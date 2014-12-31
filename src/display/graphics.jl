module Graphics

using Blink, Lazy

_shell = nothing

function shell()
  global _shell
  _shell ≠ nothing && active(_shell) && return _shell
  _shell = Blink.init()
end

docpane(url = "http://docs.julialang.org/en/latest/") =
  Window(shell(), @d(:url => url,
                     :alwaysOnTop => true,
                     :width => 500,
                     :height => 700))

docs() = docpane()

docs(search) = docpane("http://docs.julialang.org/en/latest/search/?q=$search")

end
