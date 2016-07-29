---
layout: posts
title: Bash Tips to Increase Productivity
---

### Reverse Command History Search
---

With reverse command history search, you can quickly search through all your previously ran commands to bring up a previous command. This is much faster than hitting the up arrow key repeatedly!

To make this even more useful, I also recommend increasing the number of commands that are held in your Bash history (default 500). You can do this by editing the `HISTSIZE` variable in your .bashrc file.

{% highlight bash %}
export HISTSIZE=99999
{% endhighlight %}

You can make your history unlimited you would like by setting a number less than 0 (example: `-1`).

While you're at it, I recommend setting some other items:

{% highlight bash %}
export HISTTIMEFORMAT='%F %T '
export HISTFILESIZE='-1'
{% endhighlight %}

Firstly, this will make reading your `history` a little easier by adding real timestamps. Secondly it removes the file size restrictions on your history.

To initiate the reverse command history search, you are going to use `ctrl-r`. This is going to change your prompt to look something like this:

{% highlight bash %}
(reverse-i-search)`': 
{% endhighlight %}

You can then start typing in words to search backwards through your command history. You can hit `ctrl-r` at any time to cycle through search results for your current terms, and `enter` to execute the command on screen.

#### Example

I will start by generating a little bit of command history:

{% highlight bash %}
mike@diode:/$ echo "Hello"
Hello
mike@diode:/$ echo "World"
World
{% endhighlight %}

If I hit `ctrl-r` and start typing "echo", it will bring up the last command which matches my search:

{% highlight bash %}
(reverse-i-search)`echo': echo "World"
{% endhighlight %}

If I then hit `ctrl-r` again, it will cycle through past commands that match my search terms:

{% highlight bash %}
(reverse-i-search)`echo': echo "Hello"
{% endhighlight %}

Once I find the command I like, I just use the `enter` key to execute the command:

{% highlight bash %}
mike@diode:/$ echo "Hello"
Hello
{% endhighlight %}


#### Tip

Sometimes I find it useful to hit `ctrl-e` once I find a command I like. This moves the cursor to the end of the line so that I can edit the command a bit before executing.

If you change your mind while searching, you can just use `ctrl-c`.


### Repeating the Last Command
---

A quick and easy way to repeat your last command is `!!`. For example:

{% highlight bash %}
mike@diode:~$ echo hi
hi
mike@diode:~$ !!
echo hi
hi
{% endhighlight %}

This is especially useful if you forgot to include `sudo`:

{% highlight bash %}
mike@diode:~$ systemctl restart bind9
Failed to restart bind9.service: Access denied
See system logs and 'systemctl status bind9.service' for details.
mike@diode:~$ sudo !!
sudo systemctl restart bind9
[sudo] password for mike: 
mike@diode:~$ 
{% endhighlight %}


### Recalling the Final Argument of Previous Commands
---

I find sometimes a particular argument is the subject of many commands. If this argument is the last argument in previous commands, it can be brought up with `alt-.` (that is alt + period). You can hit `alt-.` multiple times to keep going back through previous commands.

### Clear the Screen
---
Sometimes I like to quickly clear the screen to make output easier to discern from previous output with `ctrl-l`.

### Quick Cut and Paste
---
You can "yank" everything before your cursor with a quick `ctrl-u`. When you are ready to put it back simply use `ctrl-y`.

I like to use this when I have a long command ready to execute, but then I decide to check something before running it. I will quickly `ctrl-u`, do whatever I wanted to do and then `ctrl-y` to put the original command right back. Make sure your cursor is at the end of the line with `ctrl-e`.

*BONUS*: You can move your cursor to the front of the line with `ctrl-a`.

There are a lot of keyboard shortcuts, these are just some of my most used. For a full list, you can see <a href="http://ss64.com/bash/syntax-keyboard.html" target="_blank">http://ss64.com/bash/syntax-keyboard.html</a>.

### Command Substitution
---
This isn't as much of a productivity shortcut as it is pretty much required for bash scripting in general and you're probably already using it. Nevertheless, one very common use of command substitution is to capture the output of a command in a `bash` script. You can use command substitution by wrapping your command in `$(` and `)`.

{% highlight bash %}
MAC_ADDR=$(ip a show label eth0 | grep link/ether | awk '{print $2}')
{% endhighlight %}

It is possible to also use command substitution with backticks:

    `command`
    
However you do *NOT* want to do this because you cannot nest with backticks like you can with `$(` and `)`. For example:

{% highlight bash %}
basename $(dirname $(grep -l ${MAC_ADDR} /sys/class/net/*/* 2>/dev/null))
{% endhighlight %}

To read more about command substitution, see <a href="http://tldp.org/LDP/abs/html/commandsub.html" target="_blank">http://tldp.org/LDP/abs/html/commandsub.html</a>.

### Process Substitution
---

This one is a little more advanced. You will find use for process substitution if a command expects a file for an argument, but you want to give it the output of another command instead.

In the following example, I will use process substitution and `diff` to compare the contents of two directories. You can tell which commands are being used for process substitution because they are wrapped in `<(` and `)`.

{% highlight bash %}
mike@diode:/tmp$ ls -l dir_1/ dir_2/
dir_1/:
total 0
-rw-r--r-- 1 mike mike 0 Jul 29 15:44 hello
-rw-r--r-- 1 mike mike 0 Jul 29 15:44 foo

dir_2/:
total 0
-rw-r--r-- 1 mike mike 0 Jul 29 15:44 hello
-rw-r--r-- 1 mike mike 0 Jul 29 15:44 bar

mike@diode:/tmp$ diff -u <(ls dir_1/) <(ls dir_2/)
--- /dev/fd/63  2016-07-29 15:44:23.343211057 -0700
+++ /dev/fd/62  2016-07-29 15:44:23.343211057 -0700
@@ -1,2 +1,2 @@
 hello
 -foo
 +bar
{% endhighlight %}

To read more about process substitution, see <a href="http://tldp.org/LDP/abs/html/process-sub.html" target="_blank">http://tldp.org/LDP/abs/html/process-sub.html</a>.

