export body!, content!, loadcss!, loadjs!

content!(o, sel, html::String) =
  @js_ o Blink.fill($sel, $html)

content!(o, sel, html) =
  content!(o, sel, stringmime(MIME"text/html"(), html))

body!(w, html) = content!(w, "body", html)

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
  return wait(cb)
end
