module Blink

using Lazy

include("process.jl")
include("jsexprs.jl")
include("jscall.jl")
include("window.jl")
include("utils.jl")

export docs
docs(a...) = Main.Graphics.docs(a...)

end # module

include("display/graphics.jl")
