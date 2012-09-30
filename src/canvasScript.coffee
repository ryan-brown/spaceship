socket = io.connect()
canvas = null
buffer = null
ctx = null
mainContext = null
myId = 0
myBg = new Image()
myBg.src = 'http://www.californiaindianeducation.org/science_lab/pics/space_photos/Space_Deep.jpg'

myKeys = [false, false, false, false, false]
clients = []
asteroids = []

window.init = ->
  canvas = document.getElementById 'myCanvas'
  buffer = document.getElementById 'myBuffer'
  canvas.focus()
  buffer.width = myBg.width
  buffer.height = myBg.height
  ctx = buffer.getContext "2d"
  setInterval update, 30
  mainContext = canvas.getContext "2d"

  canvas.onblur = () ->
    socket.emit 'clientStoppedFocus', true
    


  canvas.onkeydown = (evt) ->
    for i in [0..3]
       if evt.which == 37+i and myKeys[i] == false
          myKeys[i] = true
          socket.emit 'buttonPressedStart', i
       if evt.which == 32 and myKeys[4] == false
          myKeys[4] = true
          socket.emit 'buttonPressedStart', 32


  canvas.onkeyup = (evt) ->
    for i in [0..3]
      if evt.which == 37+i
        myKeys[i] = false
        socket.emit 'buttonPressedStop', i
      else if evt.which == 32
        myKeys[4] = false
        socket.emit 'buttonPressedStop', 32


update = ->
  ctx.save()
  blank()
  background()
  draw()
  ctx.restore()


blank = ->
  ctx.fillStyle = "#000"
  ctx.fillRect 0, 0, canvas.width, canvas.height

background = ->
  ctx.drawImage myBg, 0, 0


draw = ->
  drawAllPlayers ctx
  drawAllAsteroids ctx

  mainContext.save()
  mainContext.translate(canvas.width/2-clients[0].x, canvas.height/2-clients[0].y)
  mainContext.drawImage buffer, 0, 0

  drawBottom = clients[0].y >= buffer.height-canvas.height/2
  drawTop = clients[0].y <= canvas.height/2
  drawRight = clients[0].x >= buffer.width-canvas.width/2
  drawLeft = clients[0].x <= canvas.width/2
  

  if drawBottom
    # Top -> Bottom
    mainContext.drawImage buffer, 0, 0, buffer.width, canvas.height/2, 0, buffer.height, buffer.width, canvas.height/2
  else if drawTop
    # Bottom -> Top
    mainContext.drawImage buffer, 0, buffer.height-canvas.height/2, buffer.width, canvas.height/2, 0, -canvas.height/2, buffer.width, canvas.height/2

  if drawRight
    # Left -> Right
    mainContext.drawImage buffer, 0, 0, canvas.width/2, buffer.height, buffer.width, 0, canvas.width/2, buffer.height
  else if drawLeft
    # Right -> Left
    mainContext.drawImage buffer, buffer.width-canvas.width/2, 0, canvas.width/2, buffer.height, -canvas.width/2, 0, canvas.width/2, buffer.height
  
  if drawBottom && drawRight
    # Top Left -> Bottom Right
    mainContext.drawImage buffer, 0, 0, canvas.width/2, canvas.height/2, buffer.width, buffer.height, canvas.width/2, canvas.height/2
  else if drawTop && drawLeft
    # Bottom Right -> Top Left
    mainContext.drawImage buffer, buffer.width-canvas.width/2, buffer.height-canvas.height/2, canvas.width/2, canvas.height/2, -canvas.width/2, -canvas.height/2, canvas.width/2, canvas.height/2
  else if drawTop && drawRight
    # Bottom Left -> Top Right
    mainContext.drawImage buffer, 0, buffer.height-canvas.height/2, canvas.width/2, canvas.height/2, buffer.width, -canvas.height/2, canvas.width/2, canvas.height/2
  else if drawBottom && drawLeft
    # Top Right -> Bottom Left
    mainContext.drawImage buffer, buffer.width-canvas.width/2, 0, canvas.width/2, canvas.height/2, -canvas.width/2, buffer.height, canvas.width/2, canvas.height/2


  mainContext.restore()

  #drawAllPlayers mainContext
  drawOnlyPlayer mainContext


  #mainContext.drawImage buffer, buffer.width-(canvas.width/2),  buffer.height-(canvas.height/2), canvas.width/2,  canvas.height/2, 0, 0, canvas.width/2, canvas.height/2

