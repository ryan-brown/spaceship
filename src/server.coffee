http = require "http"
fs = require "fs"
io = require "socket.io"
clients = []
tickRate = 30
mapSize =
  width: 1280
  height: 1280

asteroids = []

serverCallback = (req, res) ->
  if req.url == "/favicon.ico"
    res.writeHead 200
    res.end()
    return

    if req.url.match(/png/)
      res.writeHead 200, {'Content-Type' : 'image/png'}
    else
      res.writeHead 200, {'Content-Type' : 'text/html'}


  fs.readFile ".#{req.url}", (err, content) ->
    console.log "Someone is looking at me! Hello there!"
    if err
      fs.readFile "myCanvas.html", (err, content) ->
        res.write "#{content}"
        res.end()
    else
      res.write "#{content}"
      res.end()

clientCallback = (client) ->

  clientObj =
    id: client.id
    health: 100
    x: Math.random()*mapSize.width
    y: Math.random()*mapSize.height
    points: 0
    width: 20
    height: 20
    bbRadius: 10
    rotation: 0
    kills: 0
    deaths: 0
    lastBullet: 0
    velocity:
      x: 0
      y: 0
    myKeys: [false, false, false, false]
    myBullets: []

  clients.unshift clientObj
  client.broadcast.emit 'clientJoined', clientObj
  client.emit 'clientList', clients

  client.on 'buttonPressedStart', (evt) ->
    if evt == 32
      clientObj.myKeys[4] = true
    else
      clientObj.myKeys[evt] = true

  client.on 'buttonPressedStop', (evt) ->
    if evt == 32
      clientObj.myKeys[4] = false
    else
      clientObj.myKeys[evt] = false

  client.on 'disconnect', (evt) ->
    for i in [0...clients.length]
      if clients[i]? and clients[i].id == client.id
        socket.sockets.emit 'clientQuit', clients[i]
        clients.splice i, 1

  client.on 'clientStoppedFocus', (evt) ->
    for i in [0...clientObj.myKeys.length]
      break if clientObj.myKeys.length < 1
      clientObj.myKeys[i] = false
      console.log "PIE"


radsToDegrees = (rads) ->
  (rads * 180) / Math.PI

handleControls = ->
  for clientObj in clients
    if clientObj.myKeys[0]
      clientObj.rotation -= Math.PI * (tickRate/1000)
      socket.sockets.emit 'clientMoved', clientObj

    if clientObj.myKeys[2]
      clientObj.rotation += Math.PI * (tickRate/1000)
      socket.sockets.emit 'clientMoved', clientObj

    if clientObj.myKeys[1]
      clientObj.velocity.x += 5 * Math.cos clientObj.rotation
      clientObj.velocity.y += 5 * Math.sin clientObj.rotation

    totalVel = Math.sqrt Math.pow(clientObj.velocity.x, 2) + Math.pow(clientObj.velocity.y, 2)
    maxVel = 200
    if totalVel > maxVel
      clientObj.velocity.x *= maxVel / totalVel
      clientObj.velocity.y *= maxVel / totalVel

    if clientObj.myKeys[4] and (clientObj.lastBullet > 0.25)
      bullet =
        x: clientObj.x
        y: clientObj.y
        width: 3
        height: 3
        bbRadius: 1
        damage: 20
        age: 0
        velocity:
          x: clientObj.velocity.x + (500 * Math.cos clientObj.rotation)
          y: clientObj.velocity.y + (500 * Math.sin clientObj.rotation)

      clientObj.lastBullet = 0
      clientObj.myBullets.push bullet

###
    if clientObj.myKeys[3]
      clientObj.velocity.x -= Math.cos radsToDegrees(clientObj.rotation)
      clientObj.velocity.y -= Math.sin radsToDegrees(clientObj.rotation)
###

updatePhysics = ->
  for clientObj in clients
    addVelocity clientObj
    stayOnMap clientObj

    currBullets = clientObj.myBullets.length
    clientObj.lastBullet += (tickRate/1000)

    for i in [0...clientObj.myBullets.length]
      bullet = clientObj.myBullets[i]
      break unless bullet?

      addVelocity bullet
      bullet.age += (tickRate/1000)
      stayOnMap bullet

      clientObj.myBullets.splice i, 1 if bullet.age > 1.5

    socket.sockets.emit 'bulletsUpdated', clientObj if currBullets > 0

    if clientObj.velocity.x != 0 or clientObj.velocity.y != 0
      socket.sockets.emit 'clientMoved', clientObj


    if asteroids.length > 0
      for asteroidObj in asteroids
        addVelocity asteroidObj
        stayOnMap asteroidObj
      socket.sockets.emit 'asteroidUpdate', asteroids


