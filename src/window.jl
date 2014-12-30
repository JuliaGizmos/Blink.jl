import Base: position

export Window, flashframe, shell, id, progress, title,
  centre, floating, loadurl

type Window
  id::Int
  shell::AtomShell
end

shell(win::Window) = win.shell
id(win::Window) = win.id

function Window(a::AtomShell, opts::Associative = Dict())
  id = @js a createWindow($opts)
  return Window(id, a)
end

function dot_(w::Window, code; callback = false)
  js_(w.shell, :(withwin($(w.id), $(jsexpr(code).s))),
      callback = callback)
end

dot(args...; callback = true) =
  dot_(args..., callback = callback)

macro dot (win, code)
  :(dot($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

macro dot_ (win, code)
  :(dot_($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

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
