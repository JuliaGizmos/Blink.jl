using Test
using Blink
using WebIO

"""
Execute function f() with a timeout of `timeout` seconds. Returns the
result of f() or `nothing` in the case of a timeout.
"""
function with_timeout(f::Function, timeout)
    c = Channel{Any}(1)
    @async begin
        put!(c, f())
    end
    @async begin
        sleep(timeout)
        put!(c, nothing)
    end
    take!(c)
end

@testset "WebIO integration" begin
    @testset "mount test" begin
        w = Window(Dict(:show => false))
        mounted = Channel(false)
        setmounted = () -> push!(mounted, true)
        scope = Scope()
        onmount(scope, js"""
            function () {
                $setmounted()
            }
        """)
        body!(w, scope)
        did_mount = with_timeout(() -> take!(mounted), 5)
        @test did_mount
    end

    @testset "button click" begin
        scope = Scope()
        obs = Observable(scope, "obs", false)
        obschannel = Channel(1)
        on((x) -> push!(obschannel, x), obs)
        scope(dom"button#mybutton"(
            events=Dict(
                "click" => @js function()
                    $obs[] = true
                end
            )
        ))
        w = Window(Dict(:show => false); body=scope)

        # Sleep to allow WebIO scope to mount in Electron
        sleep(0.25)

        @js w document.querySelector("#mybutton").click()
        did_click = with_timeout(() -> take!(obschannel), 5)
        @test did_click
    end
end
