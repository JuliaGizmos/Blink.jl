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
  var result = eval(data.code);
  if (data.callback) {
    result == undefined && (result = null);
    result = {
      type: 'callback',
      data: {
        callback: data.callback,
        result: result
      }
    }
    c.write(JSON.stringify(result));
  }
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
    if (handlers.hasOwnProperty(data.type)) {
      handlers[data.type](data, c);
    } else {
      throw "No such command: " + data.type;
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

function createWindow(opts, comUrl) {
  var win = new BrowserWindow(opts);
  windows[win.id] = win;
  if (opts.url) {
    win.loadURL(opts.url);

    windows[win.id].comUrl = comUrl;

    // load blink.js and webio.bundle.js
    win.webContents.on('did-finish-load', function() {
      win.webContents.executeJavaScript(`
        // is blink.js already loaded?
        if (typeof Blink != 'object') {
          var comUrl = '${comUrl ? comUrl : windows[win.id].comUrl}';
          var port = comUrl.split(":").pop().split("/")[0];
          var id = comUrl.split("/").pop()[0];
          var urlParams = new URLSearchParams(comUrl);
          var callback_id = urlParams.get('callback');

          document.ws = comUrl.replace("http", "ws");

          var script = document.createElement('script');
          script.defer = true;
          script.type = 'text/javascript';
          script.src = 'http://localhost:' + port + '/blink.js';
          document.head.appendChild(script);

          var script = document.createElement('script');
          script.type = 'text/javascript';
          script.src =  'http://localhost:' + port + '/webio.bundle.js';
          document.head.appendChild(script);
        }
      `);
    });
  }
  win.setMenu(null);

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
