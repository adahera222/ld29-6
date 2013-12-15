var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);

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

app.get('/referee', function(req, res, next) {
  var data = {"reload":app.get('reload')};

  res.render('referee', data);
});

app.get('/*', function(req, res, next) {
  var data = {"reload":app.get('reload')};

  res.render('index', data);
});

var game = {};
var gameTimer;
var players = {};
var referee = {};

io.sockets.on('connection', function(socket) {
  socket.on('newPlayer', function(playerName) {
    if (players[playerName]) {
      socket.emit('nameTaken');
    }
    else {
      players[playerName] = {name:playerName, socket:socket};
      socket.playerName = playerName;

      if (referee.socket) {
        referee.socket.emit('players', {players:parsePlayers()});
      }
    }
  });

  socket.on('newReferee', function(password) {
    if (password === process.env.REFEREE_PASSWORD) {
      if (referee.token) {
        socket.emit('usurped');
        referee = {};
      }

      socket.referee = true;
      referee.socket = socket;
      referee.token = Math.random() * 999999999;
      socket.emit('token', {token: referee.token});
      socket.emit('state', {time: timeLeft()});
    }
  });

  socket.on('getPlayers', function(token) {
    if (token === referee.token) {
      socket.emit('players', {players: parsePlayers()});
    }
  });

  socket.on('startGame', function(token) {
    if (token === referee.token) {
      startGame();
    }
  });

  socket.on('distance', function(distance) {
    players[socket.playerName].distance = distance;

    allIn = true;

    for (var player in players) {
      if (players[player].distance === null) {
        allIn = false;

        break;
      }
    }

    if (allIn) {
      makeScoreboard();
    }
  });

  socket.on('disconnect', function() {
    if (socket.referee) {
      referee = {};
    }
    else {
      delete players[socket.playerName];

      if (referee.socket) {
        referee.socket.emit('players', {players:parsePlayers()});
      }
    }
  });
});

function makeScoreboard() {
  var scoreboard = {};
  var playerDistances = [];

  for (var playerName in players) {
    var player = players[playerName];
    playerDistances.push({name:playerName, distance:player.distance});
  }

  scoreboard.players = playerDistances;

  sendScoreboard(scoreboard);
}

function sendScoreboard(scoreboard) {
  for (var playerName in players) {
    var player = players[playerName];
    player.socket.emit('scoreboard', scoreboard);
  }
}

function parsePlayers() {
  var parsedPlayers = {};

  for (var playerName in players) {
    var player = players[playerName];
    var parsedPlayer = {name: player.name};
    parsedPlayers[playerName] = parsedPlayer;
  }

  return parsedPlayers;
}

function startGame() {
  game = {}
  game.seed = Math.random() * 999999999;
  game.startTime = Math.floor((new Date).getTime()/1000);

  for (var playerName in players) {
    var player = players[playerName];
    player.distance = null;
    player.socket.emit('startGame', {seed: game.seed, length: process.env.GAME_LENGTH});
  }

  referee.socket.emit('state', {time: timeLeft()});

  gameTimer = setInterval(function() {
    if (!timeLeft()) {
      endGame();
    }
  }, 100);
}

function endGame() {
  clearInterval(gameTimer);
  for (var playerName in players) {
    var player = players[playerName];
    player.socket.emit('endGame');
  }
  referee.socket.emit('state', {time: timeLeft()});
}

function timeLeft() {
  if (game.startTime) {
    var timeLeft = (parseInt(game.startTime) + parseInt(process.env.GAME_LENGTH)) - Math.floor((new Date).getTime()/1000);

    if (timeLeft > 0) {
      return timeLeft;
    }
    else {
      return null;
    }
  }
  else {
    return null;
  }
}

server.listen(app.get('port'));
console.log("Node.js server is taking the express line on port %d in %s mode.", app.get('port'), app.settings.env);
