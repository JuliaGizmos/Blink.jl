(function() {

  var ws = location.href.replace("http", "ws");
  var sock = new WebSocket(ws);

  function msg(t, m) {
    if (m == undefined) {
      m = t;
    } else {
      m.type = t;
    }
    sock.send(JSON.stringify(m));
  }

  var handlers = {};

  handlers.eval = function(data) {
    var result = eval(data.code);
    if (data.callback) {
      result == undefined && (result = null);
      result = {type: 'callback', callback: data.callback, result: result};
      sock.send(JSON.stringify(result));
    }
  }

  sock.onmessage = function (event) {
    var msg = JSON.parse(event.data);
    if (handlers.hasOwnProperty(msg.type)) {
      handlers[msg.type](msg);
    }
  };

  Blink = {
    sock: sock,
    msg: msg,
    handlers: handlers
  }
})();
