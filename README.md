# Blink.jl

Blink.jl provides a Julia API for creating and working with browser windows, (currently) via [Atom-Shell](https://github.com/atom/atom-shell).

Basic usage:

```julia
Pkg.add("Blink")
using Blink
a = Blink.init() # initialise the atom-shell process
w = Window(a) # Open a new window
body(w, "<h1>Hello World</h1>") # Set the body content
loadurl(w, "http://julialang.org") # Load a web page
```

For options see the functions defined in [window.jl](src/window.jl), which closely follow [atom-shell's API](https://github.com/atom/atom-shell/blob/master/docs/api/browser-window.md).

## BlinkDisplay

Blink.jl also provides the the `BlinkDisplay` module, which provides a pop-up window for Julia graphics.

```julia
using Blink, Gadfly
BlinkDisplay.init()
plot(x = 1:100, y = cumsum(rand(100)-0.5), Geom.line)
```

You'll see a pop up window open for each plot. If you want to use the same window for subsequent plots call the `pin()` function. Also available is `pin(id)` (where a window's `id` is displayed in its title bar) and `unpin()`.

Blink.jl also provides the `docs()` and `docs("search")` functions for quickly viewing the Julia manual. Hopefully in the not-too-distant future it will include nice tools for exploring images, datasets etc.

### Display System

Blink.jl ships with its own [display system](src/graphics/system.jl), which enables the user handle multiple input/output devices and decide what media types get displayed where. By default, `BlinkDisplay.init()` simply calls

```julia
setdisplay(Media.Graphical, BlinkDisplay._display)
```

which means "display graphical output on the BlinkDisplay device". You could also set tabular data (e.g. Matrices and DataFrames) to display with Blink.jl:

```julia
setdisplay(Media.Tabular, BlinkDisplay._display)
rand(5, 5) #> Displays in pop up window
```

or set the display for specific types (abstract or concrete):

```julia
setdisplay(FloatingPoint, BlinkDisplay._display)
2.3 #> Displays with Blink
```

In principle you can also set displays for a given input device, although this needs more support from Base to work well.

## Debugging

`Blink.init(debug = true)` will initialize Atom-Shell with output redirected to the terminal. If you have node-inspector installed, it will also launch a debugger for the Atom-Shell browser process.

You can open the devtools for a specific window with `tools(w)`.

## Issues & Caveats

* Blink.jl communicates with browser processes over TCP. This limits the practicality of JS interop; you need to write a JS gui with a Julia backend as opposed to a pure-Julia app. Hopefully in the future we can get something more direct going with Cxx.jl & libchromiumcontent
* On Windows, the spawned process dumps its output into Julia's STDOUT, which is kind of annoying.
