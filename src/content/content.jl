using Mux, WebSockets, JSON, Lazy, Mustache

export Page, id, active

include("api.jl")

# Content

mutable struct Page
  id::Int
  sock::WebSocket
  handlers::Dict{String, Any}
  cb::Future

  function Page(init = nothing)
    serve()
    p = new(gen_id())
    p.handlers = Dict()
    p.cb = Future()
    init == nothing || (p.handlers["init"] = init)
    enable_callbacks!(p)
    pool[p.id] = WeakRef(p)
    finalizer(p) do p
      delete!(pool, p.id)
    end
    return p
  end
end

include("config.jl")

id(p::Page) = p.id
active(p::Page) = isdefined(p, :sock) && isopen(p.sock) && isopen(p.sock.socket)
handlers(p::Page) = p.handlers

function Base.wait(p::Page)
  wait(p.cb)
  return p
end

function msg(p::Page, m)
  active(p) || wait(p)
  write(p.sock, json(m))
end

const pool = Dict{Int, WeakRef}()

function gen_id()
  i = 1
  while haskey(pool, i) i += 1 end
  return i
end

include("server.jl")

@init for r in ["blink.js", "blink.css", "reset.css", "spinner.css"]
  resource(resolve_blink_asset("res", r))
end