stayOnMap = (obj) ->
    if obj.x < 0 
      obj.x += mapSize.width
    if obj.x > mapSize.width
      obj.x -= mapSize.width
    if obj.y < 0 
      obj.y += mapSize.height
    if obj.y > mapSize.height
      obj.y -= mapSize.height

addVelocity = (obj) ->
    obj.x += (tickRate/1000) * obj.velocity.x
    obj.y += (tickRate/1000) * obj.velocity.y

clientDied = (clientObj) ->
  clientObj.health = 100
  clientObj.x = Math.random()*mapSize.width
  clientObj.y = Math.random()*mapSize.height
  clientObj.points = Math.round(clientObj.points/2)
  clientObj.deaths++
  socket.sockets.emit 'clientDied', clientObj

isColliding = (obj1, obj2) ->
  return false unless obj1? and obj2?

  if obj1.bbRadius? and obj2.bbRadius?
    distance_x = obj2.x - obj1.x
    distance_y = obj2.y - obj1.y

    distance_total = Math.sqrt (Math.pow(distance_x, 2) + Math.pow(distance_y, 2))

    return obj1.bbRadius+obj2.bbRadius > distance_total

collisionDetection = ->

  for shooterClient in clients
      for i in [0...shooterClient.myBullets.length]
        break if shooterClient.myBullets.length < 1
        bullet = shooterClient.myBullets[i]
        didHit = false

        for clientObj in clients
          continue if shooterClient.id == clientObj.id

          if isColliding clientObj, bullet
            clientObj.health -= bullet.damage
            didHit = true

            if clientObj.health <= 0
              shooterClient.points += Math.round(clientObj.points/4)
              shooterClient.kills++

              socket.sockets.emit 'bulletHit', shooterClient
              clientDied clientObj
            else
              shooterClient.points += 50
              socket.sockets.emit 'bulletHit', shooterClient
              socket.sockets.emit 'bulletHurt', clientObj


        for h in [0...asteroids.length]
          break if asteroids.length < 1
          asteroidObj = asteroids[h]
          if isColliding asteroidObj, bullet
            didHit = true
            shooterClient.points += Math.round(asteroidObj.bbRadius)
            breakAsteroid h

        shooterClient.myBullets.splice i, 1 if didHit

      for h in [0...asteroids.length]
        break if asteroids.length < 1
        asteroidObj = asteroids[h]
        if isColliding shooterClient, asteroidObj
          breakAsteroid asteroidObj
          shooterClient.health -= asteroidObj.bbRadius
          clientDied shooterClient if shooterClient.health <= 0
          breakAsteroid h
          socket.sockets.emit 'asteroidHurt', shooterClient


newAsteroid = (x = Math.random()*mapSize.width, y = Math.random()*mapSize.height, radius = (Math.random()*10)+30) ->
    asteroid =
      x: x
      y: y
      id: asteroids.length
      bbRadius: radius
      velocity: 
        x: (Math.random()*200) - 100
        y: (Math.random()*200) - 100

    asteroids.push asteroid

breakAsteroid = (asteroidIndex) ->
  return unless asteroids[asteroidIndex]?
  asteroidObj = asteroids[asteroidIndex]
  if asteroidObj.bbRadius > 15
    newAsteroid asteroidObj.x, asteroidObj.y, asteroidObj.bbRadius/2
    newAsteroid asteroidObj.x, asteroidObj.y, asteroidObj.bbRadius/2

  asteroids.splice asteroidIndex, 1

updateAsteroids = ->
  totalSize = 0
  for asteroidObj in asteroids
    totalSize += asteroidObj.bbRadius

  newAsteroid() if totalSize < 200

updateStats = ->
  for clientObj in clients
    if clientObj.health < 100
      clientObj.health += 0.05

eachFrame = ->
  updateStats()
  handleControls()
  updateAsteroids()
  updatePhysics()
  collisionDetection()

server = http.createServer(serverCallback).listen 8080
socket = io.listen server
socket.on 'connection', clientCallback
socket.set 'log level', 1

setInterval eachFrame, tickRate