(function() {

  Blink = {};

  // Comms stuff

  var ws = "ws://127.0.0.1:"+port;
  if (!/\/\d+$/.test(ws)) {
    ws += '/' + id;
  }
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

  function cb(id, data) {
    data === undefined && (data = null);
    if (data && data.constructor == Promise) {
      data.then(data => cb(id, data));
    } else {
      msg('callback', {callback: id, result: data});
    }
  }

  handlers.eval = function(data) {
    var result = eval(data.code);
    if (data.callback) {
      result == undefined && (result = null);
      cb(data.callback, result);
    }
  }

  Blink.sock = sock;
  Blink.msg = msg;
  Blink.cb = cb;
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

  function evalwith(obj, code) {
    return (function() {
      return eval(code);
    }).call(obj);
  }

  function evalscripts(dom) {
    var scripts = dom.querySelectorAll("script");
    Array.prototype.forEach.call(scripts, function(s) {
      window.eval(innertext(s));
    });
  }

  Blink.evalwith = evalwith;
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

  // JS Utils

  function hypot(x, y) {
    return Math.sqrt(x*x + y*y);
  }

  function click(node, f) {
    var startX = 0;
    var startY = 0;
    node.onmousedown = function(e) {
      if (e.which == 1) {
        startX = e.clientX;
        startY = e.clientY;
      }
    };
    node.onmouseup = function(e) {
      if (e.which == 1 && hypot(e.clientX - startX, e.clientY - startY) < 5) {
        f(e);
      }
    };
  }

  Blink.click = click;

})();
