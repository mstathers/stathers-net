---
layout: posts
title: NetworkManager - Source Policy Routing
---

This can be considered a part two of a previous post on [source policy routing]({% post_url 2015-06-25-source-policy-routing %}). Review that post for an overview of source policy routing. 

This post will demonstrate how to use [NetworkManager](https://networkmanager.dev/) to configure source policy routing. The main advantage of using NetworkManager is it's included with modern Enterprise Linux distributions and it handles boot time persistence.

## Network Diagram
![Source Policy Routing - Network Diagram](/pictures/source_policy_netdia.png "Source Policy Routing - Network Diagram")


## Instructions
Start by creating two new tables, one for each interface.
*/etc/iproute2/rt_tables*
{% highlight text %}
#
# Reserved values
#
255     local
254     main
253     default
0       unspec
#
# Dual-interface routing tables
# - prinet: Private interface (eth0) routing table
# - pubnet: Public interface (eth1) routing table
#
100     prinet
101     pubnet
{% endhighlight %}

Find the UUIDs of each connection. These UUIDs will be used to configure each connection.
{% highlight bash %}
$ nmcli --fields DEVICE,UUID connection show
DEVICE  UUID
eth0    5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03
eth1    fd703f29-a874-37dc-948d-2b1a719e0d6f
lo      2ff97c54-daca-42f6-a8fd-fc1bd74e2acb
{% endhighlight %}


## `eth0`
Configure the routes and rules for the `eth0` interface. In this example, assume our default gateway will be out `eth0`.
{% highlight bash %}
$ eth0_uuid=5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03
$ eth0_ip=10.10.0.5
$ eth0_cidr=10.10.0.0/24
$ eth0_gateway=10.10.0.254
$ nmcli connection modify ${eth0_uuid} \
 +ipv4.routes '${eth0_ip}/32 0.0.0.0 0 table=100' \
 +ipv4.routes '0.0.0.0/0 ${eth0_gateway} 0 table=100' \
 +ipv4.routes '${eth0_cidr} 0.0.0.0 0' \
 +ipv4.routing-rules 'priority 100 from ${eth0_cidr} table 100'
{% endhighlight %}

## `eth1`
Configure the routes and rules for the `eth1` interface. Very similar to `eth0`, but disable the default gateway on this interface.
{% highlight bash %}
$ eth1_uuid=fd703f29-a874-37dc-948d-2b1a719e0d6f
$ eth1_ip=10.20.0.5
$ eth1_cidr=10.20.0.0/24
$ eth1_gateway=10.20.0.254
$ nmcli connection modify ${eth1_uuid} ipv4.never-default yes \
 +ipv4.routes '${eth1_ip}/32 0.0.0.0 0 table=101' \
 +ipv4.routes '0.0.0.0/0 ${eth1_gateway} 0 table=101' \
 +ipv4.routes '${eth1_cidr} 0.0.0.0 0' \
 +ipv4.routing-rules 'priority 101 from ${eth1_cidr} table 101'
{% endhighlight %}

## Reload Connections

{% highlight bash %}
nmcli connection up ${eth0_uuid}
nmcli connection up ${eth1_uuid}
{% endhighlight %}
