# Message handling

export handle

handlers(o) = Dict()

handle_message(o, m) = Base.invokelatest(get(handlers(o), m["type"], identity), m["data"])

handle(f, o, t) = (handlers(o)[t] = f)

# Callback Tasks

const callbacks = Dict{Int,Threads.Condition}()

const counter = Ref(0)

function callback!()
  id = (counter[] += 1)
  cb = Threads.Condition()
  callbacks[id] = cb
  return id, cb
end

function callback!(id, value = nothing)
  haskey(callbacks, id) || return
  c = callbacks[id]
  lock(c)
  try
    notify(callbacks[id], value)
  finally
    unlock(c)
  end
  delete!(callbacks, id)
  return
end

function enable_callbacks!(o)
  handle(o, "callback") do m
    callback!(m["callback"], get(m, "result", nothing))
  end
end
