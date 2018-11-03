(function (Blink) {
    if (Blink.sock) {
        WebIO.sendCallback = function (msg) {
            Blink.msg("webio", msg);
        }
        WebIO.triggerConnected();
    } else {
        console.error("Blink not connected")
    }

    Blink.handlers.webio = function (msg) {
        WebIO.dispatch(msg.data);
    };
})(Blink);
