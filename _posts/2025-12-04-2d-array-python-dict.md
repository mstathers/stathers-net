---
layout: posts
title: Using a Python Dictionary to Represent a 2D Grid
tags: python TIL
---

It's <a href="https://adventofcode.com/">Advent of Code</a> time! Problems featuring a two dimensional grid are not uncommon, so developing a strategy to deal with this is useful.

In the past I would use a pair of nested arrays to represent this grid. This was a bit messy, you would have to reference grid coordinates "backwards" as `Y, X`, and it would require all sorts of additional out-of-bounds checking.

An improvement is to use a dictionary where the key is a tuple of "X,Y" coordinates.

### Sample Input
Just a simple 3x3 grid of sequential whole numbers. I'm not going to actually bother to convert these to integers for our example, because the value actually doesn't matter for this strategy.
{% highlight python %}
>>> print(input)
012
345
678
{% endhighlight %}

### Populating the Dictionary
{% highlight python %}
grid = {}
for y, line in enumerate(input.split('\n')):
    for x, val in enumerate(line):
        grid[(x, y)] = val
{% endhighlight %}

### Accessing the Data
Use a tuple for the dictionary key. `x=1, y=2`
{% highlight python %}
>>> grid[(1, 2)]
'7'
{% endhighlight %}

### Searching the Grid
Dictionary comprehension can be used to search the grid for keys that hold the desired value.
{% highlight python %}
>>> [key for key, val in grid.items() if val == '7']
[(1, 2)]
{% endhighlight %}

### Finding Neighbors
In the Advent of Code problems, finding the contents of neighboring locations is also very common. This function will return a list of all neighboring locations, for a given position.
{% highlight python %}
def get_neighbors(grid: dict, pos: tuple) -> list[tuple]:
    x0, y0 = pos
    candidates = [
        (x0 - 1, y0 + 1),(x0, y0 - 1),(x0 + 1, y0 - 1),
        (x0 - 1, y0),                 (x0 + 1, y0),
        (x0 - 1, y0 - 1),(x0, y0 + 1),(x0 + 1, y0 + 1),
    ]
    return [p for p in candidates if p in grid]
{% endhighlight %}

We can see that the `1,2` coordinate location (value: `7`) has five valid neighboring locations:
{% highlight python %}
>>> get_neighbors(grid, (1,2))
[(1, 1), (2, 1), (0, 2), (2, 2), (0, 1)]
{% endhighlight %}




#### Future Learning - Complex Numbers
I've seen people discuss using <a href="https://en.wikipedia.org/wiki/Complex_number">complex numbers</a> to represent the grids. I honestly haven't wrapped my head around the math for that, but I would like to learn.
