var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);
var _ = require('underscore');

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
var countdownTimer;
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
      socket.emit('state', {time: timeLeft((parseInt(game.startTime) + parseInt(process.env.GAME_LENGTH)))});
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
      if (!(typeof players[player].distance !== "undefined" && players[player].distance !== null)) {
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

  scoreboard.players = _.sortBy(playerDistances, 'distance').reverse();

  _.each(scoreboard.players, function(element, index) {
    element['rank'] = index + 1;
  });

  sendScoreboard(scoreboard);
}

function sendScoreboard(scoreboard) {
  for (var playerName in players) {
    var player = players[playerName];
    scoreboard.me = _.find(scoreboard.players, function(p) {
      return p['name'].toString() === playerName.toString();
    });
    player.socket.emit('scoreboard', scoreboard);
  }

  countdown();
}

function countdown() {
  for (var playerName in players) {
    var player = players[playerName];
    player.socket.emit('countdown', {time: process.env.REST_LENGTH});
  }

  var countdownStartTime = Math.floor((new Date).getTime()/1000);

  countdownTimer = setInterval(function() {
    if (!timeLeft((parseInt(countdownStartTime) + parseInt(process.env.REST_LENGTH)))) {
      startGame();
    }
  }, 100);
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
  if (countdownTimer) {
    clearInterval(countdownTimer);
  }

  game = {}
  game.seed = Math.random() * 999999999;
  game.startTime = Math.floor((new Date).getTime()/1000);

  for (var playerName in players) {
    var player = players[playerName];
    player.distance = null;
    player.socket.emit('startGame', {seed: game.seed, length: process.env.GAME_LENGTH});
  }

  if (referee.socket) {
    referee.socket.emit('state', {time: timeLeft((parseInt(game.startTime) + parseInt(process.env.GAME_LENGTH)))});
  }

  gameTimer = setInterval(function() {
    if (!timeLeft((parseInt(game.startTime) + parseInt(process.env.GAME_LENGTH)))) {
      endGame();
    }
  }, 100);
}

function endGame() {
  if (gameTimer) {
    clearInterval(gameTimer);
  }

  for (var playerName in players) {
    var player = players[playerName];
    player.socket.emit('endGame');
  }

  if (referee.socket) {
    referee.socket.emit('state', {time: timeLeft((parseInt(game.startTime) + parseInt(process.env.GAME_LENGTH)))});
  }
}

function timeLeft(target) {
  if (game.startTime) {
    var timeLeft = target - Math.floor((new Date).getTime()/1000);

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
