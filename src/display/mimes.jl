function tohtml(io::IO, m::MIME"text/html", x)
  writemime(io, m, x)
end

function tohtml(io::IO, m::MIME"text/plain", x)
  writemime(io, m, x)
end

function tohtml(io::IO, m::MIME"image/png", img)
  print(io, """<img src="data:image/png;base64,""")
  print(io, stringmime(m, img))
  print(io, "\" />")
end

function tohtml(io::IO, m::MIME"image/svg+xml", img)
  writemime(io, m, img)
end

function bestmime(val)
  for mime in ("text/html", "image/svg+xml", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

tohtml(io::IO, x) = tohtml(io, bestmime(x), x)

tohtml(x) = sprint(tohtml, x)
