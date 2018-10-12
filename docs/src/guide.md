# Usage Guide

Using Blink to build a local web app has two basic steps:
1. Create a window and load all your HTML and JS.
2. Handle interaction between julia and your window.

## 1. Setting up a new Blink Window

Create a new window via [`Window`](@ref), and load some html via [`body!`](@ref).

```julia-repl
julia> using Blink

julia> w = Window(async=false) # Open a new window
Blink.AtomShell.Window(...)

julia> body!(w, "Hello World", async=false) # Set the body content
```

The main functions for setting content on a window are [`content!(w,
querySelector, html)`](@ref) and [`body!(w, html)`](@ref). `body!` is just
shorthand for `content!(w, "body", html)`.

You can also load an external url via `loadurl`, which will replace the current
content of the window:
```julia
loadurl(w, "http://julialang.org") # Load a web page
```

Note the use of `async=false` in the examples above. By default, these functions
return immediately, but setting `async=false` will block until the function has
completed. This is important if you are executing multiple statements in a row
that depend on the previous statement having completed.


### Loading stadalone HTML, CSS & JS files

You can load complete standalone files via the [`load!`](@ref) function. Blink
will handle the file correctly based on its file type suffix:
```julia
load!(w, "ui/app.css")
load!(w, "ui/frameworks/jquery-3.3.1.js")
```

You can also call the corresponding `importhtml!`, `loadcss!`, and `loadjs!` directly.

## 2. Setting up interaction between Julia and JS

```@setup Blink-w
using Blink
w = Window(Dict(:show=>false), async=false)
```

This topic is covered in more detail in the [Communication](@ref) page.

Just as you can directly write to the DOM via `content!`, you can
directly execute javscript via the [`@js`](@ref) macro.

```@repl Blink-w
@js w Math.log(10)
```

To invoke julia code from javascript, you can pass a "message" to julia:

```julia
# Set up julia to handle the "press" message:
handle(w, "press") do args
  @show args
end
# Invoke the "press" message from javascript whenever this button is pressed:
body!(w, """<button onclick='Blink.msg("press", "HELLO")'>go</button>""");
```
