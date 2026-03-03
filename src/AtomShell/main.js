const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const net = require("net");
const path = require("path");

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
  app.on('window-all-closed', function(e) { /*  */ });
  ipcMain.handle("dialog:openFile", (evt, opts) => dialog.showOpenDialog(evt.sender.getOwnerBrowserWindow(), opts));
  ipcMain.handle("dialog:saveFile", (evt, opts) => dialog.showSaveDialog(evt.sender.getOwnerBrowserWindow(), opts));
});

// Window creation
var windows = {};

function createWindow(opts) {
  // Store the user defined preload script(s), if any, to pass to our preload script.
  let userPreloads = opts.webPreferences?.preload ?? [];
  // Merge in the required scripts as additionalArguments and overwrite preload.
  opts.webPreferences = { ...opts.webPreferences, ...{
    additionalArguments: [
      ...opts.webPreferences?.additionalArguments ?? [],
      ...(Array.isArray(userPreloads) ? userPreloads : [userPreloads]).map(f => `--blink-preloadjs=${f}`)
    ],
    preload: path.join(__dirname, 'preload.js')
  }};

  var win = new BrowserWindow(opts);
  windows[win.id] = win;
  if (opts.url) {
    win.loadURL(opts.url);
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
