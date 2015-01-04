module BlinkDisplay

using Blink, Graphics, Lazy, Requires

_shell = nothing

function shell(; debug = false)
  global _shell
  _shell ≠ nothing && active(_shell) && return _shell
  _shell = Blink.init(debug = debug)
end

window(opts = @d()) = Window(shell(), opts)

include("display.jl")
include("objects.jl")

export docs

docpane(url = "http://docs.julialang.org/en/latest/") =
  window(@d(:url => url,
            :alwaysOnTop => true,
            :width => 500,
            :height => 700))

docs() = docpane()

docs(search) = docpane("http://docs.julialang.org/en/latest/search/?q=$search")

end
