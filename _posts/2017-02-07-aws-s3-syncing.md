---
layout: posts
title: Syncing files to Amazon's AWS S3
---

Many people have heard of Amazon's cloud product, <a href="https://aws.amazon.com/" target="_blank">AWS</a>. The story behind it is really interesting and well worth the read. I wont go into it here, but the short version of it is that Amazon developed a solution in-house to serve up their online store. This technology was so good that they were able to successfully split it into it's own $150 USD billion dollar product (estimated in 2015).

There are many benefits to utilizing a cloud provider; including scalability, reliability and even cost. That last point can scale in an aggressive manner though, so watch out for that if using AWS for large projects.

### AWS S3

Although there are many components to AWS, this post will focus on S3 specifically. The following is Amazon's own definition of S3:

> Amazon Simple Storage Service (Amazon S3) is object storage with a simple web service interface to store and retrieve any amount of data from anywhere on the web. It is designed to deliver 99.999999999% durability, and scale past trillions of objects worldwide.

### Setting up a new bucket

Once in the AWS management console, the S3 interface will be accessible. Creating a bucket is as simple as clicking the "Create Bucket" button, selecting a region and giving it a name. You can set all sorts of preferences in the Properties of your bucket, but you shouldn't need anything more to get started.

Once we have files in our bucket, you will be able to view and download the files from within this interface as well.

### Setting up IAM credentials and policies

A dedicated "user" with a specific policy should be created to interact with your new bucket. This can be managed within the AWS management console, in the IAM interface. I recommend setting up a policy to control access to the bucket, before creating a user.

#### IAM Policies

To determine what permissions a user has, AWS will look at the policies applied to that user. Policies can also be assigned to groups, and then users can be members of groups. For this simple demonstration though, groups will be skipped.

The following is a simple policy that will allow an IAM user to upload, download files and delete from a specific bucket with specific file ACLs:

{% highlight json %}
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::bucket-name-here"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::bucket-name-here/*"
            ]
        }
    ]
}
{% endhighlight %}

If using this policy, be sure to replace `bucket-name-here` with the actual name of the bucket.

#### IAM Users

Once a policy has been defined, a new IAM user can be created. Upon creating this user, ensure that you apply the new policy to the user.

A set of access keys will need to be created for the user as well. In the user section of IAM, after selecting the new user, the Security Credentials tab will allow you to view any current access keys or create a new set of keys. Be sure to copy down the access key ID and secret.

---

### awscli

#### Installation and Configuration

There are may libraries and tools to use for interacting with AWS. I think the easiest way to get started with AWS is by using <a href="https://aws.amazon.com/cli/" target="_blank">awscli</a>. You can use it from the command line and this allows it to be easily added to shell scripts. It can be installed using python-pip from the command line:

{% highlight bash %}
pip install awscli
{% endhighlight %}

Start configuring awscli by selecting <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html" target="_blank">region</a> and setting that globally.

{% highlight bash %}
mkdir  ~/.aws/
cat << EOF > ~/.aws/config
[default]
region = us-west-2
EOF

{% endhighlight %}

You can also configure awscli to use the IAM user's access keys at this point

{% highlight bash %}
cat << EOF > ~/.aws/credentials
[default]
aws_access_key_id = <set key here>
aws_secret_access_key = <set secret here>
EOF

{% endhighlight %}

#### Using awscli

The built-in documentation for awscli is very good and can be easily accessed using the awscli itself:

{% highlight bash %}
usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help
{% endhighlight %}


#### Examples

The following are some simple example operation for some basic tasks. Be sure to replace the bucket name in the example with the name of your own bucket.

Listing files in the bucket:
{% highlight bash %}
aws s3 ls s3://bucket-name-here/
{% endhighlight %}

Copying a file to a bucket:
{% highlight bash %}
aws s3 cp /path/to/local_file.txt s3://bucket-name-here/
{% endhighlight %}

Removing a file in a bucket:
{% highlight bash %}
aws s3 rm s3://bucket-name-here/file_to_delete.txt
{% endhighlight %}

There is also a `sync` command that works a bit like rsync. Note that it will not preserve symbolic links.
{% highlight bash %}
aws s3 sync /path/to/directory/ s3://bucket-name-here/directory/ --delete
{% endhighlight %}

### Additional Resources
The AWS documentation is quite good and everything you need can be found there. Some helpful links though:

* <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html" target="_blank">Using Bucket Policies and User Policies</a>

* <a href="https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/" target="_blank">Writing IAM Policies: How to Grant Access to an Amazon S3 Bucket</a>

* <a href="https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html" target="_blank">Managing Access Keys for your AWS Account</a>
