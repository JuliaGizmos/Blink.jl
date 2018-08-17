using Blink
using Test
using Sockets


cleanup = !AtomShell.isinstalled()

cleanup && AtomShell.install()

# open window and wait for it to initialize
# TODO: can we remove the sleep(10) when the Window()
# constructor is made synchronous?
w = Window(Blink.@d(:show => false)); sleep(10.0)

# make sure the window is really active
@test @js(w, Math.log(10)) ≈ log(10)

@test string(Blink.jsstring(:(Dict("a" => 1, :b => 10)))...) == "{\"a\":1,\"b\":10}"

# check that <!DOCTYPE html> was declared
@test  startswith(Blink.maintp.tokens[1][2], "<!DOCTYPE html>\n")

include("content/api.jl");
include("AtomShell/window.jl");

cleanup && AtomShell.uninstall()
