module AtomShell

abstract Shell

_shell = nothing

include("install.jl")
include("process.jl")
include("window.jl")

end
