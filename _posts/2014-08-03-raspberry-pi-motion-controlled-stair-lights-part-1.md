---
layout: posts
title: Raspberry Pi - Motion Controlled LED Lights on Stairs - Part 1
---

A quick back-story, my parents purchased a house in 2012 which could be classified as a bit of a "fixer-upper". As the motivated people they are, they decided to perform a large majority of the renovations themselves.

It was a couple months ago now, that I was sitting around talking to my father and he was telling me about how he had recently been in a local hardware store and they had this kit for sale where you would install LED lights into a flight of stairs there was a controller that would do all sorts of interesting things with the lights when you walked up to them. Continuing, he scoffs and explains that "They wanted $400 for that thing, no way!"

Instead he found some reasonably priced outdoor patio LED fixtures which you install into decking and they are meant to turn on and off with the rise and fall of the sun (light level sensors).

It was my turn to scoff, and I boasted that I could fill in the gap between his relatively simple patio lights and the over-priced kit from the hardware store. 
After I had returned back to Vancouver, I purchased some supplies from <a href="http://www.adafruit.com/" target="_blank">Adafruit</a>, including a prototyping board, PIR motion sensors and a relay. *Note, although I could have made a relay I really wanted to minimize fire risk for this project, keeping in mind where it was to be installed.*

* [Raspberry Pi Protoboard](http://www.adafruit.com/products/1171)
* [PIR Motion Sensors](http://www.adafruit.com/products/189)
* [Powerswitch Tail 2](http://www.adafruit.com/products/268)

I then started to prototype up the project and program the logic into my Raspberry Pi.
![Stairlights prototyping](/pictures/stairlights-proto.jpg)

The design consists of motion sensors at the top and bottom of the flight of stairs which then are connected to the Raspberry Pi via the protoboard. The Python script on the Pi controls the logic to switch on the relay for a period of time, when the motion sensors are tripped. This allows the lights to turn on when one walks up or down the stairs.

I decided to use Python for this project because the Raspberry Pi GPIO libraries are very good for Python. I also wrote an init script for Debian so that the stairlights script can start as a daemon upon boot-up.  Please feel free to check out the work and fork the project on [Github](https://github.com/mstathers/stairlights).

After I was done prototyping with a breadboard, I transferred my design to the Protoboard:
![Stairlights soldering](/pictures/stairlights-solder.jpg)

At this stage, I need to place the works into a project box and design connectors to allow the sensors to be detached from the project box. I was tempted to use ethernet cable, just because I have lots of that and I can use the standard jacks.

You can expect to see more updates here as I progress.
