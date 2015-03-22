(function() {

  Blink = {};

  // Comms stuff

  var ws = location.href.replace("http", "ws");
  var sock = new WebSocket(ws);

  function msg(t, m) {
    if (m === undefined) {
      m = t;
    } else {
      m.type = t;
    }
    sock.send(JSON.stringify(m));
  }

  var handlers = {};

  sock.onmessage = function (event) {
    var msg = JSON.parse(event.data);
    if (handlers.hasOwnProperty(msg.type)) {
      handlers[msg.type](msg);
    }
  };

  handlers.eval = function(data) {
    var result = eval(data.code);
    if (data.callback) {
      result == undefined && (result = null);
      msg('callback', {callback: data.callback, result: result});
    }
  }

  Blink.sock = sock;
  Blink.msg = msg;
  Blink.handlers = handlers;

  // JS eval

  function innertext(dom) {
    var children = dom.childNodes;
    if (children.length > 0) {
      return children[0].wholeText;
    } else {
      return "";
    }
  }

  function evalscripts(dom) {
    var scripts = dom.querySelectorAll("script");
    Array.prototype.forEach.call(scripts, function(s) {
      window.eval(innertext(s));
    });
  }

  Blink.evalscripts = evalscripts;

  // HTML utils

  function callback(t, f) {
    if (f === undefined) {
      f = t;
      t = 0;
    }
    t *= 1000;
    setTimeout(f, t);
  }

  function select(node) {
    if (typeof node === "string") {
      return document.querySelector(node);
    } else {
      return node;
    }
  }

  function fill(node, html) {
    node = select(node);
    node.classList.add('blink-show');
    callback(function () {
      node.classList.add('blink-fade');
      callback(0.2, function() {
        node.innerHTML = html;
        evalscripts(node);
        node.classList.remove('blink-fade');
      });
    });
  }

  Blink.fill = fill;

})();
