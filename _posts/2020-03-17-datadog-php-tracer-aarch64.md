---
layout: posts
title: Datadog PHP Tracer on aarch64
---

Recently we have been exploring the use of the a1 instance type in AWS EC2 as the performance is favorable to our workloads the cost makes this instance type very appealing. This instance type uses an ARM processor and therefor has the architecture of `aarch64`. More information about the instance class can be found <a href="https://aws.amazon.com/ec2/instance-types/a1/" target="_blank">here</a>.

One of the many vendors we use at FormAssembly to help deliver our product is <a href="https://www.datadoghq.com/" target="_blank">Datadog</a>. Their product is used for both log aggregation and their application performance monitoring (APM). Because FormAssembly is written in PHP, we need to rely on an extension in order to facilitate their APM tracing (<a href="https://github.com/DataDog/dd-trace-php" target="_blank">https://github.com/DataDog/dd-trace-php</a>). Unfortunately, at the time of writing, this package is published by Datadog for the aarch64 architecture.

The process I eventually used to create an aarch64 rpm package which we could distribute to our servers was a little bit hacky and quite a bit interesting. I have provided feedback to Datadog to publish their own package, or to at least include a source RPM - but for the time being, this process will have to work.

## Steps to build an aarch64 rpm package

Before starting you will need to be running on an aarch64 system that is rhel based. I used an Amazon EC2 a1 instance running Amazon Linux 2 (amzn2).

### 1. Compile the ddtrace.so extension
Download and install the source tarball for the release (<a href="https://github.com/DataDog/dd-trace-php/releases/latest" target="_blank">https://github.com/DataDog/dd-trace-php/releases/latest</a>). Extract it, move into the directory and run the following:

{% highlight bash %}
./configure && make
{% endhighlight %}

You will likely need to install dependencies. I’m putting this together after the fact from a build attempt on a system with many build tools and libraries already installed so I will leave this as an exercise for the reader.
If everything was successful, you will be left with the php extension file `./modules/ddtrace.so`.

### 2. Download the published x86_64 rpm
This can be found on the above github releases page. Rename it to reflect the aarch64 architecture, this is used later to help us trick `rpmrebuild` into building us an aarch64 package. eg:

{% highlight bash %}
mv datadog-php-tracer-0.41.1-1.{x86_64,aarch64}.rpm
{% endhighlight %}

### 3. Install `rpmrebuild`
A simple `yum install rpmrebuild`.

Once installed we will need to edit `rpmrebuild` to further trick it into rebuilding an x86_64 rpm as an aarch64 rpm. Edit `/usr/lib/rpmrebuild/rpmrebuild.sh` and find the function `RpmArch`. This function finds out the architecture of the package we are rebuilding - add the following line before the `return` to force the desired architecture:


{% highlight bash %}
      pac_arch="aarch64"
{% endhighlight %}


### 4. Time to actually rebuild the package.

{% highlight bash %}
rpmrebuild -enp --change-files "/bin/bash" datadog-php-tracer-0.41.1-1.aarch64.rpm
{% endhighlight %}

This will open an editor and allow us to change the SPEC file of the package. We need to replace any instance of x86_64 with aarch64. This vim command will do it for you: `:%s/x86.64/aarch64/`.

Next, still in the SPEC file, we need to remove all mentions of the existing php extensions, there are a bunch:

{% highlight bash %}
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20100412-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20100412.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20131106-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20131106-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20131106-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20131106.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20151012-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20151012-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20151012-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20151012.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20160303-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20160303-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20160303-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20160303.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20170718-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20170718-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20170718-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20170718.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20180731-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20180731-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20180731-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20180731.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20190902-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20190902-zts-debug.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20190902-zts.so"
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace-20190902.so"
{% endhighlight %}

Delete all those and just insert this single line:

{% highlight bash %}
%attr(0755, root, root) "/opt/datadog-php/extensions/ddtrace.so"
{% endhighlight %}

You can then write and quit editing the spec file (`:wq`).

It will prompt you if you want to continue, you do.

This will drop you back into a shell, and give us a chance to load in our compiled extension from step one. You will find a temporary directory within `/root/` that looks like `/root/.tmp/rpmrebuild.23012`. That is where we can load our extension.

{% highlight bash %}
rm -f /root/.tmp/rpmrebuild.23012/work/root/opt/datadog-php/extensions/ddtrace*
cp dd-trace-php-0.41.1/modules/ddtrace.so /root/.tmp/rpmrebuild.23012/work/root/opt/datadog-php/extensions/
{% endhighlight %}

Next, we need to exit the shell and it is very important we return a 0 so that rpmrebuild is happy:

{% highlight bash %}
exit 0
{% endhighlight %}

At this point, rpmrebuild will actually build the package and it should say something like this:

{% highlight bash %}
result: /root/rpmbuild/RPMS/aarch64/datadog-php-tracer-0.41.1-1.aarch64.rpm
{% endhighlight %}

### 5. Test the package
Test the package, make sure it works as expected.
