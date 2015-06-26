---
layout: posts
title: Linux - Source Policy Routing
---

*"If I have two networks attached to my server, how do I make sure traffic that comes into an interface goes out the same interface?"*

I have found this question has come up a fair amount, from fellow techs and from customers. It was always answered with a murky explanation skirting around "advanced Linux routing" and an short explanation of a "better" or "more standard" way. I knew there must be a better way, and sure enough there is - Source Policy Routing with <a href="https://en.wikipedia.org/wiki/Iproute2" target="_blank">iproute2</a>. This is just one way to do it, and I am sure there are other ways as well (marking traffic, for example).

### Network Diagram
![Source Policy Routing - Network Diagram](/pictures/source_policy_netdia.png "Source Policy Routing - Network Diagram")


### Instructions
First add two tables into */etc/iproute2/rt_tables* with your favourite text editor, one for each network. This is creating two new routing tables which we can work on.
{% highlight bash %}
#
# reserved values
#
255 local
254 main
253 default
0   unspec
#
# local
#
10 network10
20 network20
{% endhighlight %}

Next up, we will assign each network and default gateway to each of our new routing tables (network10 and network20):
{% highlight bash %}
# Adding the network address for our first network to our first routing table.
ip route add 10.10.0.0 dev eth0 table network10
# Adding the default route for the same network to the first routing table.
ip route add default via 10.10.0.254 table network10
#
# Adding the network address for our second network to our second routing table.
ip route add 10.20.0.0 dev eth1 table network20
# Adding the default route for the same network to the second routing table.
ip route add default via 10.20.0.254 table network20
{% endhighlight %}

Then, we need to make sure our *main* routing table is aware of our networks
{% highlight bash %}
ip route add 10.10.0.0/24 dev eth0
ip route add 10.20.0.0/24 dev eth1
{% endhighlight %}

Finally, we need to add a routing *rule* to say if traffic is coming *from* one of our networks to use a specific routing table.
{% highlight bash %}
ip rule add from 10.10.0.0/24 table network10
ip rule add from 10.20.0.0/24 table network20
{% endhighlight %}


### Loading at Boot
I am admittedly not too happy with this next bit and I think it could be done a lot better, but currently I use a script in */etc/network/if-pre-up.d/* to facilitate loading of these routes at boot. Please [contact](/contact.html) me if you ever make a better version of this, I would love to use it!
{% highlight bash %}
#!/bin/bash

# "IFACE  physical name of the interface being processed"
#  - interfaces(5)
if [ "$IFACE" = "eth0" ]; then

    # Just checking if we are using our custom routing table already.
    ip route list table network10 | grep -q scope
    if [ $? -eq 0 ]; then
        exit 0
    fi

    ip route add 10.10.0.0 dev eth0 table network10
    ip route add default via 10.10.0.254 table network10
     
    ip route add 10.10.0.0/24 dev eth0
     
    ip rule add from 10.10.0.0/24 table network10
fi

if [ "$IFACE" = "eth1" ]; then

    # Just checking if we are using our custom routing table already.
    ip route list table network20 | grep -q scope
    if [ $? -eq 0 ]; then
        exit 0
    fi

    ip route add 10.20.0.0 dev eth1 table network20
    ip route add default via 10.20.0.254 table network20

    ip route add 10.20.0.0/24 dev eth1

    ip rule add from 10.20.0.0/24 table network20
fi

{% endhighlight %}
