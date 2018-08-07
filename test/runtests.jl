using Blink
using Compat.Test
using Compat.Sockets


cleanup = !AtomShell.isinstalled()

cleanup && AtomShell.install()

# open window and wait for it to initialize
w = Window(Blink.@d(:show => false)); sleep(5.0)

# make sure the window is really active
@test @js(w, Math.log(10)) ≈ log(10)

@test string(Blink.jsstring(:(Dict("a" => 1, :b => 10)))...) == "{\"a\":1,\"b\":10}"

# check that <!DOCTYPE html> was declared
@test  startswith(Blink.maintp.tokens[1][2], "<!DOCTYPE html>\n")

include("content/api.jl");
include("AtomShell/window.jl");

cleanup && AtomShell.uninstall()
