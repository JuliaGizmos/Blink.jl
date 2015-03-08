export pin, top

type WebView
  ws
  pinned
end

pinned(view::WebView) =
  isa(view.pinned, Window) && active(view.pinned) ? view.pinned : nothing

function last(view::WebView)
  while !isempty(view.ws) && !active(view.ws[end]) pop!(view.ws) end
  isempty(view.ws) ? nothing : view.ws[end]
end

WebView() = WebView(c(), nothing)

const _display = WebView()
view() = _display

function init()
  setdisplay(Media.Graphical, view())
  return
end

displaysize(x) = (500, 400)
displaytitle(x) = "Julia"

function Media.render(view::WebView, x; options = @d())
  size = displaysize(x)
  html = tohtml(x)
  w = @or(pinned(view), Window(@d(:width => size[1], :height => size[2])))
  front(w)
  body(w, html)
  title(w, string(displaytitle(x), " (", id(w), ")",
                  isa(pinned(view), Window) ? pinstr : ""))
  push!(view.ws, w)
  return w
end

# Pin / unpin API

const pinstr = "*"

pintitle(w) = active(w) && title(w, string(title(w), pinstr))
unpintitle(w) = active(w) && title(w, replace(title(w), pinstr, ""))

pintitle(::Nothing) = nothing
unpintitle(::Nothing) = nothing

function pin(w::Window)
  if pinned(view()) == w
    pin(nothing)
  elseif active(w)
    pin(nothing)
    pintitle(w)
    view().pinned = w
    push!(view().ws, w)
  end
  return
end

# pin(id) = pin(Window(id, shell()))
pin() = pin(last(view()))

function pin(::Nothing)
  if pinned(view()) ≠ nothing
    unpintitle(pinned(view()))
    view().pinned = nothing
  end
end

# Float API

top(w::Window) = (floating(w, !floating(w)); nothing)

# top(id) = top(Window(id, shell()))

top(::Nothing) = nothing

top() = top(last(view()))
