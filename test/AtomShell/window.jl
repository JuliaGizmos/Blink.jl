using Blink
using Base.Test

@testset "size Tests" begin
    w = Window(Blink.@d(:show => false, :width=>150, :height=>100)) ; sleep(5.0);
    @test size(w) == [150,100]

    size(w, 100,200)
    @test size(w) == [100,200]
end
