using Blink
using Test

import Blink: jsonstring, jsonprint, jsonparse
import Blink.AtomShell: sendmsg, recvmsg
import Blink: JSON

@testset "JSON compatibility" begin
    @testset "serialization" begin
        # Symbol keys and values are written as strings, which is what the
        # `type`/`code`/`callback` protocol in `rpc.jl` relies on
        @test JSON.parse(jsonstring(Dict(:type => :eval, :code => "1 + 1"))) ==
            Dict("type" => "eval", "code" => "1 + 1")

        # Non-finite floats become `null` rather than aborting the message or
        # emitting literals the browser's `JSON.parse` would reject
        parsed = JSON.parse(jsonstring(Dict("a" => NaN, "b" => Inf, "c" => -Inf, "d" => 1.5)))
        @test parsed["a"] === nothing
        @test parsed["b"] === nothing
        @test parsed["c"] === nothing
        @test parsed["d"] == 1.5

        io = IOBuffer()
        jsonprint(io, Dict("a" => NaN))
        @test String(take!(io)) == jsonstring(Dict("a" => NaN))
    end

    @testset "parsing" begin
        # Parsed messages reach `handle` callbacks (Blink's, WebIO's and user
        # code), several of which are annotated `::Dict`, so objects must
        # materialize as `Dict{String, Any}` at every level of nesting
        m = jsonparse("""{"type":"webio","data":{"type":"request","arguments":[{"a":1}]}}""")
        @test m isa Dict{String, Any}
        @test m["data"] isa Dict{String, Any}
        @test m["data"]["arguments"][1] isa Dict{String, Any}

        # JSON `null` stays `nothing`, which `enable_callbacks!` relies on
        @test jsonparse("""{"result":null}""")["result"] === nothing
    end

    @testset "electron message framing" begin
        # Electron writes callbacks back-to-back, so the framing has to survive
        # several messages sitting in the buffer at once
        io = IOBuffer()
        sendmsg(io, Dict(:type => "callback", :data => Dict(:callback => 1, :result => "a")))
        sendmsg(io, Dict(:type => "callback", :data => Dict(:callback => 2, :result => "b")))
        seekstart(io)

        m1 = recvmsg(io)
        @test m1["type"] == "callback"
        @test m1["data"]["callback"] == 1
        @test m1["data"]["result"] == "a"

        m2 = recvmsg(io)
        @test m2["data"]["callback"] == 2
        @test m2["data"]["result"] == "b"

        # A closed or truncated stream yields no message rather than throwing:
        @test recvmsg(io) === nothing
    end
end
