---
layout: posts
title: Tailscale Funnel
---

Recently I've been exploring the <a href="https://jellyfin.org/" target="_blank">Jellyfin</a> media system running via docker on my home file server. I've been really happy with it recommend it if you're looking for a solution to stream your media.

I had an upcoming trip and I wanted to access my home media library remotely. In the past I would have jumped into my router and setup some basic port forwarding, but this time I wanted to try something new - <a href="https://tailscale.com/kb/1223/tailscale-funnel/" target="_blank">Tailscale Funnel.</a>

The advantage here is I don't need to expose my home IP address publicly. Also my ISP doesn't allow port forwarding TCP 80 or 443 so this helps get around that inconvenience. <a href="https://tailscale.com/kb/1247/funnel-serve-use-cases/" target="_blank">Tailscale lists some additional use cases if you're curious read more.</a>

### Setup Tailscale 
The <a href="https://tailscale.com/kb/1017/install/" target="_blank">setup process</a> is fairly straight forward. You will need to use an SSO provider though, some easy to use options will be presented to you at signup time, including for example Apple, Google, GitHub, Microsoft, Okta, or OneLogin.

 Once you're signed up, you'll need to <a href="https://tailscale.com/download/" target="_blank">download</a> and install the Tailscale client. I tested this on Debian Bookworm and CentOS Stream 8, both were very smooth. I was impressed by the CLI install, it finishes by providing you a link which you can open on another host (with a web browser) to authenticate your newly created node to your Tailscale network, aka "Tailnet".

Once you have some nodes setup, you'll have a Tailnet in which the connected nodes can communicate with each other. This on its own is great and highly useful.

If you want, <a href="https://tailscale.com/kb/1217/tailnet-name/" target="_blank">you can change your Tailnet name</a> from the admin console instead of the initially auto generated name. Functionally it won't make a difference, but a friendly name might be a little easier to remember later on.

### Enable DNS For Nodes
Tailscale can automatically provide DNS names to nodes and set resolvers on your host so that you can use these names. Tailscale calls this <a href="https://tailscale.com/kb/1054/dns/" target="_blank">MagicDNS.</a>
MagicDNS is very easy to setup, simply browse to the DNS page in the Tailscale admin console and click the button to __Enable MagicDNS__.

Nodes will use their host name (eg "host") with your Tailnet name (eg "fake-network.ts.net") for their FQDN. For example `host.fake-network.ts.net`.

### Enable HTTPS On Nodes
Once DNS is enabled, it's <a href="https://tailscale.com/kb/1153/enabling-https/
" target="_blank">straight forward to enable HTTPS.</a> This will create a Let's Encrypt certificate to use with your host's DNS name. Note though, this will mean that your host names will end up in the <a href="https://en.wikipedia.org/wiki/Certificate_Transparency" target="_blank">Certificate Transparency</a> ledger.

### Grant Nodes Permission To Use Funnel
We need to allow our node to use Funnel. In the Tailscale admin console, browse to <a href="Access controls" target="_blank">Access controls</a>. You can click the __Add Funnel to policy__ button to allow all nodes to use Funnel. You can restrict this to specific nodes as well, refer to the Funnel documentation for more information on this.

### Serve and Expose
We need to use the `serve` command on our node so that our service is available - I also map the default Jellyfin port 8096 port to 443.
```
# tailscale serve https / http://127.0.0.1:8096
```

Finally, we need to enable Funnel on the node to expose this port publicly.
```
# tailscale funnel 443 on
```

### Finished
Congratulations, you should now be able to browse to your host at its public Tailscale FQDN from anywhere.
