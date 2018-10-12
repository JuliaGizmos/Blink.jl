import JSExpr: @js, @js_str, JSString, jsstring, jsexpr, @var, @new
using Lazy: @d

export js, @js, @js_, @var, @new

# include("jsexprs.jl")

include("callbacks.jl")

mutable struct JSError <: Exception
    name::String
    msg::String
end

Base.showerror(io::IO, e::JSError) =
    print(io, "Javascript error\t$(e.name): $(e.msg)")

# RPC API

export js, js_, @js, @js_, @var, @new

"""
    js(win, expr::JSString; callback=false)

Execute the javscript in `expr`, inside `win`.

If `callback==true`, returns the result of evaluating `expr`.
"""
function js end

"""
    JSString(str)

A wrapper around a string indicating the string contains javascript code.
"""
function JSString end

msg(o, m) = error("$(typeof(o)) object doesn't support JS messages")

function js(o, js::JSString; callback = true)
  cmd = @d(:type => :eval,
           :code => js.s)
  if callback
    id, cond = callback!()
    cmd[:callback] = id
  end
  msg(o, cmd)

  if callback
      val = wait(cond)
      if isa(val, AbstractDict) && get(val, "type", "") == "error"
          err = JSError(get(val, "name", "unknown"), get(val, "message", "blank"))
          throw(err)
      end
      return val
  else
      return o
  end
end

js(o, j; callback=true) = js(o, JSString(string(jsstring(j)...)); callback=callback)

"""
    @js win expr

Execute `expr`, converted to javascript, inside `win`, and return the result.

`expr` will be parsed as julia code, and then converted directly to the
equivalent javascript. Language keywords that don't exist in julia can be
represented with their macro equivalents, `@var`, `@new`, etc.

See also: `@js_`, the asynchronous version.

# Examples
```julia-repl
julia> @js win x = 5
5
julia> @js_ win for i in 1:x console.log(i) end
```
"""
macro js(o, ex)
    :(js($(esc(o)), $(Expr(:quote, ex))))
end

"""
    @js_ win expr

Execute `expr`, converted to javascript, asynchronously inside `win`, and return
immediately.

`expr` will be parsed as julia code, and then converted directly to the
equivalent javascript. Language keywords that don't exist in julia can be
represented with their macro equivalents, `@var`, `@new`, etc.

See also: `@js`, the synchronous version that returns its result.

# Examples
```julia-repl
julia> @js win x = 5
5
julia> @js_ win for i in 1:x console.log(i) end
```
"""
macro js_(o, ex)
    :(js($(esc(o)), $(Expr(:quote, ex)), callback=false))
end
