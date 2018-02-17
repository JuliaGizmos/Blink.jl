using Blink
using Base.Test

@testset "size Tests" begin
    w = Window(Blink.@d(:show => false, :width=>800, :height=>400)) ; sleep(5.0);
    @test size(w) == [800,400]

    size(w, 100,200)
    @test size(w) == [100,200]
end
