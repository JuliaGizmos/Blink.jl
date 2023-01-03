module AtomShell

using ..Blink: resource
using Sockets
using WebIO

abstract type Shell end

include("process.jl")
include("window.jl")
include("webio.jl")

end
