export body!, content!, loadcss!, loadjs!, load!, importhtml!

function content!(o, sel, html::AbstractString; fade = true, async = true)
  if async
    @js_(o, Blink.fill($sel, $html, $fade, null, null))
  else
    @js o begin  # Use `@js` to wait until the below Promise is resolved.
      @new Promise(function (resolve, reject)
        Blink.fill($sel, $html, $fade, resolve, reject)
      end)
    end
    return o  # But still return `o` for chaining.
  end
end

content!(o, sel, html; fade = true, async = true) =
  content!(o, sel, stringmime(MIME"text/html"(), html), fade=fade, async=async)

body!(w, html; fade = true, async = true) = content!(w, "body", html, fade=fade, async=async)

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
  @js w @new Promise(function (resolve, reject)
    @var script = document.createElement("script")
    script.src = $url
    script.onload = resolve
    script.onerror = (e) -> reject(
                               Dict("name"=>"JSLoadError",
                                    "message"=>"failed to load " + this.src)
                                    )
    document.head.appendChild(script)
  end)
end

isurl(f) = occursin(r"^https?://", f)

function load!(w, file; async=false)
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
    importhtml!(w, file; async=async)
  else
    error("Blink: Unsupported file type")
  end
end
