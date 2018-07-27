export body!, content!, loadcss!, loadjs!, load!, importhtml!

content!(o, sel, html::AbstractString; fade = true) =
    @js_(o, Blink.fill($sel, $html, $fade))

content!(o, sel, html; fade = true) =
  content!(o, sel, stringmime(MIME"text/html"(), html), fade = fade)

body!(w, html; fade = true) = content!(w, "body", html, fade = fade)

function loadcss!(w, url)
  # Uses Expr(:var, ...) instead of @var to work around issue #134
  @js_ w begin
    $(Expr(:var, :(link = document.createElement("link"))))
    link.type = "text/css"
    link.rel = "stylesheet"
    link.href = $url
    document.head.appendChild(link)
  end
end

function importhtml!(w, url; async=false)
  # Uses Expr(:var, ...) instead of @var to work around issue #134
  if async
    @js_ w begin
      $(Expr(:var, :(link = document.createElement("link"))))
      link.rel = "import"
      link.href = $url
      document.head.appendChild(link)
    end
  else
    @js w begin
      $(Expr(:new, :(Promise(function (resolve, reject)
          $(Expr(:var, :(link = document.createElement("link"))))
          link.rel = "import"
          link.href = $url
          link.onload = (e) -> resolve(true)
          link.onerror = (e) -> reject(false)
          document.head.appendChild(link)
      end))))
    end
  end
end

function loadjs!(w, url)
  # Uses Expr(:var, ...) instead of @var to work around issue #134
  @js w $(Expr(:new, :(Promise(function (resolve, reject)
    $(Expr(:var, :(script = document.createElement("script"))))
    script.src = $url
    script.onload = resolve
    script.onerror = (e) -> reject(
                               Dict("name"=>"JSLoadError",
                                    "message"=>"failed to load " + this.src)
                                    )
    document.head.appendChild(script)
  end))))
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
