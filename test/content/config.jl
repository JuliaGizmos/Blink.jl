using Test

withenv("BLINK_PORT"=>4321) do
    p = readlines(`$(joinpath(Sys.BINDIR, "julia")) -E 'using Blink; println(Blink.port[])'`)
    @test p[1] == "4321"
end
