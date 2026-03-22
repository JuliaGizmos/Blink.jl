const {app, BrowserWindow} = require('electron')
var net = require("net");

function arg(name) {
  for (var i = 0; i < process.argv.length; i++) {
    if (process.argv[i] == name) {
      return process.argv[i+1];
    }
  }
}

var handlers = {};

handlers.eval = function(data, c) {
  Promise.resolve()
    .then(() => eval(data.code))
    .then((result) => {
      if (data.callback) {
        result == undefined && (result = null);
        c.write(JSON.stringify({
          type: 'callback',
          data: {
            callback: data.callback,
            result: result
          }
        }) + '\n');
      }
    })
    .catch((exc) => {
      console.error('[Blink] Eval error:', exc);
      if (data.callback) {
        c.write(JSON.stringify({
          type: 'callback',
          data: {
            callback: data.callback,
            result: {
              type: 'error',
              name: (exc && exc.name) ? exc.name : 'EvaluationError',
              message: (exc && exc.message) ? exc.message : String(exc)
            },
            error: true
          }
        }) + '\n');
      }
    });
}

var server = net.createServer(function(c) { //'connection' listener
  c.on('end', function() {
    app.quit();
  });

  var buffer = [''];
  c.on('data', function(data) {
    str = data.toString();
    lines = str.split('\n');
    buffer[0] += lines[0];
    for (var i = 1; i < lines.length; i++)
      buffer[buffer.length] = lines[i];

    while (buffer.length > 1)
      line(buffer.shift());
  });

  function line(s) {
    /*
     * HACK: Sometimes (notably, inside of a @testset in Julia), extra messages
     * which are not well-formed JSON are sent; for example, "GET /1 HTTP/1.1"
     * is sometimes sent. This is a fix of the symptom rather than addressing
     * the root cause; it probably **should** crash the electron process rather
     * than swallow the error.
     */
    try {
      var data = JSON.parse(s);
      // c.write('{}');
    } catch (exc) {
      console.error(`Unable to parse JSON message: ${exc}`);
      return;
    }
    try {
      if (handlers.hasOwnProperty(data.type)) {
        handlers[data.type](data, c);
      } else {
        console.error("No such command: " + data.type);
      }
    } catch (exc) {
      console.error(`Error handling command ${data.type}: ${exc}`);
      if (data.callback) {
        var result = {
          type: 'callback',
          data: {
            callback: data.callback,
            result: { type: 'error', name: 'EvaluationError', message: String(exc) },
            error: true
          }
        };
        c.write(JSON.stringify(result) + '\n');
      }
    }
  }
});

var port = parseInt(arg('port'));
server.listen(port);

app.on("ready", function() {
  app.on('window-all-closed', function(e) {
  });
});

// Window creation
var windows = {};

function _createWindow(opts) {
  var win = new BrowserWindow(opts);
  windows[win.id] = win;
  if (opts.url) {
    win.loadURL(opts.url);
  }
  win.setMenu(null);
  if (process.env.BLINK_DEBUG) {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  // Create a local variable that we'll use in
  // the closed event handler because the property
  // .id won't be accessible anymore when the window
  // has been closed.
  var win_id = win.id

  win.on('closed', function() {
    delete windows[win_id];
  });

  return win.id;
}

function createWindow(opts) {
  if (app.isReady()) {
    return _createWindow(opts);
  }
  return app.whenReady().then(function() {
    return _createWindow(opts);
  });
}

function evalwith(obj, code) {
  return (function() {
    return eval(code);
  }).call(obj);
}

function withwin(id, code) {
  if (windows[id]) {
    return evalwith(windows[id], code);
  }
}
