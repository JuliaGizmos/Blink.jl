# Blink.jl

Linux, OSX: [![Build Status](https://travis-ci.org/JunoLab/Blink.jl.svg?branch=master)](https://travis-ci.org/JunoLab/Blink.jl)


Blink.jl provides a API for communicating with web pages from Julia. Pages may be served over the internet and controlled from the browser, or served locally via an [Electron](https://github.com/atom/Electron) window. Blink can therefore be used as a GUI toolkit – [DevTools.jl](https://github.com/JunoLab/DevTools.jl) for an example use.

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
