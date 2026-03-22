(function() {

  Blink = {};

  // Comms stuff

  var href = (typeof window !== 'undefined' && window.location && window.location.href) ?
    window.location.href :
    null;
  var ws = null;
  if (href && /^https?:\/\//.test(href)) {
    ws = href.replace(/^http/, "ws");
    // Remove query string for the regex check
    var wsBase = ws.split('?')[0];
    ws = wsBase;
    if (!/\/\d+$/.test(wsBase) && typeof id !== 'undefined') {
      ws = wsBase + '/' + id;
    }
  } else {
    console.error("[Blink] Unable to establish WebSocket: no http(s) location available", href);
  }

  function msg(t, m) {
    var msg = (m === undefined) ?
      { type: t.type, data: t } :
      { type: t, data: m }
    Blink.sock.send(JSON.stringify(msg))
  }


  function connect() {
    if (!ws) {
      return;
    }
    Blink.sock = new WebSocket(ws);
    Blink.sock.onopen = function() {
      if (typeof callback_id !== 'undefined' && !Blink._initCallbackSent) {
        Blink._initCallbackSent = true;
        cb(callback_id, true);
      }
    };
    Blink.sock.onmessage = onmessage;
    Blink.sock.onclose = function() {
      if (Blink.sock.readyState == 3) {
        setTimeout(connect, 500);
      }
    }
  }

  function onmessage(event) {
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


  var handlers = {};
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

  Blink.msg = msg;
  Blink.cb = cb;
  Blink.handlers = handlers;
  Blink._initCallbackSent = false;
  connect();

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

  function fill(node, html, fade, resolve, reject) {
    node = select(node);
    fade ?
      fillfade(node, html, resolve, reject) :
      fillnofade(node, html, resolve, reject)
  }
  function fillfade(node, html, resolve, reject) {
    node = select(node);
    node.classList.add('blink-show');
    callback(function () {
      node.classList.add('blink-fade');
      callback(0.2, function() {
        fillnofade(node, html, null, null);
        node.classList.remove('blink-fade');
        if (resolve) resolve(true);
      });
    });
  }
  function fillnofade(node, html, resolve, reject) {
    node.innerHTML = html;
    evalscripts(node);
    if (resolve) resolve(true);
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

  // Window creation callback is sent from connect()->onopen (once).
})();
