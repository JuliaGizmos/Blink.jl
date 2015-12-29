var app = require("app");
var net = require("net");

// console.log('Args:');
// console.log(process.argv);

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
    result = {type: 'callback', callback: data.callback, result: result};
    c.write(JSON.stringify(result));
  }
}

var connection = {};

var server = net.createServer(function(c) { //'connection' listener
  connection = c;
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
    data = JSON.parse(s);
    if (handlers.hasOwnProperty(data.type)) {
      handlers[data.type](data, c);
    } else {
      throw "No such command: " + data.type;
    }
  }
});

var port = parseInt(arg('port'));
server.listen(port, function() { //'listening' listener
  console.log('Electron server listening on port ' + port);
});

app.on("ready", function() {
  app.on('window-all-closed', function(e) {
  });
});

// Window creation
var Window = require("browser-window");
var windows = {};

function createWindow(opts) {
  var win = new Window(opts);
  windows[win.id] = win;
  if (opts.url) {
    win.loadURL(opts.url);
  }

  win.webContents.on('dom-ready', function(opts) {
    var browserOpts = opts.sender.browserWindowOptions;
    if (browserOpts.hasOwnProperty("callback")) {
      var callback = browserOpts.callback;
      result = {type: 'callback', callback: callback, result: callback};
      connection.write(JSON.stringify(result));
    }
  });

  win.on('closed', function() {
    delete windows[win.id];
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
