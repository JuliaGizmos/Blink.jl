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
