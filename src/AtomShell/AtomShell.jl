module AtomShell

using Compat
using Compat.Sockets
using Compat.Sys: isapple, isunix, islinux, iswindows

abstract type Shell end

_shell = nothing

include("install.jl")
include("process.jl")
include("window.jl")

end
