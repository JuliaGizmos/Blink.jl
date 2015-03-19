# Resources

const resources = Dict{UTF8String, UTF8String}()

resource(f, name = basename(f)) = (resources[name] = f)

resroute() =
  branch(req -> length(req[:path]) == 1 && haskey(resources, req[:path][1]),
         req -> @d(:body => open(readbytes, resources[req[:path][1]]),
                   :headers => Mux.fileheaders(req[:path][1])))

# Server setup

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
   resroute(),
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
