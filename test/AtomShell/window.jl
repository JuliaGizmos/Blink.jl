using Blink
using Compat.Test

@testset "size Tests" begin
    w = Window(Blink.@d(:show => false, :width=>150, :height=>100)) ; sleep(5.0);
    @test size(w) == [150,100]

    size(w, 200,200)
    @test size(w) == [200,200]
end
