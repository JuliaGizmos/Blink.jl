export body!, content!, loadcss!, loadjs!, load!, importhtml!

content!(o, sel, html::AbstractString; fade = true) =
  fade ?
    @js_(o, Blink.fill($sel, $html)) :
    @js_ o document.querySelector($sel).innerHTML = $html

content!(o, sel, html; fade = true) =
  content!(o, sel, stringmime(MIME"text/html"(), html), fade = fade)

body!(w, html; fade = true) = content!(w, "body", html, fade = fade)

function loadcss!(w, url)
  @js_ w begin
    @var link = document.createElement("link")
    link.type = "text/css"
    link.rel = "stylesheet"
    link.href = $url
    document.head.appendChild(link)
  end
end

function importhtml!(w, url; async=false)
  if async
    @js_ w begin
      @var link = document.createElement("link")
      link.rel = "import"
      link.href = $url
      document.head.appendChild(link)
    end
  else
    @js w begin
      @new Promise(function (resolve, reject)
          @var link = document.createElement("link")
          link.rel = "import"
          link.href = $url
          link.onload = (e) -> resolve(true)
          link.onerror = (e) -> reject(false)
          document.head.appendChild(link)
      end)
    end
  end
end

function loadjs!(w, url)
  @js w @new Promise(function (resolve)
    @var script = document.createElement("script")
    script.src = $url
    script.onload = resolve
    document.head.appendChild(script)
  end)
end

isurl(f) = ismatch(r"^https?://", f)

function load!(w, file)
  if !isurl(file)
    resource(file)
    file = basename(file)
  end
  ext = Mux.extension(file)
  if ext == "js"
    loadjs!(w, file)
  elseif ext == "css"
    loadcss!(w, file)
  elseif ext == "html"
    importhtml!(w, file)
  else
    error("Blink: Unsupported file type")
  end
end

function addblink!(w)
    varid = "var id = $(w.id)"
    ws = "ws://127.0.0.1:$(Blink.port)/$(w.id)"
    src = "http://127.0.0.1:$(Blink.port)/blink.js"
    @js_ w begin
        varid = document.createElement("script")
        varid.type = "text/javascript";
        varid.innerText = $varid
        document.head.appendChild(varid);
        blinkjs = document.createElement("script");
        blinkjs.type = "text/javascript";
        blinkjs.src = $src
        blinkjs.onload = e -> (Blink.sock = @new WebSocket($ws))
        document.head.appendChild(blinkjs);
    end
end
