---
layout: posts
title: TCP analysis and Intermittent Delivery Issues
---

### Introduction

Returning to work at the beginning of the week, I learned that one of our clients had an issue that was believed to be reputation based. Their customers were having problems sending messages to a variety of large email providers, specifically hotmail.com, aol.com and yahoo.com. As you may or may not know, "IP Reputation" is a very important thing for a mail server to maintain. If you end up with a poor reputation, many email servers will not accept mail from you. For an ISP, this can be very bad and can generate a large amount of costly support calls.

As the week marched on, it was evident that this was not your regular reputation issue. At this point I took ownership of this and decided to dig a little bit deeper. An analysis of the mail log file indicated that the problem appeared to be intermittent in nature; sometimes messages went through and sometimes the sending server would get disconnected from the recipient server due to a timeout. 

Typically if a mail server does not trust your IP address, it will respond with a `5xx` SMTP code (permanent failure) and a short message. Similarly, if a server is rate limiting your IP they will either block your connections completely or respond with a `4xx` SMTP code (temporary failure) and a short message.

This no longer looked like a reputation issue given the intermittent nature to me; the reasons being were that the recipient servers were disconnecting due to timeout, no `5xx` or `4xx` errors and the fact that this was occurring across multiple recipient domains and MX servers. Furthermore, we had not heard of any similar reports from any other customers.

### Digging deeper
At this stage I smelled a network issue. However, I really do not like to simply cry "networking issue" unless I know with certainty that the problem is not being caused by our product (there is a bit of personal pride involved as well).

Enter <a href='http://www.tcpdump.org/' target="_blank">**tcpdump**</a>.

This is not a tutorial on how to use **tcpdump**, so I am going to get right into the analysis.

{% highlight bash %}
57   0.475828   192.0.2.1 -> 152.163.0.99 SMTP 8754 C: DATA fragment, 1432 bytes
58   0.475935 152.163.0.99 -> 192.0.2.1   TCP 66 smtp > 60464 [ACK] Seq=507 Ack=62546 Win=64000 Len=0 TSval=4249346069 TSecr=2478265
59   0.528278 152.163.0.99 -> 192.0.2.1   TCP 66 smtp > 60464 [ACK] Seq=507 Ack=66890 Win=64512 Len=0 TSval=4249346122 TSecr=2478275
60   0.528312   192.0.2.1 -> 152.163.0.99 SMTP 11650 C: DATA fragment, 1432 bytes
61   0.771305   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
62   1.259310   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
63   2.235329   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
64   4.191383   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
65   8.107357   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
66  15.931354   192.0.2.1 -> 152.163.0.99 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1432 bytes
67  30.528175 152.163.0.99 -> 192.0.2.1   SMTP 124 S: 421 4.4.2 mtaiw-aaj08.mx.aol.com Error: timeout exceeded
68  30.528224 152.163.0.99 -> 192.0.2.1   TCP 66 smtp > 60464 [FIN, ACK] Seq=565 Ack=66890 Win=64512 Len=0 TSval=4249376123 TSecr=2478275
69  30.567309   192.0.2.1 -> 152.163.0.99 TCP 66 60464 > smtp [ACK] Seq=110330 Ack=566 Win=15680 Len=0 TSval=2485799 TSecr=4249376122
{% endhighlight %}

What happened is the server connected successfully and SMTP commenced as expected the `EHLO`, `MAIL FROM`, `RCPT TO` and `DATA` commands were all sent successfully and received successfully. The server was sending mail data when suddenly it was no longer receiving TCP `ACK` responses back from the recipient server. I could see from the dump that retransmissions were attempted until finally the remote server closed the connection due to a timeout.

This was good and I could tell that the problem did not exist on our end! After consideration there were only two possibilities to consider:

 * The sending server was never getting back the TCP `ACK` responses from the recipient mail server.
 * The recipient mail server was never getting the DATA packets from the sending server and therefore did not have the opportunity to even send `ACK` responses.

### But we need more
I knew at this point that the problem was not on our end of things, but I did not want to leave the client hanging and I was curious as well as to what was going on.

I sent the packet capture over to the client and explained the situation to them. I asked if they could do a similar packet capture at their edge router so that I could try to isolate the problem. Depending on their findings, I would be able to reliably determine whether the problem was inside or outside their network.

