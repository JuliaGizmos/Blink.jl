# Resources
import HTTP.WebSockets: CloseFrameBody
const resources = Dict{String, String}()

resource(f, name = basename(f)) = (@assert isfile(f); resources[name] = f)

const resroute =
  branch(req -> length(req[:path]) == 1 && haskey(resources, req[:path][1]),
         req -> Dict(:body => open(read, resources[req[:path][1]]),
                  :headers => Mux.fileheaders(req[:path][1])))

# Server setup

const maintp = Mustache.template_from_file(joinpath(@__DIR__, "main.html"))

app(f) = req -> render(maintp, Dict(
  "id" => Page(f).id,
  # "webio_bundle" => basename(WebIO.bundlepath)
))

function page_handler(req)
  id = try parse(Int, req[:params][:id]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  callback_id = try split(req[:query], "=")[2] catch e nothing end
  callback_script = callback_id != nothing ? """var callback_id = $callback_id""" : ""
  return render(maintp, Dict("id"=>id,
                          "optional_create_window_callback"=>callback_script))

  @label fail
  return Dict(:body => "Not found",
           :status => 404)
end

function ws_handler(ws)
  id = try parse(Int, split(ws.request.target, "/", keepempty=false)[end]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = ws
  @async @errs get(handlers(p), "init", identity)(p)
  try
    put!(p.cb, true)
  catch e
    @warn e
  end
  for msg in ws
    @errs handle_message(p, JSON.parse(String(msg)))
  end
  return

  @label fail
  close(ws, CloseFrameBody(1000, ""))
end

http_default =
  mux(Mux.defaults,
      resroute,
      page(":id", page_handler),
      Mux.notfound())

const serving = Ref(false)
const server = Ref{Mux.HTTP.Servers.Server}()

function serve()
  serving[] && return
  serving[] = true
  server[] = Mux.serve(Mux.App(http_default), Mux.App(ws_handler), ip"127.0.0.1", port[])
end

function stopserve()
  serving[] || return
  serving[] = false
  close(server[])
end
