# Blink.jl 
[![Build Status](https://travis-ci.org/JunoLab/Blink.jl.svg?branch=master)](https://travis-ci.org/JunoLab/Blink.jl) 
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JunoLab.github.io/Blink.jl/stable) 
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JunoLab.github.io/Blink.jl/latest)

Blink.jl is the Julia wrapper around [Electron](https://electronjs.org/). It 
can serve HTML content in a local window, and allows for communication between
Julia and the web page. In this way, therefore, Blink can be used as a GUI
toolkit for building HTML-based applications for the desktop.

To install, do:
```julia
Pkg.add("Blink")
Blink.AtomShell.install()
```

Basic usage:

```julia
julia> Pkg.add("Blink")
# ... Blink builds and downloads Electron ...

julia> using Blink

julia> w = Window() # Open a new window
Blink.AtomShell.Window(...)

julia> body!(w, "Hello World") # Set the body content

julia> loadurl(w, "http://julialang.org") # Load a web page
```

For options see the functions defined in [window.jl](src/AtomShell/window.jl), which closely follow [electron's API](https://github.com/atom/electron/blob/master/docs/api/browser-window.md).

You can also use the JS API to interact with the window. For example:

```julia
julia> @js w Math.log(10)
2.302585092994046
```

If that's not convincing enough, open the console (`Cmd-Alt-I` on OS X) and evaluate:

```julia
@js w console.log("hello, web-scale world")
```

## Issues & Caveats

* On Windows, the spawned process dumps its output into Julia's STDOUT, which is kind of annoying.
