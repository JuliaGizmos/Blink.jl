module Blink

using Lazy

include("procs.jl")
include("jsexprs.jl")
include("jscall.jl")
include("window.jl")
include("utils.jl")

export docs
docs() = Main.Graphics.docs()

end # module

include("display/docs.jl")
