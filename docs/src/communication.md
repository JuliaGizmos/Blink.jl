# [Communication between Julia and Javascript](@id Communication)

After creating a Window and loading HTML and JS, you may want to interact with
julia code (e.g. by clicking a button in HTML, or displaying a plot from julia).

This section covers this two-way communication.

## Julia to Javascript
```@setup Blink-win
using Blink
win = Window(Dict(:show=>false), async=false)
```

The easiest way to communicate to javascript from julia is with the [`@js`](@ref) and
[`@js_`](@ref) macros. These macros allow you to execute arbitrary javascript code in a
given Window.

```@repl Blink-win
@js win x = 5;
@js win x
```

The `@js_` macro executes its code asynchronously, but doesn't return its
result:
```@repl Blink-win
@time @js win begin   # Blocks until finished; `i` is returned
  for i in 0:1000000 end  # waste time
  i  # return i
end

@time @js_ win begin   # Returns immediately, but `i` is not returned.
  for i in 0:1000000 end  # waste time
  i  # This is ignored
end
```

If your javascript expression is complex, or you want to copy-paste existing
javascript, it can be easier to represent it as a pure javascript string.
For that, you can call the [`js`](@ref) function with a [`JSString`](@ref Blink.JSString):
```@repl Blink-win
body!(win, """<div id="box" style="color:red;"></div>""", async=false);
div_id = "box";
js(win, Blink.JSString("""document.getElementById("$div_id").style.color"""))
```

Note that the code passed to these macros runs in its own scope, so any
javascript variables you create with `var` (or the `@var` equivalent for `@js`)
will be inaccessible after returning:
```@repl Blink-win
@js win (@var x_var = 5; x_var)  # x_var is only accessible within this scope.
@js win x_var
```

## Javascript to Julia
Communication from javascript to julia currently works via a message passing
interface.

To invoke julia code from javascript, you specify a julia callback via `handle`:
```julia-repl
julia> handle(w, "press") do args
         @show args
       end
```
This callback can then be triggered from javscript via `Blink.msg()`:
```@setup handler
using Blink
w = Window(Dict(:show=>false), async=false)
handle(w, "press") do args
  @show args
end
```
```@repl handler
@js w Blink.msg("press", "Hello from JS");
```
Note that the javascript function `Blink.msg` takes _exactly_ 1 argument.  To
pass more or fewer arguments, pass your arguments as an array:
```@repl handler
handle(w, "event") do count, values, message
  # ...
end
@js w Blink.msg("event", [1, ['a','b'], "Hi"]);
```

Finally, here is an example that uses a button to call back to julia:
```@setup Blink-w
using Blink
w = Window(Dict(:show=>false), async=false)
```
```@repl Blink-w
handle(w, "press") do arg
  println(arg)
end
body!(w, """<button onclick='Blink.msg("press", "HELLO")'>go</button>""", async=false);
```
Now, clicking the button will print `HELLO` to julia's STDOUT.


## Back-and-forth

Note that you cannot make a synchronous call to javascript from _within_ a julia
callback, or you'll cause julia to hang:

**BAD**:
```julia-repl
julia> @js w x = 5

julia> handle(w, "press") do args...
         # Increment x and get its new value
         x = @js w (x += 1; x)  # ERROR: Cannot make synchronous calls within a callback.
         println("New value: $x")
       end
#9 (generic function with 1 method)

julia> @js w Blink.msg("press", [])

# JULIA HANGS UNTIL CTRL-C, WHICH KILLS YOUR BLINK WINDOW.
```

**GOOD**: Instead, if you need to access the value of `x`, you should simply
provide it when invoking the `press` handler:
```@repl Blink-w
@js w x = 5

handle(w, "press") do args...
  x = args[1]
  # Increment x
  @js_ w (x = $x + 1)  # Note the _asynchronous_ call.
  println("New value: $x")
end

@js w Blink.msg("press", x)
# JULIA HANGS UNTIL CTRL-C, WHICH KILLS YOUR BLINK WINDOW.
```


## Tasks

The julia webserver is implemented via Julia
[Tasks](https://docs.julialang.org/en/v1/manual/control-flow/#man-tasks-1). This
means that julia code invoked from javascript will run _sort of_ in parallel to
your main julia code.

In particular:
 - Tasks are _coroutines, not threads_, so they aren't truly running in parallel.
 - Instead, execution can switch between your code and the coroutine's code whenever a piece of computation is _interruptible_.

So, if your Blink callback handler performs uninterruptible work, it will fully
occupy your CPU, preventing any other computation from occuring, and can
potentially hang your computation.

### Examples:

**BAD**: If your callback runs a long loop, it won't be uninterruptible while
it's running:
```julia-repl
julia> handle(w, "press") do args...
         println("Start")
         while true end  # infinite loop
         println("End")
       end
#40 (generic function with 1 method)

julia> body!(w, """<button onclick='Blink.msg("press", 1)'>go</button>""", async=false);

julia> # CLICK THE go BUTTON, AND YOUR PROCESS WILL FREEZE
Start
```

**BAD**: The same is true if your _main_ julia computation is hogging the CPU, then
your callback can't run:
```julia-repl
julia> handle(w, "press") do args...
         println("Start")
         sleep(5) # This will happily yield to any other computation.
         println("End")
       end
#41 (generic function with 1 method)

julia> body!(w, """<button onclick='Blink.msg("press", 1)'>go</button>""", async=false);

julia> while true end  # Infinite loop

# NOW, CLICK THE go BUTTON, AND NOTHING HAPPENS, SINCE THE CPU IS BEING HOGGED!
```

**GOOD**: So to allow for happy communication, all your computations should be interruptible, which you can achieve with calls such as `yield`, or `sleep`:
```julia-repl
julia> handle(w, "press") do args...
         println("Start")
         sleep(5) # This will happily yield to any other computation.
         println("End")
       end
#39 (generic function with 1 method)

julia> body!(w, """<button onclick='Blink.msg("press", 1)'>go</button>""", async=false);

julia> while true  # Still an infinite loop, but a _fair_ one.
         yield()  # This will yield to any other computation, allowing the callback to run.
       end

# NOW, CLICKING THE go BUTTON WILL WORK CORRECTLY ✅
Start
End
```
