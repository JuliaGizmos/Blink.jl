using Mux, WebSockets, JSON, Lazy

export Page, id, active

include("api.jl")

# Content

type Page
  id::Int
  sock::WebSocket
  handlers::Dict{ASCIIString, Any}

  function Page(init = nothing)
    p = new(gen_id())
    p.handlers = Dict()
    init == nothing || (p.handlers["init"] = init)
    enable_callbacks!(p)
    pool[p.id] = WeakRef(p)
    finalizer(p, p -> delete!(pool, p.id))
    return p
  end
end

include("config.jl")

id(p::Page) = p.id
active(p::Page) = isdefined(p, :sock) && isopen(p.sock) && isopen(p.sock.socket)
handlers(p::Page) = p.handlers
msg(p::Page, m) = write(p.sock, json(m))

const pool = Dict{Int, WeakRef}()

function gen_id()
  i = 1
  while haskey(pool, i) i += 1 end
  return i
end

include("server.jl")

for r in ["blink.js", "blink.css", "spinner.css"]
  resource(Pkg.dir("Blink", "res", r))
end
