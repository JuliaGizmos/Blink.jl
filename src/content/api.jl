export body!, content!, loadcss!, loadjs!, load!

content!(o, sel, html::String; fade = true) =
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

function loadjs!(w, url)
  id, cb = callback!()
  @js_ w begin
    @var script = document.createElement("script")
    script.src = $url
    script.onload = e -> Blink.cb($id)
    document.head.appendChild(script)
  end
  return wait(cb, 5, msg = "JS load timed out")
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
  else
    error("Blink: Unsupported file type")
  end
end
