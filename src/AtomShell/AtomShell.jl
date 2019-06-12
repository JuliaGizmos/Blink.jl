module AtomShell

using Sockets
using WebIO

abstract type Shell end

_shell = nothing

include("install.jl")
include("process.jl")
include("window.jl")
include("webio.jl")

end
