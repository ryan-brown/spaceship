// Generated by CoffeeScript 1.3.3
(function() {
  var asteroids, background, blank, buffer, canvas, clients, ctx, draw, drawAllAsteroids, drawAllPlayers, drawOnlyPlayer, drawPlayer, isPlayer, mainContext, myBg, myId, myKeys, socket, update, updateClients;

  socket = io.connect();

  canvas = null;

  buffer = null;

  ctx = null;

  mainContext = null;

  myId = 0;

  myBg = new Image();

  myBg.src = 'http://www.californiaindianeducation.org/science_lab/pics/space_photos/Space_Deep.jpg';

  myKeys = [false, false, false, false, false];

  clients = [];

  asteroids = [];

  window.init = function() {
    canvas = document.getElementById('myCanvas');
    buffer = document.getElementById('myBuffer');
    canvas.focus();
    buffer.width = myBg.width;
    buffer.height = myBg.height;
    ctx = buffer.getContext("2d");
    setInterval(update, 30);
    mainContext = canvas.getContext("2d");
    canvas.onblur = function() {
      return socket.emit('clientStoppedFocus', true);
    };
    canvas.onkeydown = function(evt) {
      var i, _i, _results;
      _results = [];
      for (i = _i = 0; _i <= 3; i = ++_i) {
        if (evt.which === 37 + i && myKeys[i] === false) {
          myKeys[i] = true;
          socket.emit('buttonPressedStart', i);
        }
        if (evt.which === 32 && myKeys[4] === false) {
          myKeys[4] = true;
          _results.push(socket.emit('buttonPressedStart', 32));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    return canvas.onkeyup = function(evt) {
      var i, _i, _results;
      _results = [];
      for (i = _i = 0; _i <= 3; i = ++_i) {
        if (evt.which === 37 + i) {
          myKeys[i] = false;
          _results.push(socket.emit('buttonPressedStop', i));
        } else if (evt.which === 32) {
          myKeys[4] = false;
          _results.push(socket.emit('buttonPressedStop', 32));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
  };

  update = function() {
    ctx.save();
    blank();
    background();
    draw();
    return ctx.restore();
  };

  blank = function() {
    ctx.fillStyle = "#000";
    return ctx.fillRect(0, 0, canvas.width, canvas.height);
  };

  background = function() {
    return ctx.drawImage(myBg, 0, 0);
  };

  draw = function() {
    var drawBottom, drawLeft, drawRight, drawTop;
    drawAllPlayers(ctx);
    drawAllAsteroids(ctx);
    mainContext.save();
    mainContext.translate(canvas.width / 2 - clients[0].x, canvas.height / 2 - clients[0].y);
    mainContext.drawImage(buffer, 0, 0);
    drawBottom = clients[0].y >= buffer.height - canvas.height / 2;
    drawTop = clients[0].y <= canvas.height / 2;
    drawRight = clients[0].x >= buffer.width - canvas.width / 2;
    drawLeft = clients[0].x <= canvas.width / 2;
    if (drawBottom) {
      mainContext.drawImage(buffer, 0, 0, buffer.width, canvas.height / 2, 0, buffer.height, buffer.width, canvas.height / 2);
    } else if (drawTop) {
      mainContext.drawImage(buffer, 0, buffer.height - canvas.height / 2, buffer.width, canvas.height / 2, 0, -canvas.height / 2, buffer.width, canvas.height / 2);
    }
    if (drawRight) {
      mainContext.drawImage(buffer, 0, 0, canvas.width / 2, buffer.height, buffer.width, 0, canvas.width / 2, buffer.height);
    } else if (drawLeft) {
      mainContext.drawImage(buffer, buffer.width - canvas.width / 2, 0, canvas.width / 2, buffer.height, -canvas.width / 2, 0, canvas.width / 2, buffer.height);
    }
    if (drawBottom && drawRight) {
      mainContext.drawImage(buffer, 0, 0, canvas.width / 2, canvas.height / 2, buffer.width, buffer.height, canvas.width / 2, canvas.height / 2);
    } else if (drawTop && drawLeft) {
      mainContext.drawImage(buffer, buffer.width - canvas.width / 2, buffer.height - canvas.height / 2, canvas.width / 2, canvas.height / 2, -canvas.width / 2, -canvas.height / 2, canvas.width / 2, canvas.height / 2);
    } else if (drawTop && drawRight) {
      mainContext.drawImage(buffer, 0, buffer.height - canvas.height / 2, canvas.width / 2, canvas.height / 2, buffer.width, -canvas.height / 2, canvas.width / 2, canvas.height / 2);
    } else if (drawBottom && drawLeft) {
      mainContext.drawImage(buffer, buffer.width - canvas.width / 2, 0, canvas.width / 2, canvas.height / 2, -canvas.width / 2, buffer.height, canvas.width / 2, canvas.height / 2);
    }
    mainContext.restore();
    return drawOnlyPlayer(mainContext);
  };

  drawAllPlayers = function(context) {
    var bullet, clientObj, _i, _len, _ref, _results;
    _ref = clients.slice(0).reverse();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      clientObj = _ref[_i];
      context.save();
      context.translate(clientObj.x, clientObj.y);
      context.rotate(clientObj.rotation);
      context.translate(-clientObj.x, -clientObj.y);
      drawPlayer(clientObj, context);
      context.restore();
      _results.push((function() {
        var _j, _len1, _ref1, _results1;
        _ref1 = clientObj.myBullets;
        _results1 = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          bullet = _ref1[_j];
          context.fillStyle = "#fff";
          _results1.push(context.fillRect(bullet.x, bullet.y, 3, 3));
        }
        return _results1;
      })());
    }
    return _results;
  };

  drawOnlyPlayer = function(context) {
    var bullet, _i, _len, _ref;
    context.save();
    context.translate(canvas.width / 2, canvas.height / 2);
    context.rotate(clients[0].rotation);
    context.translate(-clients[0].x, -clients[0].y);
    drawPlayer(clients[0], context);
    context.restore();
    context.save();
    context.translate(canvas.width / 2, canvas.height / 2);
    context.translate(-clients[0].x, -clients[0].y);
    _ref = clients[0].myBullets;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      bullet = _ref[_i];
      context.fillStyle = "#fff";
      context.fillRect(bullet.x, bullet.y, 3, 3);
    }
    return context.restore();
  };

  drawPlayer = function(playerObj, context) {
    context.save();
    context.strokeStyle = '#fff';
    context.lineWidth = 1;
    context.beginPath();
    context.moveTo(playerObj.x - (playerObj.height / 2), playerObj.y - (playerObj.width / 2));
    context.lineTo(playerObj.x - (playerObj.height / 2), playerObj.y + (playerObj.width / 2));
    context.lineTo(playerObj.x + (playerObj.height / 2), playerObj.y);
    context.closePath();
    context.stroke();
    context.fillStyle = "#00dd00";
    context.fillRect(playerObj.x - (playerObj.height / 2) - 10, playerObj.y - (playerObj.width / 2), 3, (playerObj.health / 100) * playerObj.width);
    context.fillStyle = "#fff";
    context.font = "12px Arial";
    context.textAlign = "center";
    context.translate(playerObj.x - (playerObj.height / 2) - 22, playerObj.y);
    context.rotate(Math.PI / 2);
    context.fillText("" + playerObj.points, 0, 0);
    return context.restore();
  };

  drawAllAsteroids = function(context) {
    var asteroidObj, _i, _len;
    context.save();
    for (_i = 0, _len = asteroids.length; _i < _len; _i++) {
      asteroidObj = asteroids[_i];
      context.beginPath();
      context.strokeStyle = "#fff";
      context.arc(asteroidObj.x, asteroidObj.y, asteroidObj.bbRadius, 0, 2 * Math.PI, false);
      context.stroke();
      context.closePath();
    }
    return context.restore();
  };

  isPlayer = function(clientObj) {
    return clientObj.id === myId;
  };

  updateClients = function(clientObj) {
    var i, _i, _ref, _results;
    _results = [];
    for (i = _i = 0, _ref = clients.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if ((clients[i] != null) && clients[i].id === clientObj.id) {
        _results.push(clients[i] = clientObj);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  socket.on('clientMoved', function(clientObj) {
    return updateClients(clientObj);
  });

  socket.on('bulletsUpdated', function(clientObj) {
    return updateClients(clientObj);
  });

  socket.on('bulletHurt', function(clientObj) {
    return updateClients(clientObj);
  });

  socket.on('bulletHit', function(clientObj) {
    updateClients(clientObj);
    if (clientObj.id === myId) {
      return document.getElementById('myKills').innerHTML = "Kills: " + clientObj.kills;
    }
  });

  socket.on('clientDied', function(clientObj) {
    updateClients(clientObj);
    if (clientObj.id === myId) {
      return document.getElementById('myDeaths').innerHTML = "Deaths: " + clientObj.deaths;
    }
  });

  socket.on('clientQuit', function(clientObj) {
    var i, _i, _ref, _results;
    _results = [];
    for (i = _i = 0, _ref = clients.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if (clients[i] == null) {
        break;
      }
      if (clients[i].id === clientObj.id) {
        _results.push(clients.splice(i, 1));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  });

  socket.on('clientJoined', function(clientObj) {
    return clients.push(clientObj);
  });

  socket.on('asteroidUpdate', function(asteroidList) {
    return asteroids = asteroidList;
  });

  socket.on('asteroidHurt', function(clientObj) {
    return updateClients(clientObj);
  });

  socket.on('clientList', function(clientList) {
    clients = clientList;
    return myId = clientList[0].id;
  });

}).call(this);