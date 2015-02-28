module Content

# Content

# Server Setup

using HttpServer, WebSockets

function __init__()
  http = HttpHandler(http_handler)
  http.events["error"]  = (client, err) -> println(err)
  http.events["listen"] = (port)        -> println("Listening on $port...")

  const server = Server(http, WebSocketHandler(sock_handler))
  @schedule run(server, port())
end

function http_handler(req, res)
  readall(joinpath(dirname(@__FILE__), "main.html"))
end

function sock_handler(req, client)
  while true
    msg = read(client)
    write(client, msg)
  end
end

end
