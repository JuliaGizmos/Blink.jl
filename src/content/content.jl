module Content

# Configuration

port() = get(ENV, "BLINK_PORT", 80)

const ippat = r"([0-9]+\.){3}[0-9]+"

@unix_only localips() =
  map(IPv4, readlines(`ifconfig` |>
                      `grep -Eo $("inet (addr:)?$(ippat.pattern)")` |>
                      `grep -Eo $(ippat.pattern)` |>
                      `grep -v $("127.0.0.1")`))

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

# Content

end
