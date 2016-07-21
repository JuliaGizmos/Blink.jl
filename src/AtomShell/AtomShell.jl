module AtomShell

using Compat; import Compat.String

abstract Shell

_shell = nothing

include("install.jl")
include("process.jl")
include("window.jl")

end
