
struct WebIOBlinkComm <: WebIO.AbstractConnection
    window::Window
end

function initwebio!(w::Window)
    if isdefined(WebIO, :BlinkConnection)
        # Older versions of WebIO have their own setup logic for Blink.
        # Let's avoid conflicts.
        Base.depwarn(
            "Please upgrade WebIO for a smoother integration with Blink.",
            :blink_webio_upgrade
        )
        return
    end

    @js w begin
        window._webIOBundlePath = $(WebIO.bundlepath)
        require($(normpath(joinpath(@__DIR__, "webio.js"))))
    end

    comm = WebIOBlinkComm(w)
    handle(w, "webio") do msg
        WebIO.dispatch(comm, msg)
    end
end

function Sockets.send(comm::WebIOBlinkComm, data)
    msg(comm.window, Dict(:type=>"webio", :data=>data))
end

Base.isopen(comm::WebIOBlinkComm) = active(comm.window.content)
