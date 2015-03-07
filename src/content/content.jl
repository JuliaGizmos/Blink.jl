using HttpServer, WebSockets, JSON, Lazy

export Page, id, active

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

# Server Setup

parse_id(s::String) = parseint(s[2:end])

function http_handler(req, res)
  try
    pool[parse_id(req.resource)] # Only valid if frame with the ID exists
  catch e
    res = Response("Not found")
    res.status = 404
    return res
  end
  return readall(joinpath(dirname(@__FILE__), "main.html"))
end

function sock_handler(req, client)
  local p
  try
    p = pool[parse_id(req.resource)].value
    # TODO: check if f already has a client, call init
  catch e
    close(client)
    return
  end
  p.sock = client
  while active(p)
    data = read(client)
    @errs handle_message(p, JSON.parse(ASCIIString(data)))
  end
end

function __init__()
  get(ENV, "BLINK_SERVE", "true") in ("1", "true") || return
  http = HttpHandler(http_handler)
  http.events["error"]  = (client, err) -> println(err)
  http.events["listen"] = (port)        -> println("Listening on $port...")

  const server = Server(http, WebSocketHandler(sock_handler))
  @schedule @errs run(server, port)
end
