---
layout: posts
title: Raspberry Pi - Kiosk Style Wall Monitor
---

It is not unusual to setup some displays to provide at-a-glance metrics for the various systems under your care. With great software like <a href="https://www.nagios.org/" target="_blank">Nagios</a>, <a href="http://www.cacti.net/" target="_blank">Cacti</a>, <a href="http://www.splunk.com/" target="_blank">Splunk</a>, <a href="https://www.graylog.org/" target="_blank">Graylog</a> and many others, it is easy to collect, centralize and visualize your data. However, in this article I want to talk about an easy and cost-effective way to handily display this data.

### The Hardware
I lucked out because a year ago my employer moved into a new office and we were able to design and build-out our new space however we wanted. I planned ahead and had the contractors put in the power, data jacks and wall mounting for four identical 27 inch LCD monitors up near the ceiling above where I expected our desks to be. I understand this is fortuitous timing, but you can just work with what you have. I started out using the Raspberry Pi 2, but I have recently upgraded them to the Raspberry Pi 3 model. One of the nice benefits of the Pi 3 is the addition of built-in WiFi capability which should make retrofit installation a bit easier if you do not already have data jacks available nearby.

Otherwise, you just need the regular Raspberry Pi stuff; micro-USB power, network connectivity and an HDMI connection to your display.

Assuming you do not have to worry about hiring contractors to run power or data, and you are just going to throw a monitor up on a shelf, you can probable do this project for a few hundred dollars per station. This should allow this project be compatible with all but the most shoestring of budgets.

### OS Installation
I used Raspbian for this project, you could use another operating system but the instructions in this article will change depending on which desktop environment you use. At the time of writing, Raspbian uses the LightDM display manager.

I will not be going into the specifics of OS installation on a Raspberry Pi as there are lots of tutorials out there. To save yourself headache, I do recommend enabling the passwordless auto-login feature and I do also recommend utilizing <a href="https://www.raspberrypi.org/documentation/installation/installing-images/" target="_blank">the official Raspberry Pi documentation</a>.

### System Configuration
The next sections outline some of the configuration changes needed to ensure that the monitors will stay on indefinitely, sans screensaver.

#### Disable Powersaving in Console
To disable the powersaving features of KBD, edit the `/etc/kbd/config` file and ensure the following is set:

{% highlight bash %}
BLANK_TIME=0
POWERDOWN_TIME=0
{% endhighlight %}

#### Disable Screensaver in X
Configure `X` via the `/etc/lightdm/lightdm.conf` file to set the screensaver timeout to 0 (infinite) and to disable DPMS (display power management services). Make sure to set the `xserver-command` setting within the `SeatDefaults` section of this file.

{% highlight bash %}
[SeatDefaults]
xserver-command=X -s 0 -dpms
{% endhighlight %}

#### Configure Display Scaling
This step may be skipped depending on your displays. For the 27 inch LG monitors available to me, I used the following values in `/boot/config.txt`:

{% highlight bash %}
hdmi_group=2
hdmi_mode=82
{% endhighlight %}

In case display scaling needs to be adjusted, please refer to the <a href="https://www.raspberrypi.org/documentation/configuration/config-txt.md" target="_blank">official Raspberry Pi documentation for the `config.txt` options</a>.

#### Auto-start Application on Boot
Part of the nice thing about having a monitor station, is not having to touch it. Apart from the displays, I use no other peripherals. In order to accomplish this, first ensure passwordless auto-login has been enabled via the `raspi-config` setup utility.

Next, configure LightDM to autostart applications by first creating an `autostart` directory within `~/.config` using the following command:

{% highlight bash %}
mkdir ~/.config/autostart
{% endhighlight %}

Create a file inside the `~/.config/autostart/` directory to hold the application autostart configuration. My application is the Midori browser, but any application will work. Using Midori for an example, edit `~/.config/autostart/midori.desktop` and add the following:

{% highlight bash %}
[Desktop Entry]
Type=Application
Exec=midori -e Fullscreen -e enable-javascript=true -a https://stathers.net/
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=midori
Name=midori
Comment[en_US]=
Comment=
{% endhighlight %}

You would enter whatever URL applies to you. In my case, we have an internal server that provides different content based on a GET value.

As mentioned above, Midori is not required. Instead you could use another browser (I have tested Chrome and Iceweasel) or you could use an entirely different application. In fact, during the holidays last year I setup one of my stations to play a YouTube video of a fireplace. I accomplished this feat of festivity using <a href="http://elinux.org/Omxplayer" target="_blank">Omxplayer</a> and <a href="http://docs.livestreamer.io/" target="_blank">Livestreamer</a>.

### Conclusion
I hope you use this to improve your real-time visibility into your systems in a cost-effective and easy way. If you have any questions at all, feel free to <a href="https://stathers.net/contact.html" target="_blank">contact me</a>.
