__precompile__()

module Blink

using Reexport
using Distributed: Future
using Sockets
using Logging
using Base64: stringmime
using WebIO

include("lazy/lazy.jl")
include("rpc/rpc.jl")
include("content/content.jl")

include("AtomShell/AtomShell.jl")
export AtomShell
@reexport using .AtomShell
import .AtomShell: resolve_blink_asset

end # module
