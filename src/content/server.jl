# Resources

const resources = Dict{String, String}()

resource(f, name = basename(f)) = (@assert isfile(f); resources[name] = f)

const resroute =
  branch(req -> length(req[:path]) == 1 && haskey(resources, req[:path][1]),
         req -> d(:body => open(read, resources[req[:path][1]]),
                  :headers => Mux.fileheaders(req[:path][1])))

# Server setup

const maintp = Mustache.template_from_file(joinpath(dirname(@__FILE__), "main.html"))

app(f) = req -> render(maintp, d("id"=>Page(f).id))

function page_handler(req)
  id = try parse(Int, req[:params][:id]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  callback_id = try split(req[:query], "=")[2] catch e nothing end
  callback_script = callback_id != nothing ? """var callback_id = $callback_id""" : ""
  return render(maintp, d("id"=>id,
                          "optional_create_window_callback"=>callback_script))

  @label fail
  return d(:body => "Not found",
           :status => 404)
end

function ws_handler(req)
  id = try parse(Int, req[:path][end]) catch e @goto fail end
  client = req[:socket]
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = client
  @async @errs get(handlers(p), "init", identity)(p)
  put!(p.cb, true)
  while active(p)
    local data
    try
      data = read(client)
    catch e
      if (isa(e, ArgumentError) && contains(e.msg, "closed")) || isa(e, WebSockets.WebSocketClosedError)
        handle_message(p, d("type"=>"close", "data"=>nothing))
        yield() # Prevents an HttpServer task error (!?)
        return
      else
        rethrow()
      end
    end
    @errs handle_message(p, JSON.parse(String(data)))
  end
  return

  @label fail
  close(client)
end

http_default =
  mux(Mux.defaults,
      resroute,
      page(":id", page_handler),
      Mux.notfound())

ws_default =
  mux(Mux.wdefaults,
      ws_handler)

const serving = Ref(false)

function serve()
  serving[] && return
  serving[] = true
  http = Mux.http_handler(Mux.App(http_default))
  ws = Mux.ws_handler(Mux.App(ws_default))
  @async begin
    # Suppress log output from HTTP.jl unless the user has already
    # configured a custom logger. See:
    # https://github.com/JuliaLang/julia/pull/28229#issuecomment-410229612
    if current_task().logstate === nothing
      with_logger(NullLogger()) do
        WebSockets.serve(WebSockets.ServerWS(http, ws), ip"127.0.0.1", port[], false)
      end
    else
      WebSockets.serve(WebSockets.ServerWS(http, ws), ip"127.0.0.1", port[], false)
    end
  end
end
