include("graphics/Graphics.jl")
using Graphics

module Blink

using Lazy

include("content/content.jl")
include("browser.jl")

include("process.jl")
include("jsexprs.jl")
include("jscall.jl")
include("window.jl")
include("utils.jl")

end # module

include("display/BlinkDisplay.jl")
using BlinkDisplay
