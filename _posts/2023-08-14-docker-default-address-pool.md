---
layout: posts
title: Docker Default Address Pool
---

Every time a [Docker Compose](https://docs.docker.com/compose/){:target=_blank} application starts it creates a [Docker network](https://docs.docker.com/network/){:target=_blank} to facilitate inter-container communication. I encountered a problem where sometimes the network assigned to the application would conflict with services running on our internal network. Troubleshooting this is a different discussion, but the fix is straightforward, the default address pool from which Docker assigns new Docker networks needs to change.

In a server environment edit the `/etc/docker/daemon.json` file. For Docker Desktop, this can be modified via the Docker Engine menu found within the Settings. Add the following block to the existing config:
```
  "default-address-pools": [
    {
      "base": "10.10.0.0/16",
      "size": 24
    }
```
Note that this configuration adheres JSON format.

The above configuration sets up a single address pool of `10.10.0.0/16` affording over 65,000 IP addresses. Each network created within this pool will use a `/24` CIDR subnet mask effectively providing 254 usable IP addresses. For my own requirements, this allocation proves more than adequate, and should ensure I have no more IP conflicts.

It is possible to configure multiple address pools if desired.

When choosing an address pool, exercise caution to try to avoid address conflicts. To illustrate, my home network uses a `192.168.x.x` address, and my workplace's internal network uses portions of the `172.` private range. By opting to choose a network inside the `10.x.x.x` range I expect to avoid any conflicts moving ahead. For more information on IPv4 ranges reserved for private use, reference [https://en.wikipedia.org/wiki/Private_network](https://en.wikipedia.org/wiki/Private_network){:target=_blank}.
