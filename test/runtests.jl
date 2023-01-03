using Blink
using Test
using Sockets

# IMPORTANT: Window(...) cannot appear inside of a @testset for as-of-yet
# unknown reasons.

# open window and wait for it to initialize
w = Window(Blink.Dict(:show => false), async=false);
@testset "basic functionality" begin
    # make sure the window is really active
    @test @js(w, Math.log(10)) ≈ log(10)

    @test string(Blink.jsstring(:(Dict("a" => 1, :b => 10)))...) == "{\"a\":1,\"b\":10}"

    # check that <!DOCTYPE html> was declared
    @test startswith(Blink.maintp.tokens[1].value, "<!DOCTYPE html>")
end

include("content/api.jl");
include("AtomShell/window.jl");
include("./webio.jl")
