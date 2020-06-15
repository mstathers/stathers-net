---
layout: posts
title: HAProxy Service Discovery with AWS Autoscaling Groups
---

## Background and History
I would like to start by giving some background to provide context for the decisions that were made this project. This project relates to the segment of our infrastructure containing a load balancer layer running HAProxy in front of a series of application server clusters serving http(s) traffic.

Before this project, AWS Autoscaling Group (ASG) lifecycle hooks would add application servers to a central registry upon scale-out. The same lifecycle hooks would then trigger a script on the HAProxy load balancers to query the central registry in order to reconfigure HAProxy with the new backend server information. The script would then finish by reloading HAProxy. A similar process would happen for ASG scale-in.

### Issues to be Solved
For a long time this solution worked just great, but as we started to scale up we were encountering performance issues. During releases we would want to flag some of our servers for maintenance mode within HAProxy - but given the large number of backends we had and the servers attached to those backends it would drag the load balancer down. This was especially true during release cycles when we were scaling our ASGs out and back in. We needed a way to put servers into maintenance mode efficiently for these releases.

Additionally we had a problem with this system in regards to our disaster recovery site. If we were to copy our central registry to our DR site, the cluster membership information would would be inaccurate - new site, new members. Admittedly, there were other possible solutions here, but service discovery also helped solve this problem.

## What is Service Discovery?
Wikipedia says:
> Service discovery is the automatic detection of devices and services offered by these devices on a computer network. A service discovery protocol (SDP) is a network protocol that helps accomplish service discovery. Service discovery aims to reduce the configuration efforts from users.

The goal was to replace our central registry with something much more dynamic. It would have to also be compatible with HAProxy and couldn't require our scripts to glue it all together.

Turns out there is something for this - The SRV Record:
> A Service record (SRV record) is a specification of data in the Domain Name System defining the location, i.e., the hostname and port number, of servers for specified services.

The SRV record contains a priority, a weight, a port and an address, and it may contain multiple such entries.

## HAProxy Configuration
HAProxy's implementation of service discovery uses something called `server-templates`. They get configured into a backend, where a `server` configuration would normally go and they look a bit like this:
```
server-template CLUSTER1 3 _CLUSTER1._tcp.example.com check resolvers r53
```
In this case this template configuration would configure three servers in the backend and get their information by querying the SRV record.
The configuration requires a name, how many servers you want it to make, the SRV record to query, and the resolver you want HAProxy to use. In my case the resolver is setup as part of the global HAProxy configuration and was just configured to use the system default resolvers out of resolv.conf:
```
resolvers r53
    parse-resolv-conf # Just read from resolv.conf
    accepted_payload_size 8192 # Allow larger DNS payloads
```

Continuing the above example, I would create a `_CLUSTER1._tcp.example.com` record and enter some values such as:
```
0 0 443 192.0.2.10
0 0 443 192.0.2.11
```
If the load balancer was queried via the appropriate frontend, it would then go on to connect to either `192.0.2.10` or `192.0.2.11` on port `443` with equal weight.

HAProxy unfortunately will not use the priority value in the SRV record, but they will use the weight value. As such we can change the load balancing weight by setting a value in the record from 0 to 65535. Note that HAProxy weights only go between 0 and 255, so they just do some simple math and divide the record value by 256 to convert between them.

I decided to leverage this weighting function in order to implement a pseudo maintenance mode, by leaving our default weight at 65535 and dropping the weight to 0 for any server that we want to take out of the rotation. In theory, it is still possible for some traffic to go through to such a host but by that time we probably would have started working on the host and the health check should pick up that the host is down.

Note: I saw in some HAProxy mailing lists discussion around using the SRV record priority value to trigger backend server states. This would be ideal because then we could actually put a host into maintenance mode.

## SRV Record Configuration
It's all well and good that HAProxy can load balance traffic based on an SRV record. I had to come up with a method for updating the SRV records dynamically. There was some iteration here as I came across some EC2 "gotchas" and a race condition.

The ASG lifecycle hooks worked out quite well from our previous setup so I decided to reuse the method. These hooks are triggered when an EC2 instance is added or removed from an ASG. I had the hook trigger a CloudWatch rule which in turn was able to pass off the event to a Lambda function. The lambda function is simply a python3 script which relies on the boto3 library to interact with AWS via their API.

The lifecycle hook event contains the information needed to get started, including the AutoScalingGroupName, a LifecycleActionToken, the LifecycleHookName and most importantly the EC2InstanceId.

I decided to use a derivative of the AutoScalingGroupName to create the SRV record name. This resulted in a separate SRV record for each cluster and made things really simple with the HAProxy configuration (make sure each backend has the correct cluster SRV record).

I also decided to tag each of our EC2 instances with two values, their IP address and their SRV-Weight - as this information was needed to interact with the SRV record.

When the lifecycle hook triggers the lambda function, the function first looks at whether an instance is launching or an instance is terminating.

If an instance is launching, the instance is tagged appropriately with the IP and the SRV-Weight. eg.

{% highlight python %}
# New server - add to SRV record
if event['detail']['LifecycleHookName'] == "srvCreation":
    # Tag server with new srv_weight of 65535
    print('Tagging {} with srv_weight: 65535'.format(instance_id))
    ec2.create_tags(
        Resources = [instance_id],
        Tags = [{
            'Key': 'srv_weight',
            'Value': '65535'
        }]
    )
{% endhighlight %}

