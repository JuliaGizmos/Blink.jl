using HttpServer, WebSockets, JSON, Lazy

export Frame

include("config.jl")

# Content

type Frame
  id::Int
  sock::WebSocket
  handlers::Dict{ASCIIString, Any}

  function Frame(init = nothing)
    f = new(gen_id())
    f.handlers = Dict()
    init == nothing || (f.handlers["init"] = init)
    enable_callbacks!(f)
    pool[f.id] = WeakRef(f)
    finalizer(f, f -> delete!(pool, f.id))
    return f
  end
end

id(f::Frame) = f.id
handlers(f::Frame) = f.handlers
msg(f::Frame, m) = write(f.sock, json(m))

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
  local f
  try
    f = pool[parse_id(req.resource)].value
    # TODO: check if f already has a client, call init
  catch e
    close(client)
    return
  end
  f.sock = client
  while !client.is_closed
    data = read(client)
    @errs handle_message(f, JSON.parse(ASCIIString(data)))
  end
end

function __init__()
  http = HttpHandler(http_handler)
  http.events["error"]  = (client, err) -> println(err)
  http.events["listen"] = (port)        -> println("Listening on $port...")

  const server = Server(http, WebSocketHandler(sock_handler))
  @schedule @errs run(server, port())
end
