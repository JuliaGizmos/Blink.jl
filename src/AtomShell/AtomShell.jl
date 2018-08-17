module AtomShell

using Sockets

abstract type Shell end

_shell = nothing

include("install.jl")
include("process.jl")
include("window.jl")

end
