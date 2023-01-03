
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
        WebIO = window.WebIO = @new webio.default();
        WebIO.setSendCallback(function (message)
            window.Blink.msg("webio", message)
        end)
        Blink.handlers.webio = function (message)
            window.WebIO.dispatch(message.data)
        end
    end

    comm = WebIOBlinkComm(w)
    handle(w, "webio") do msg
        WebIO.dispatch(comm, msg)
    end
end

@init begin
    resource(WebIO.bundlepath)
end

function Sockets.send(comm::WebIOBlinkComm, data)
    msg(comm.window, Dict(:type=>"webio", :data=>data))
end

Base.isopen(comm::WebIOBlinkComm) = active(comm.window.content)
