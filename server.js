var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);

if (process.env.GATE && process.env.GATE === 'true') {
  if ((process.env.USERNAME && process.env.USERNAME !== '') && (process.env.PASSWORD && process.env.PASSWORD !== '')) {
    app.use(express.basicAuth(process.env.USERNAME, process.env.PASSWORD));
  }
}

if (process.env.RELOAD && process.env.RELOAD === 'true') {
  app.set('reload', true);
}

app.configure(function() {
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.set('view options', {layout: false});
  app.use(express.favicon(__dirname + '/public/favicon.ico'));
  app.use(express.logger('dev'));
  app.use(express.compress());
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.static(__dirname + '/public'));
  app.use(app.router);
  app.use(error);
});

function error(err, req, res, next) {
  console.error(err.stack);

  res.send(err.stack);
}

app.get('/*', function(req, res, next) {
  var data = {"reload":app.get('reload')};

  res.render('index', data);
});

var players = {};

io.sockets.on('connection', function (socket) {
  socket.on('newPlayer', function (playerName) {
    if (players[playerName]) {
      socket.emit('nameTaken');
    }
    else {
      players[playerName] = playerName;
      socket.playerName = playerName;
      socket.emit('start', {seed: Math.random() * 999999999});
    }
  });

  socket.on('disconnect', function() {
    delete players[socket.playerName];
  });
});

server.listen(app.get('port'));
console.log("Node.js server is taking the express line on port %d in %s mode.", app.get('port'), app.settings.env);
