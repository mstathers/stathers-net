---
layout: posts
title: Dirty Vagrant
---

> <a href="https://www.vagrantup.com/" target="_blank">Vagrant</a> is a tool for building and managing virtual machine environments in a single workflow. With an easy-to-use workflow and focus on automation, Vagrant lowers development environment setup time, increases production parity, and makes the "works on my machine" excuse a relic of the past.

As it says on tin, Vagrant is a way to spin up VMs quickly in an automated manner. To <a href="https://www.vagrantup.com/intro/getting-started/index.html" target="_blank">get started</a> simply:

{% highlight bash %}
vagrant init centos/7
vagrant up
{% endhighlight %}

This will download the base box from HashiCorp's public vagrant box server and start the box. The `centos/7` box specifically refers to <a href="https://atlas.hashicorp.com/centos/boxes/7" target="_blank">https://atlas.hashicorp.com/centos/boxes/7</a>.

The newly started box can then be accessed with:

{% highlight bash %}
vagrant ssh
{% endhighlight %}

### Vagrantfile

The meat and potatoes of the Vagrant experience will be manipulated via the `Vagrantfile` (created upon running `vagrant init`).

Here is an example `Vagrantfile` which will setup two machines and network them together via private interfaces.

{% highlight ruby %}
Vagrant.configure("2") do |config|
    config.vm.define "dns" do |dns|
        dns.vm.box = "centos/7"
        dns.vm.network "private_network", ip: "172.16.0.254"
    end
    config.vm.define "master" do |master|
        master.vm.box = "centos/7"
        master.vm.network "private_network", ip: "172.16.0.1"
    end
    config.vm.provision :shell, path: "bootstrap.sh"
end
{% endhighlight %}

This names two machines, instructs Vagrant to base them on the `centos/7` box and assigns them static IP addresses on private interfaces.

It also triggers a script to run upon provisioning the box for the first time. In this case the `bootstrap.sh` script resides in the same directory as the `Vagrantfile` and contains some simple bash commands:

{% highlight bash %}
cat << EOF > /etc/resolv.conf
search puppet.local
nameserver 172.16.0.254
EOF

echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
{% endhighlight %}

A provisioning script is definitely not required though!

### Read More
<a href="https://www.vagrantup.com/intro/getting-started/index.html" target="_blank">https://www.vagrantup.com/intro/getting-started/index.html</a>
