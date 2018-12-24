__precompile__()

module Blink

using Reexport
using Distributed: Future
using Sockets
using Logging
using Base64: stringmime

include("rpc/rpc.jl")
include("content/content.jl")

include("AtomShell/AtomShell.jl")
export AtomShell
@reexport using .AtomShell
import .AtomShell: resolve_blink_asset

for r in ["blink.js", "blink.css", "reset.css", "spinner.css"]
  resource(resolve_blink_asset("res", r))
end

import WebIO: AbstractWidget
include("webio.jl")

end # module
