(function() {

  Blink = {};

  // Comms stuff

  var ws = location.href.replace("http", "ws");
  if (!/\/\d+$/.test(ws)) {
    ws += '/' + id;
  }
  var sock = new WebSocket(ws);

  function msg(t, m) {
    var msg = (m === undefined) ?
      { type: t.type, data: t } :
      { type: t, data: m }
    sock.send(JSON.stringify(msg))
  }

  var handlers = {};

  sock.onmessage = function(event) {
    var msg = JSON.parse(event.data);
    if (handlers.hasOwnProperty(msg.type)) {
      handlers[msg.type](msg);
    }
  };

  function cb(id, data) {
    data === undefined && (data = null);
    Promise.resolve(data).then(data => {
      var err = data != null ? data.type == 'error' : false;
      msg('callback', {callback: id, result: data, error: err});
    });
  }

  handlers.eval = function(data) {
    new Promise(resolve => resolve(eval(data.code)))
      .catch(e => {
        return ({type: 'error', name: e.name, message: e.message})
      })
      .then(result => {
        if (data.callback) {
          cb(data.callback, result);
        }
      });
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

  function fill(node, html, fade) {
    node = select(node);
    fade ?
      fillfade(node, html) :
      fillnofade(node, html)
  }
  function fillfade(node, html) {
    node = select(node);
    node.classList.add('blink-show');
    callback(function () {
      node.classList.add('blink-fade');
      callback(0.2, function() {
        fillnofade(node, html);
        node.classList.remove('blink-fade');
      });
    });
  }
  function fillnofade(node, html) {
    node.innerHTML = html;
    evalscripts(node);
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
