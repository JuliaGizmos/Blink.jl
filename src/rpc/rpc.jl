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
      if isa(val, Associative) && get(val, "type", "") == "error"
          err = JSError(get(val, "name", "unknown"), get(val, "message", "blank"))
          throw(err)
      end
      return val
  else
      return o
  end
end

js(o, j; callback=true) = js(o, JSString(string(jsstring(j)...)); callback=callback)

macro js(o, ex)
    :(js($(esc(o)), $(Expr(:quote, ex))))
end

macro js_(o, ex)
    :(js($(esc(o)), $(Expr(:quote, ex)), callback=false))
end

