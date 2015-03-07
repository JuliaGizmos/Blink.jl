module BlinkDisplay

using Blink, Media, Lazy, Requires

include("display.jl")
include("objects.jl")
include("mimes.jl")

export docs

docpane(url = "http://docs.julialang.org/en/latest/") =
  Window(@d(:url => url,
            :alwaysOnTop => true,
            :width => 500,
            :height => 700))

docs() = docpane()

docs(search) = docpane("http://docs.julialang.org/en/latest/search/?q=$search")

end
