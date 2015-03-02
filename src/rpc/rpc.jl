# This basically just defines an API and utilities for
# JS RPCs – the implementation is left to specific objects.

# Note that this API is very limited. Although it would
# be perfectly possible to have full interop with references
# to JS objects etc., it would be an enormously leaky
# abstraction over a TCP connection with any latency.

# Convert Julia `Expr`s to strings of JS

include("jsexprs.jl")

# RPC API

export js, js_, @js, @js_, @var, @new

# Implement this method
js(o, ::JSString; callback = true) = error("$(typeof(o)) object doesn't support JS calls")

js(o, s; callback = true) = js(o, jsexpr(s); callback = callback)

js_(args...) = js(args..., callback = false)

macro js(o, ex)
  :(js($(esc(o)), $(Expr(:quote, ex))))
end

macro js_(o, ex)
  :(js_($(esc(o)), $(Expr(:quote, ex))))
end

# Callback utils

const callbacks = Dict{Int,Condition}()

const counter = [0]

function callback!()
  id = (counter[1] += 1)
  cb = Condition()
  callbacks[id] = cb
  return id, cb
end

function callback!(id, value = nothing)
  haskey(callbacks, id) || return
  notify(callbacks[id], value)
  delete!(callbacks, id)
  return
end