{% highlight bash %}
77   0.572332   192.0.2.1 -> 66.196.118.37 SMTP 1514 C: DATA fragment, 1448 bytes
78   0.573099 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [ACK] Seq=170 Ack=54693 Win=65152 Len=0 TSval=2024110363 TSecr=20589623
79   0.573102 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [ACK] Seq=170 Ack=57589 Win=62208 Len=0 TSval=2024110363 TSecr=20589623
80   0.573104 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [ACK] Seq=170 Ack=60485 Win=59328 Len=0 TSval=2024110363 TSecr=20589623
81   0.630983 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [ACK] Seq=170 Ack=63381 Win=65152 Len=0 TSval=2024110422 TSecr=20589623
82   0.631439 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [ACK] Seq=170 Ack=66277 Win=65152 Len=0 TSval=2024110422 TSecr=20589638
83  60.570259 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 52035 [FIN, ACK] Seq=170 Ack=66277 Win=66560 Len=0 TSval=2024170361 TSecr=20589638
84  60.608526   192.0.2.1 -> 66.196.118.37 TCP 66 [TCP Previous segment lost] 52035 > smtp [ACK] Seq=109717 Ack=171 Win=14848 Len=0 TSval=20604648 TSecr=2024170361
85  69.152690   192.0.2.1 -> 66.196.118.37 SMTP 1514 [TCP Retransmission] C: DATA fragment, 1448 bytes
86  69.213188 66.196.118.37 -> 192.0.2.1   TCP 60 smtp > 52035 [RST] Seq=171 Win=0 Len=0
{% endhighlight %}

Admittedly, it is a little hard to understand what is going on here without the full capture. But for hopefully obvious reasons I hope you understand why I could not post that. Instead, I will do my best to explain.

What the edge capture showed is that the router could not see the DATA transmissions from the sending server! This means that the problem was definitely between the sending server and the edge. To explain further, the reason the sending server never received `ACK` responses is because the recipient server never even got the DATA transmissions.


### The culprit
The client and I discussed if any unique equipment was between the sending server and the edge. There was only one possibility, this mail server cluster had a load balancer positioned in front and the mail servers were sending all outbound traffic back through the load balancer.

I performed a simple test and configured one of the servers so that it did not send mail through the load balancer.
{% highlight bash %}
9294   7.970938 66.196.118.37 -> 192.0.2.1   SMTP 119 S: 250 ok Thu Mar 31 19:41:02 2016:  ql 54112230, qr 0
9295   7.971087   192.0.2.1 -> 66.196.118.37 SMTP 72 C: QUIT
9296   7.971363   192.0.2.1 -> 66.196.118.37 TCP 66 39950 > smtp [FIN, ACK] Seq=25270130 Ack=223 Win=14848 Len=0 TSval=21182042 TSecr=2459445224
9297   8.031835 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 39950 [ACK] Seq=223 Ack=25270131 Win=885760 Len=0 TSval=2459445285 TSecr=21182042
9298   8.032986 66.196.118.37 -> 192.0.2.1   TCP 66 smtp > 39950 [FIN, ACK] Seq=223 Ack=25270131 Win=885760 Len=0 TSval=2459445286 TSecr=21182042
9299   8.033010   192.0.2.1 -> 66.196.118.37 TCP 66 39950 > smtp [ACK] Seq=25270131 Ack=224 Win=14848 Len=0 TSval=21182057 TSecr=2459445286
{% endhighlight %}

Success! The receiving server gave a `2xx` response, the sending server sent the SMTP `QUIT` command and the TCP `FIN`, `ACK` sequences finished correctly.

### Conclusion
Packet analysis is a very helpful tool when you really need to dig in to a problem. It definitely is not at the top of my troubleshooting toolbox, but I do make a point of keeping in practice with it. In case anybody is curious, I used <a href='http://www.tcpdump.org/' target="_blank">**tcpdump**</a>, <a href='https://www.wireshark.org/' target="_blank">**wireshark**</a> and <a href='https://www.wireshark.org/docs/man-pages/tshark.html' target="_blank">**tshark**</a> for the above.

This also highlights the importance of being familiar with the OSI model and networking. For more information, I recommend settling into the following for a bit of light reading - <a href='https://tools.ietf.org/html/rfc793' target="_blank">https://tools.ietf.org/html/rfc793</a> 
😂
