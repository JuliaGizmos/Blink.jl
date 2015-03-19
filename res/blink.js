(function() {

  Blink = {};

  // Comms stuff

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

  Blink.sock = sock;
  Blink.msg = msg;
  Blink.handlers = handlers;

  // HTML

  function callback(t, f) {
    if (f === undefined) {
      f = t;
      t = 0;
    }
    t *= 1000;
    setTimeout(f, t);
  }

  function fill(node, html) {
    node.classList.add('blink-show');
    callback(function () {
      node.classList.add('blink-fade');
      callback(0.2, function() {
        node.innerHTML = html;
        node.classList.remove('blink-fade');
      });
    });
  }

  Blink.fill = fill;

})();
