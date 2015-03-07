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

parse_id(s::String) = try parseint(s[2:end]) catch e nothing end

function http_handler(req, res)
  id = parse_id(req.resource)
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  return readall(joinpath(dirname(@__FILE__), "main.html"))

  @label fail
  res = Response("Not found")
  res.status = 404
  return res
end

function sock_handler(req, client)
  id = parse_id(req.resource)
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = client
  while active(p)
    data = read(client)
    @errs handle_message(p, JSON.parse(ASCIIString(data)))
  end
  return

  @label fail
  close(client)
end

function __init__()
  get(ENV, "BLINK_SERVE", "true") in ("1", "true") || return
  http = HttpHandler(http_handler)
  http.events["error"]  = (client, err) -> println(err)
  http.events["listen"] = (port)        -> println("Listening on $port...")

  const server = Server(http, WebSocketHandler(sock_handler))
  @schedule @errs run(server, port)
end
