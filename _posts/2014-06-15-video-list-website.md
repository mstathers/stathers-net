---
layout: posts
title: Project - Video List Website
---

An old project, revived, cleaned up and posted to <a href="https://github.com/mstathers/video-list-website/" target="_blank">GitHub</a>.

This is a simple PHP script to generate a web page containing links to videos within a directory of your choosing. For me, I simply symlinked my video directory into my webroot:
{% highlight bash %}
ln -s /home/mike/videos/ /var/www/videos
{% endhighlight %}

Of course, make sure that you have allowed following symlinks in your web server configuration; with Apache2, you need <a href="http://httpd.apache.org/docs/current/mod/core.html" target="_blank">FollowSymLinks</a>. I have not yet tested this script with other web servers, such as Nginx or Lighttpd, but I do not see any reason why they would not work.

I created this script because I wanted an easy and convenient way to stream videos from my file server to my Andoid tablet. I recommend the <a href="https://play.google.com/store/apps/details?id=org.videolan.vlc.betav7neon" target="_blank">VLC Android app</a>, but this also works well with the embedded streaming features of most modern browsers. Of course, it also performs excellently while streaming to traditional computers (again, my preferred media player is <a href="http://www.videolan.org/vlc/" target="_blank">VLC</a>).

<img src="https://raw.githubusercontent.com/mstathers/video-list-website/master/screenshot.png" style="width:100%" alt="screenshot.png" />