drawAllPlayers = (context) ->
  for clientObj in clients.slice(0).reverse()
    context.save()

    context.translate clientObj.x, clientObj.y
    context.rotate clientObj.rotation
    context.translate -clientObj.x, -clientObj.y
    drawPlayer clientObj, context
    context.restore()

    for bullet in clientObj.myBullets
      context.fillStyle = "#fff"
      context.fillRect bullet.x, bullet.y, 3, 3

drawOnlyPlayer = (context) ->

  context.save()
  context.translate canvas.width/2, canvas.height/2
  context.rotate clients[0].rotation
  context.translate -clients[0].x, -clients[0].y
  drawPlayer clients[0], context
  context.restore()
  context.save()
  context.translate canvas.width/2, canvas.height/2
  context.translate -clients[0].x, -clients[0].y
  for bullet in clients[0].myBullets
    context.fillStyle = "#fff"
    context.fillRect bullet.x, bullet.y, 3, 3
  context.restore()

drawPlayer = (playerObj, context) ->
  context.save()

  context.strokeStyle = '#fff';
  context.lineWidth   = 1;

  context.beginPath();

  context.moveTo playerObj.x-(playerObj.height/2), playerObj.y-(playerObj.width/2)
  context.lineTo playerObj.x-(playerObj.height/2), playerObj.y+(playerObj.width/2)
  context.lineTo playerObj.x+(playerObj.height/2), playerObj.y

  context.closePath()
  context.stroke()

  context.fillStyle = "#00dd00"
  context.fillRect playerObj.x-(playerObj.height/2)-10, playerObj.y-(playerObj.width/2), 3, (playerObj.health/100)*playerObj.width


  context.fillStyle = "#fff"
  context.font = "12px Arial";
  context.textAlign = "center";
  #context.textBaseline = "top";
  context.translate playerObj.x-(playerObj.height/2)-22, playerObj.y
  context.rotate Math.PI/2
  context.fillText "#{playerObj.points}", 0, 0

  context.restore()


drawAllAsteroids = (context) ->
  context.save()
  for asteroidObj in asteroids
    context.beginPath()
    context.strokeStyle = "#fff"
    context.arc(asteroidObj.x, asteroidObj.y, asteroidObj.bbRadius, 0, 2*Math.PI, false)
    context.stroke()
    context.closePath()
  context.restore()


isPlayer = (clientObj) ->
  clientObj.id == myId

updateClients = (clientObj) ->
  for i in [0...clients.length]
    if clients[i]? and clients[i].id == clientObj.id
      clients[i] = clientObj

socket.on 'clientMoved', (clientObj) ->
  updateClients clientObj

socket.on 'bulletsUpdated', (clientObj) ->
  updateClients clientObj

socket.on 'bulletHurt', (clientObj) ->
  updateClients clientObj

socket.on 'bulletHit', (clientObj) ->
  updateClients clientObj
  if clientObj.id == myId
    document.getElementById('myKills').innerHTML = "Kills: #{clientObj.kills}"

socket.on 'clientDied', (clientObj) ->
  updateClients clientObj
  if clientObj.id == myId
    document.getElementById('myDeaths').innerHTML = "Deaths: #{clientObj.deaths}"

socket.on 'clientQuit', (clientObj) ->
  for i in [0...clients.length]
    break unless clients[i]?
    clients.splice i, 1 if clients[i].id == clientObj.id

socket.on 'clientJoined', (clientObj) ->
  clients.push clientObj


socket.on 'asteroidUpdate', (asteroidList) ->
  asteroids = asteroidList

socket.on 'asteroidHurt', (clientObj) ->
  updateClients clientObj

socket.on 'clientList', (clientList) ->
  clients = clientList
  myId = clientList[0].id