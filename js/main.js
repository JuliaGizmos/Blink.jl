var app = require("app");
var net = require("net");

console.log('Args:');
console.log(process.argv);

function arg(name) {
  for (var i = 0; i < process.argv.length; i++) {
    if (process.argv[i] == name) {
      return process.argv[i+1];
    }
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
    data = JSON.parse(s);
    if (data.command == "eval") {
      eval(data.code);
    } else {
      throw "No such command: " + data.command;
    }
  }
});

var port = parseInt(arg('port'));
server.listen(port, function() { //'listening' listener
  console.log('server bound: ' + port);
});

app.on("ready", function() {
});
