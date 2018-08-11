__precompile__()

module Blink

using Reexport
using Compat
using Compat.Distributed: Future
using Compat.Sys: isunix, islinux, isapple, iswindows
using Compat.Sockets

include("rpc/rpc.jl")
include("content/content.jl")

include("AtomShell/AtomShell.jl")
export AtomShell
@reexport using .AtomShell
import .AtomShell: resolve_blink_asset

end # module
