# This basically just defines an API and utilities for
# JS RPCs – the implementation is left to specific objects.

# Note that this API is very limited. Although it would
# be perfectly possible to have full interop with references
# to JS objects etc., it would be an enormously leaky
# abstraction over a TCP connection with any latency.

# Convert Julia `Expr`s to strings of JS

include("jsexprs.jl")
include("callbacks.jl")

# Message handling

export handle

handlers(o) = Dict()

handle_message(o, m) = get(handlers(o), m["type"], identity)(m)

handle(f, o, t) = (handlers(o)[t] = f)

# RPC API

export js, js_, @js, @js_, @var, @new

# msg(o, )

js(o, ::JSString; callback = true) = error("$(typeof(o)) object doesn't support JS calls")

js(o, s; callback = true) = js(o, jsexpr(s); callback = callback)

js_(args...) = js(args..., callback = false)

macro js(o, ex)
  :(js($(esc(o)), $(Expr(:quote, ex))))
end

macro js_(o, ex)
  :(js_($(esc(o)), $(Expr(:quote, ex))))
end
