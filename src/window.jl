import Base: position

export Window, flashframe, shell, id, progress, title,
  centre, floating, loadurl, opentools, closetools, tools,
  body, loadhtml, loadfile

type Window
  id::Int
  shell::AtomShell
end

shell(win::Window) = win.shell
id(win::Window) = win.id

const window_defaults = @d(:url => "about:blank",
                           "node-integration" => false)

function Window(a::AtomShell, opts::Associative = Dict())
  id = @js a createWindow($(merge(window_defaults, opts)))
  return Window(id, a)
end

function dot(w::Window, code; callback = true)
  js(w.shell, :(withwin($(w.id), $(jsstring(code)))),
     callback = callback)
end

dot_(args...) = dot_(args..., callback = false)

macro dot (win, code)
  :(dot($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

macro dot_ (win, code)
  :(dot_($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

js(win::Window, js; callback = true) =
  dot(win, :(this.webContents.executeJavaScript($(jsstring(js)))), callback = callback)

# Window management APIs

active(win::Window) =
  @js win.shell windows.hasOwnProperty($(win.id))

flashframe(win::Window, on = true) =
  @dot_ win flashFrame($on)

progress(win::Window, p = -1) =
  @dot_ win setProgressBar($p)

title(win::Window, title) =
  @dot_ win setTitle($title)

title(win::Window) =
  @dot win getTitle()

centre(win::Window) =
  @dot_ win center()

position(win::Window, x, y) =
  @dot_ win setPosition($x, $y)

position(win::Window) =
  @dot win getPosition()

floating(win::Window, flag) =
  @dot_ win setAlwaysOnTop($flag)

floating(win::Window) =
  @dot win isAlwaysOnTop()

loadurl(win::Window, url) =
  @dot win loadUrl($url)

loadfile(win::Window, f) =
  loadurl(win, "file://$f")

opentools(win::Window) =
  @dot win openDevTools()

closetools(win::Window) =
  @dot win closeDevTools()

tools(win::Window) =
  @dot win toggleDevTools()

# Window content APIs

body(win::Window, html::String) =
  @js win document.body.innerHTML = $html

function loadhtml(win::Window, html)
  tmp = string(tempname(), ".html")
  open(tmp, "w") do io
    writemime(io, MIME"text/html"(), html)
  end
  loadfile(win, tmp)
  @schedule (sleep(1); rm(tmp))
  return
end
