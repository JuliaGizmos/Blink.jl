using ..Blink
import Blink: js, id
import JSExpr: JSString, jsstring
import Base: position, size, close

export Window, flashframe, shell, progress, title,
  centre, floating, loadurl, opentools, closetools, tools,
  loadhtml, loadfile, css, front

mutable struct Window
  id::Int
  shell::Shell
  content
end

"""
    Window()
    Window(electron_options::Dict; async=true)

Create and open a new Window through Electron.

If `async==false`, this function blocks until the Window is fully initialized
and ready for you to communicate with it via javascript or the Blink API.

The `electron_options` dict is used to initialize the Electron window. See here
for the full set of Electron options:
https://electronjs.org/docs/api/browser-window#new-browserwindowoptions
"""
function Window end

shell(win::Window) = win.shell
id(win::Window) = win.id

const window_defaults = @d(:url => "about:blank",
                           :title => "Julia",
                           "node-integration" => false,
                           "use-content-size" => true,
                           :icon => resolve_blink_asset("deps", "julia.png"))

raw_window(a::Electron, opts) = @js a createWindow($(merge(window_defaults, opts)))

function Window(a::Shell, opts::AbstractDict = Dict(); async=true)
  # TODO: Custom urls don't support async b/c don't load Blink.js. (Same as https://github.com/JunoLab/Blink.jl/issues/150)
  return haskey(opts, :url) ?
    Window(raw_window(a, opts), a, nothing) :
    Window(a, Page(), opts, async=async)
end

function Window(a::Shell, content::Page, opts::AbstractDict = Dict(); async=true)
  url = Blink.localurl(content)
  if !async
      # Send the callback id as a query param in the url.
      id, cond = Blink.callback!()
      url *= "?callback=$id"
  end
  # Create the window.
  opts = merge(opts, Dict(:url => url))
  w = Window(raw_window(a, opts), a, content)
  # If callback is requested, wait until the window has finished loading.
  if !async
      val = wait(cond)
      if isa(val, AbstractDict) && get(val, "type", "") == "error"
          err = JSError(get(val, "name", "unknown"), get(val, "message", "blank"))
          throw(err)
      end
  end
  return w
end

Window(args...; kwargs...) = Window(shell(), args...; kwargs...)

dot(a::Electron, win::Integer, code; callback = true) =
  js(a, :(withwin($(win), $(jsstring(code)...))),
     callback = callback)

dot(w::Window, code; callback = true) =
  ifelse(callback, dot(shell(w), id(w), code, callback = callback), w)

dot_(args...) = dot(args..., callback = false)

macro dot(win, code)
  :(dot($(esc(win)), $(Expr(:quote, Expr(:., :this, QuoteNode(code))))))
end

macro dot_(win, code)
  :(dot_($(esc(win)), $(Expr(:quote, Expr(:., :this, QuoteNode(code))))))
end

# Window management APIs

active(s::Electron, win::Integer) =
  @js s windows.hasOwnProperty($win)

active(win::Window) = active(shell(win), id(win))

"""
    flashframe(win::Window, on=true)

Start or stop "flashing" the window to get the user's attention.

In Windows, flashes the window frame. In MacOS, bounces the app in the Dock.
https://github.com/electron/electron/blob/master/docs/api/browser-window.md#winflashframeflag
"""
flashframe(win::Window, on = true) =
  @dot_ win flashFrame($on)

"""
    progress(win::Window, p=-1)

Sets progress value in progress bar. Valid range is [0, 1.0]. Remove progress
bar when progress < 0; Change to indeterminate mode when progress > 1.

https://github.com/electron/electron/blob/master/docs/api/browser-window.md#winsetprogressbarprogress-options
"""
progress(win::Window, p = -1) =
  @dot_ win setProgressBar($p)

"""
    title(win::Window, title)

Set `win`'s title to `title.`
"""
title(win::Window, title) =
  @dot_ win setTitle($title)

"""
    title(win::Window)

Get the window's title.
"""
title(win::Window) =
  @dot win getTitle()

centre(win::Window) =
  @dot_ win center()

position(win::Window, x, y) =
  @dot_ win setPosition($x, $y)

position(win::Window) =
  @dot win getPosition()

size(win::Window, w::Integer, h::Integer) =
  invoke(size, Tuple{Window, Any, Any}, win, w, h)

size(win::Window, w, h) =
  @dot_ win setSize($w, $h)

size(win::Window) =
  @dot win getSize()

floating(win::Window, flag) =
  @dot_ win setAlwaysOnTop($flag)

floating(win::Window) =
  @dot win isAlwaysOnTop()

loadurl(win::Window, url) =
  @dot win loadURL($url)

loadfile(win::Window, f) =
  loadurl(win, "file://$f")

"""
    opentools(win::Window)

Open the Chrome Developer Tools on `win`.

See also: [`closetools`](@ref), [`tools`](@ref)
"""
opentools(win::Window) =
  @dot win openDevTools()

"""
    closetools(win::Window)

Close the Chrome Developer Tools on `win` if open.

See also: [`opentools`](@ref), [`tools`](@ref)
"""
closetools(win::Window) =
  @dot win closeDevTools()

"""
    tools(win::Window)

Toggle the Chrome Developer Tools on `win`.

See also: [`opentools`](@ref), [`closetools`](@ref)
"""
tools(win::Window) =
  @dot win toggleDevTools()

front(win::Window) =
  @dot win showInactive()

close(win::Window) =
  @dot win close()

# Window content APIs

active(::Nothing) = false

handlers(w::Window) = handlers(w.content)

msg(win::Window, m) = msg(win.content, m)

js(win::Window, s::JSString; callback = true) =
  active(win.content) ? js(win.content, s, callback = callback) :
    dot(win, :(this.webContents.executeJavaScript($(s.s))), callback = callback)

const initcss = """
  <style>html,body{margin:0;padding:0;border:0;text-align:center;}</style>
  """

function loadhtml(win::Window, html::AbstractString)
  tmp = string(tempname(), ".html")
  open(tmp, "w") do io
    println(io, initcss)
    println(io, html)
  end
  loadfile(win, tmp)
  @async (sleep(1); rm(tmp))
  return
end