Then, the lambda function will query EC2 for all instances using the reserved `aws:autoscaling:groupName` tag and UPSERT the SRV record with the weights and IP addresses found for the cluster.

{% highlight python linenos %}
# upsert the srv record for all hosts in the ASG
def rebuildRecord(recordName, asg):
    recordValues = []

    # Get all running app servers for the ASG
    registered_app_servers = ec2.describe_instances(
        Filters=[{
            'Name':'tag:aws:autoscaling:groupName',
            'Values':[asg]
        },{
            'Name':'instance-state-name',
            'Values':['running']
        }
    ])

    # Go through each instance in the ASG and create the SRV record value based
    # on their IPs and weights.
    for instance_groups in registered_app_servers['Reservations']:
        for instance in instance_groups['Instances']:
            # Set the instance IP address based on Tag if it exists.
            # Also set the weight based on the instance Tag
            tags = instance['Tags']
            ipAddress = None
            weight = None
            for i, tag in enumerate(tags):
                if tag['Key'] == 'ip_address':
                    ipAddress = tag['Value']
                if tag['Key'] == 'srv_weight':
                    weight = tag['Value']
            if not ipAddress:
                ipAddress = instance['PrivateIpAddress']

            # Only include servers which have a weight set (and an IP)
            if weight and ipAddress:
                newRecordValue = {'Value': '0 {} 443 {}'.format(weight, ipAddress)}
                recordValues.append(newRecordValue.copy())

    print('DEBUG: Updating {} with values: {}'.format(recordName, recordValues))
    try:
        response = r53.change_resource_record_sets(
            HostedZoneId = HostedZoneId,
            ChangeBatch = {
                'Changes': [{
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': recordName,
                        'Type': 'SRV',
                        'TTL': 10,
                        'ResourceRecords': recordValues
                    }
                }]
            }
        )
        return response
    # Something bad happened apparently.
    except ClientError as e:
        print("Unexpected error: {}".format(e))
        return False
{% endhighlight %}

If an instance is terminating, the instance is tagged with an SRV-Weight of 0. Then, just like above the lambda function will build the SRV record, but then it waits for a short while. Recall from above that a weight of 0 will effectively put the server into MAINT mode. This is to give a chance for HAProxy to drain the connections to that host. After a period the script will remove the SRV-Weight tag from the instance, query EC2 for the cluster members based on the tags and UPSERT the SRV record.

Finally, I used the information from the lifecycle event to tell AWS that the event is complete (otherwise it would just wait for the preconfigured timeout). A small performance gain, but little things like this really build up at scale.

{% highlight python linenos %}
# Report back to the lifecyle hook that we're done.
try:
    autoscalingClient.complete_lifecycle_action(
        LifecycleHookName = event['detail']['LifecycleHookName'],
        AutoScalingGroupName = event['detail']['AutoScalingGroupName'],
        LifecycleActionToken = event['detail']['LifecycleActionToken'],
        LifecycleActionResult = 'CONTINUE'
    )
except ClientError as e:
    print("Unexpected error: {}".format(e))
    return False
{% endhighlight %}

## A Race Condition and "Gotcha"
### Race Condition
Initially I didn't do any instance tagging specifically for this project at all. The original solution was to query route53 for the current SRV record value, make whatever change I needed (adding hosts, removing hosts, changing weights), and then adding the new record it back in. This was great in theory and fine in my initial tests. Fortunately I was able to perform early testing in production, as the existence of records didn't impact anything at that point int he project.

To give some context, quite often we will double the size of an application cluster for various reasons. This means multiple instances get started at the same time, therefore multiple lifecycle hooks and multiple triggered lambda functions.

These all would be querying the existing SRV records, adding their own servers and then using an UPSERT to add the updated record. I noticed servers would be missing from the SRV records after scale-out events as a result of this. In my local testing I only ever ran the function serially so this problem never came up.

I simply wouldn't be able to run the script serially in production, it just wouldn't scale for us if I tried to get it to do that. There was talk of using a lock file method but eventually a colleague of mine suggested trying to implement an atomic method using tagging. This is why the current iteration relies on instance tags and rebuilding the relevant SRV record every single time there is a change. It's simply a more safe method and any possible performance loses are extremely minimal.

### EC2 IP Address
I could hear it as I was typing this out:
>Why did you tag the instance with the IP address?! You can just pull that information from the EC2 instance!

True. Until you've terminated the instance that is. If you terminate an instance in EC2, you can no longer query what its private IP address is (or was) - it's simply no longer configured. So I decided to tag instances with their IP addresses upon launch so this information would at least stick around until the terminated instance was cleaned up. Admittedly this was more of a problem when I was trying modify the SRV record in place instead of just recreating it via the new idempotent script. I still wanted to mention it though as it did cause issues for me.

## Caveats
This solution does increase the load on the HAProxy servers as the configuration is no longer static and the load balancer needs to query the SRV records for each backend server. You could play around with the record TTLs to balance performance and responsiveness. For most sites it didn't actually have any noticeable impact, but I did need to bump up the load balancer instance size in some environments when trying to keep track of a few thousand backends.

Finally, if you're using AWS route53 you should also be aware of their pricing.
