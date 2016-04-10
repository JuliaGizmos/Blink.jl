# Resources

const resources = Dict{UTF8String, UTF8String}()

resource(f, name = basename(f)) = (@assert isfile(f); resources[name] = f)

const resroute =
  branch(req -> length(req[:path]) == 1 && haskey(resources, req[:path][1]),
         req -> d(:body => open(readbytes, resources[req[:path][1]]),
                  :headers => Mux.fileheaders(req[:path][1])))

# Server setup

const maintp = Mustache.template_from_file(joinpath(dirname(@__FILE__), "main.html"))

app(f) = req -> render(maintp, d("id"=>Page(f).id))

function page_handler(req)
  id = try parse(req[:params][:id]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  return render(maintp, d("id"=>id))

  @label fail
  return d(:body => "Not found",
           :status => 404)
end

function ws_handler(req)
  id = try parse(req[:path][end]) catch e @goto fail end
  client = req[:socket]
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = client
  @schedule @errs get(handlers(p), "init", identity)(p)
  notify(p.cb)
  while active(p)
    local data
    try
      data = read(client)
    catch e
      if isa(e, ArgumentError) && contains(e.msg, "closed")
        handle_message(p, d("type"=>"close"))
        yield() # Prevents an HttpServer task error (!?)
        return
      else
        rethrow()
      end
    end
    @errs handle_message(p, JSON.parse(UTF8String(data)))
  end
  return

  @label fail
  close(client)
end

const user_middleware = Dict(:http=>(x,y)->x(y), :ws=>(x,y)->x(y))

set_user_middleware!(m; websocket=false) =
    user_middleware[websocket ? :ws : :http] = m

make_user_middleware(typ) = (x, y) -> user_middleware[typ](x, y)

http_default =
  mux(Mux.defaults,
      resroute,
      make_user_middleware(:http),
      page(":id", page_handler),
      Mux.notfound())

ws_default =
  mux(Mux.wdefaults,
      make_user_middleware(:ws),
      ws_handler)

isprecompiling() = ccall(:jl_generating_output, Cint, ()) == 1

@init if !isprecompiling()
  get(ENV, "BLINK_SERVE", "true") in ("1", "true") || return
  http = Mux.http_handler(Mux.App(http_default))
  delete!(http.events, "listen")
  ws = Mux.ws_handler(Mux.App(ws_default))
  serve(Mux.Server(http, ws), port)
end
