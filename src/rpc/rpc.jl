# This basically just defines an API and utilities for
# JS RPCs – the implementation is left to specific objects.

# Note that this API is very limited. Although it would
# be perfectly possible to have full interop with references
# to JS objects etc., it would be an enormously leaky
# abstraction over a TCP connection with any latency.

# Convert Julia `Expr`s to strings of JS

include("jsexprs.jl")
include("callbacks.jl")

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
  return callback ? wait(cond) : o
end

js(o, s; callback = true) = js(o, jsexpr(s); callback = callback)

js_(args...) = js(args..., callback = false)

macro js(o, ex)
  :(js($(esc(o)), $(Expr(:quote, ex))))
end

macro js_(o, ex)
  :(js_($(esc(o)), $(Expr(:quote, ex))))
end
