---
layout: posts
title: iptables - Simple Base Configuration
---

I find this is a great configuration to start with when working on a new server. From here, I typically customize based on the nature of the server. Hint: take a look at the listening services on the server and evaluate whether or not those services need to be locked down, database connections are a great example of this. I like to use a quick `netstat -nlp` command for this.

{% highlight bash %}
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -m iprange --src-range 10.9.8.7-10.9.8.10 -j ACCEPT
iptables -A INPUT -j REJECT
{% endhighlight %}

BONUS: I was setting up an rwhois server for work and I wanted to implement some form of rate limiting; it turns out that iptables can be used for this! In the below example, somebody will be able to make 19 TCP requests to port 4321 every minute before their connections will get rejected (for the remainder of that minute). I did not want this rate limiter to be too restrictive, I just wanted to avoid abuse and potential for DOS (because rwhois is that popular right).

The ICMP line is not required for the rate limiter, I just wanted people to be able to ping this box.

{% highlight bash %}
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4321 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name rwhois --rsource -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 4321 -m recent --set --name rwhois --rsource
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 4321 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp -s 192.168.0.11 --dport 22 -j ACCEPT
iptables -A INPUT -p icmp -m state --state NEW -m icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -j REJECT
{% endhighlight %}

PS, if you ask really nicely, I'll tell you about my rwhois easter-egg.
