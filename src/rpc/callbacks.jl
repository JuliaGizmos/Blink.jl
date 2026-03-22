# Message handling

export handle

handlers(o) = Dict()

handle_message(o, m) = Base.invokelatest(get(handlers(o), m["type"], identity), m["data"])

handle(f, o, t) = (handlers(o)[t] = f)

# Callback Tasks

const callbacks = Dict{Int, Channel{Any}}()

const counter = Ref(0)

function callback!()
  id = (counter[] += 1)
  cb = Channel{Any}(1)
  callbacks[id] = cb
  return id, cb
end

function callback!(id, value = nothing)
  haskey(callbacks, id) || return
  cb = callbacks[id]
  isready(cb) || put!(cb, value)
  delete!(callbacks, id)
  return
end

function wait_callback(cb::Channel{Any}; timeout::Real = 15.0)
  status = timedwait(() -> isready(cb), timeout)
  if status == :timed_out
    error("Blink callback timed out after $(timeout) seconds")
  end
  return take!(cb)
end

function enable_callbacks!(o)
  handle(o, "callback") do m
    callback!(m["callback"], get(m, "result", nothing))
  end
end
