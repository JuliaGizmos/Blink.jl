export pin, top

type WebView
  last
  pinned
end

pinned(view::WebView) =
  isa(view.pinned, Window) && active(view.pinned) ? view.pinned : nothing

WebView() = WebView(nothing, nothing)

const _display = WebView()
view() = _display

function init()
  setdisplay(Media.Graphical, view())
end

displaysize(x) = (500, 400)
displaytitle(x) = "Julia"

function Media.render(view::WebView, x; options = @d())
  size = displaysize(x)
  html = tohtml(x)
  w = isa(pinned(view), Window) ? view.pinned :
        Window(@d(:width => size[1], :height => size[2]))
  loadhtml(w, html)
  title(w, string(displaytitle(x), " (", id(w), ")",
                  isa(pinned(view), Window) ? pinstr : ""))
  view.last = w
  front(w)
  return w
end

# Pin / unpin API

const pinstr = "*"

pintitle(w) = active(w) && title(w, string(title(w), pinstr))
unpintitle(w) = active(w) && title(w, replace(title(w), pinstr, ""))

pintitle(::Nothing) = nothing
unpintitle(::Nothing) = nothing

function pin(w::Window)
  if view().pinned == w
    pin(nothing)
  else
    pin(nothing)
    view().pinned = pintitle(w)
  end
  return
end

pin(id) = pin(Window(id, shell()))
pin() = pin(view().last)

function pin(::Nothing)
  if view().pinned ≠ nothing
    unpintitle(view().pinned)
    view().pinned = nothing
  end
end

# Float API

top(w::Window) = (floating(w, !floating(w)); nothing)

top(id) = top(Window(id, shell()))

top(::Nothing) = nothing

top() = top(view().last)
