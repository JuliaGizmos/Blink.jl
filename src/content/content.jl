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

# Server Setup

function page_handler(req)
  id = try parse(req[:params][:id]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  return readall(joinpath(dirname(@__FILE__), "main.html"))

  @label fail
  return @d(:body => "Not found",
            :status => 404)
end

function ws_handler(req)
  id = try parse(req[:params][:id]) catch e @goto fail end
  client = req[:socket]
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = client
  @errs get(handlers(p), "init", identity)(p)
  while active(p)
    try
      data = read(client)
    catch e
      if isa(e, ErrorException) && contains(e.msg, "closed WebSocket")
        handle_message(p, @d("type"=>"close"))
        break
      else
        rethrow()
      end
    end
    @errs handle_message(p, JSON.parse(ASCIIString(data)))
  end
  return

  @label fail
  close(client)
end

@app http_default =
  (Mux.defaults,
   page(":id", page_handler),
   Mux.notfound())

@app ws_default =
  (Mux.wdefaults,
   page(":id", ws_handler),
   Mux.wclose)

function __init__()
  get(ENV, "BLINK_SERVE", "true") in ("1", "true") || return
  serve(http_default, ws_default, port)
end
