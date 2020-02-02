g = love.graphics

function love.load()
  width = g.getWidth()    -- get the width and height for future use
  height = g.getHeight()

  scoreFontScale = width/20
  titleFontScale = width/5.3
  buttonFontScale = width/10.6
  largeFontScale = height/1.26

  textBuffer = height/30

  scoreFont = g.newFont(scoreFontScale)    -- making a larger font for the score
  titleFont = g.newFont(titleFontScale)
  buttonFont = g.newFont(buttonFontScale)
  largeFont = g.newFont(largeFontScale)

  throwing_multiplier = 0.2   -- this will affect the speed of the projectile

  num_players = 2

  math.randomseed(os.time())    -- seeding random number generation

  random_color = {}

  planets = {}

  players = {}

  ball = {}
  ball.x = 0    -- set up the ball's values
  ball.y = 0
  ball.dx = 0
  ball.dy = 0
  ball.r = width/160
  ball.isThrown = false

  score = 0
  tempscore = 0
  cooldown_timer = 0

  plants = {}

  particles = {}

  explosions = {}
  explosion_timer = 0

  turn = 1

  hit = false

  previousScene = "start"
  scene = "start"

  titlePlanet = {}
  titlePlanet.x = width/1.42
  titlePlanet.y = height/1.5
  titlePlanet.r = 100

  titleBall = {}
  titleBall.x = titlePlanet.x
  titleBall.y = titlePlanet.y - 150
  titleBall.r = 10
  titleBall.dx = -80
  titleBall.dy = 0

  buttonCooldown = 0

  hasGenerated = false

  showTip = false
  tips = {"Hit players at their feet to kill them",
          "Use 'a' and 'd' to move around your planet!",
          "Remember, you can't go over craters!",
          "You can trap other players by hitting either side of them",
          "Your projectile will disappear after 5 seconds, so watch out!"}
  tipTimer = 0

  winScreenTimer = 0

  startButtons = {}
  setupButtons = {}
  pauseButtons = {}

  playerWon = {}

  deadPlayers = {}

  music = love.audio.newSource( 'Ben_Game_Jan.mp3', 'stream' )
  music:setLooping(true) --so it doesnt stop
  music:play()

  firstGame = true

  testNumPlayers = -1

  debug = io.open("debug.txt", "a")

  scenes = {"start"}
end

function love.update(dt)
  buttonCooldown = buttonCooldown + 1

  if scene == "start" then
    if true then    -- acceleration stuff
      titleBall.x = titleBall.x + (titleBall.dx * dt)    -- add the titleBall's velocity to the position
      titleBall.y = titleBall.y + (titleBall.dy * dt)

      mass_multiplier = 1000    -- affects gravitational influence
      G = 10    -- gravitational constant

      vx = titleBall.x - titlePlanet.x    -- get the vector from the titleBall to the titlePlanet
      vy = titleBall.y - titlePlanet.y
      dist = distanceBetween(titleBall, titlePlanet)    -- get the distance
      force = -(G * (titlePlanet.r * mass_multiplier) * (titleBall.r * mass_multiplier))/dist^2   -- find the force based on the distance and masses
      acceleration1 = force/(titlePlanet.r * mass_multiplier)    -- titlePlanet's acceleration (not used)
      acceleration2 = force/(titleBall.r * mass_multiplier)    -- titleBall's acceleration (not used)

      nx, ny = 0, 0   -- normalize?
      if dist > 0 then
        nx, ny = vx/dist, vy/dist
      end

      acceleration2x = nx*acceleration2   -- get the normalized accelerations
      acceleration2y = ny*acceleration2

      titleBall.dy = titleBall.dy + acceleration2y*dt   -- add the titleBall's acceleration to it's velocity
      titleBall.dx = titleBall.dx + acceleration2x*dt
    end

    firstGame = true

    mouseX = love.mouse.getX()
    mouseY = love.mouse.getY()

    startX = width/80
    startY = textBuffer + titleFontScale + textBuffer
    startW = width/4
    startH = buttonFontScale

    local button1 = {}
    button1.x = startX
    button1.y = startY
    button1.w = startW
    button1.h = startH
    table.insert(startButtons, button1)

    quitX = width/80
    quitY = textBuffer + titleFontScale + textBuffer + buttonFontScale + textBuffer
    quitW = width/4.5
    quitH = buttonFontScale

    local button2 = {}
    button2.x = quitX
    button2.y = quitY
    button2.w = quitW
    button2.h = quitH
    table.insert(startButtons, button2)

    if love.mouse.isDown(1) and mouseX > startX and mouseX < startX + startW and mouseY > startY and mouseY < startY + startH then
      if buttonCooldown > 5 then toScene("setup") end
    elseif love.mouse.isDown(1) and mouseX > quitX and mouseX < quitX + quitW and mouseY > quitY and mouseY < quitY + quitH then
      if buttonCooldown > 5 then love.event.quit(0) end
    end
  elseif scene == "setup" then
    mouseX = love.mouse.getX()
    mouseY = love.mouse.getY()

    plusX = textBuffer + largeFontScale/1.5 + textBuffer
    plusY = textBuffer + buttonFontScale + textBuffer + largeFontScale/2 + textBuffer/2 - buttonFontScale
    plusW = width/13
    plusH = width/13

    local button1 = {}
    button1.x = plusX
    button1.y = plusY
    button1.w = plusW
    button1.h = plusH
    table.insert(setupButtons, button1)

    minusX = textBuffer + largeFontScale/1.5 + textBuffer
    minusY = textBuffer + buttonFontScale + textBuffer + largeFontScale/2 + textBuffer*4
    minusW = width/15
    minusH = width/15

    local button2 = {}
    button2.x = minusX
    button2.y = minusY
    button2.w = minusW
    button2.h = minusH
    table.insert(setupButtons, button2)

    goX = textBuffer + largeFontScale/1.5 + textBuffer + titleFontScale/1.5 + textBuffer
    goY = textBuffer + buttonFontScale + textBuffer + largeFontScale/2 - titleFontScale/2.5
    goW = width/3
    goH = width/6

    local button3 = {}
    button3.x = goX
    button3.y = goY
    button3.w = goW
    button3.h = goH
    table.insert(setupButtons, button3)

    if love.mouse.isDown(1) and mouseX > plusX and mouseX < plusX + plusW and mouseY > plusY and mouseY < plusY + plusH then
      if buttonCooldown > 5 and num_players < 9 then num_players = num_players + 1 end
      buttonCooldown = 0
    elseif love.mouse.isDown(1) and mouseX > minusX and mouseX < minusX + minusW and mouseY > minusY and mouseY < minusY + minusH then
      if buttonCooldown > 5 and num_players > 2 then num_players = num_players - 1 end
      buttonCooldown = 0
    elseif love.mouse.isDown(1) and mouseX > goX and mouseX < goX + goW and mouseY > goY and mouseY < goY + goH then
      if buttonCooldown > 5 then
        generatePlayers()
        toScene("loading")
      end
    end
  elseif scene == "loading" then
    firstGame = false

    tipTimer = tipTimer + dt
    if tipTimer > 3 then
      hasGenerated = false
      generateWorld()
      toScene("game")
      tipTimer = 0
    end
  elseif scene == "game" then
    lastTurn = turn - 1
    if lastTurn < 1 then lastTurn = #players end

    if turn > #players then
      turn = 1
    end

    if hasGenerated == false then
      generateWorld()
      debug:write("players length at start of game: " .. #players .. "\n")
      hasGenerated = true
    end

    if turn > #players then
      turn = 1
    end

    local player = players[turn]

    for i = 1, #planets, 1 do   -- check for collisions
      local craters = planets[i].craters
      if #craters > 0 then
        for j = 1, #craters, 1 do
          local crater = craters[j]
          for k = 1, #players, 1 do
            local player = players[k]
            if player ~= nil and circleRectRotCollision(crater, player) then   -- detect player collisions with crater and kill player
              table.insert(deadPlayers, table.remove(players, k))
              ball.isThrown = false
              score = 0
              cooldown_timer = 0
              hit = true
            end
          end
        end
      end
    end

    if #players < 2 then
      players[1].score = players[1].score + 1
      debug:write("players[1] turn: " .. players[1].turn .. "\n")
      playerWon = players[1]
      debug:write("playerWon turn: " .. playerWon.turn .. "\n")
      hasGenerated = false
      ball.isThrown = false
      score = 0
      cooldown_timer = 0
      winScreenTimer = 0
      turn = 1
      debug:write("players length at to win: " .. #players .. "\n")
      toScene("win")
    end

    for i = 1, #players, 1 do   -- reset rot to 0 if gone all the way around
      local player = players[i]
      if player.rot > 2*math.pi then
        player.rot = 0
      end
    end
    temporary_radius = planets[player.planet].r + player.h    -- makes a temporary radius equal to the radius of the planet + the height of the player
    if love.keyboard.isDown("a") then   -- rotate the player counter clockwise around the planet
      if #planets[player.planet].craters == 0 then    -- if there are no craters, just move
        player.rot = player.rot - 2*dt
      else

        move = true   -- start by saying you're able to move

        for i = 1, #planets[player.planet].craters, 1 do    -- go through each crater on the planet
          local crater = planets[player.planet].craters[i]

          new_point = {}
          new_point.x = (planets[player.planet].r * math.cos(player.rot - 2*dt)) + planets[player.planet].x   -- calculate your new coordinate (at left foot of player)
          new_point.y = (planets[player.planet].r * math.sin(player.rot - 2*dt)) + planets[player.planet].y

          if distanceBetween(new_point, crater) < crater.r + 1 then   -- check if it's inside the crater
            move = false    -- if it is, set move to false
          end
        end

        if move then    -- if you can still move, move
          player.rot = player.rot - 2*dt
        end
      end
    elseif love.keyboard.isDown("d") then   -- rotate the player clockwise around the planet (same as going counter clockwise)
      if #planets[player.planet].craters == 0 then
        player.rot = player.rot + 2*dt
      else

        move = true

        for i = 1, #planets[player.planet].craters, 1 do
          local crater = planets[player.planet].craters[i]

          new_point = {}
          new_point.x = (planets[player.planet].r * math.cos(player.rot + 2*dt + (4*math.pi/planets[player.planet].r))) + planets[player.planet].x    -- calculates right foot of player if moved
          new_point.y = (planets[player.planet].r * math.sin(player.rot + 2*dt + (4*math.pi/planets[player.planet].r))) + planets[player.planet].y

          if distanceBetween(new_point, crater) < crater.r + player.w/2 then
            move = false
          end
        end

        if move then
          player.rot = player.rot + 2*dt
        end
      end
    end

    -- if love.keyboard.isDown("w") then    -- this is for unlimited movement
    --   player.y = player.y - 2
    -- elseif love.keyboard.isDown("a") then
    --   player.x = player.x - 2
    -- elseif love.keyboard.isDown("s") then
    --   player.y = player.y + 2
    -- elseif love.keyboard.isDown("d") then
    --   player.x = player.x + 2

    player.x = (temporary_radius * math.cos(player.rot)) + planets[player.planet].x   -- move the player around the planet based on its rotation
    player.y = (temporary_radius * math.sin(player.rot)) + planets[player.planet].y

   if ball.isThrown then    -- run when the ball is thrown

      for i = 1, #planets, 1 do
        local planet = planets[i]

        if true then    -- acceleration stuff
          ball.x = ball.x + (ball.dx * dt)    -- add the ball's velocity to the position
          ball.y = ball.y + (ball.dy * dt)

          mass_multiplier = 1000    -- affects gravitational influence
          G = 15    -- gravitational constant

          vx = ball.x - planet.x    -- get the vector from the ball to the planet
          vy = ball.y - planet.y
          dist = distanceBetween(ball, planet)    -- get the distance
          force = -(G * (planet.r * mass_multiplier) * (ball.r * mass_multiplier))/dist^2   -- find the force based on the distance and masses
          acceleration1 = force/(planet.r * mass_multiplier)    -- planet's acceleration (not used)
          acceleration2 = force/(ball.r * mass_multiplier)    -- ball's acceleration (not used)

          nx, ny = 0, 0   -- normalize?
          if dist > 0 then
            nx, ny = vx/dist, vy/dist
          end

          acceleration2x = nx*acceleration2   -- get the normalized accelerations
          acceleration2y = ny*acceleration2

          ball.dy = ball.dy + acceleration2y*dt   -- add the ball's acceleration to it's velocity
          ball.dx = ball.dx + acceleration2x*dt
        end

        if distanceBetween(ball, planet) < planet.r + ball.r then   -- reset if the ball has hit the planet
          ball.isThrown = false
          cooldown_timer = 0
          explosion_timer = 0
          score = 0
          turn = turn + 1

          local crater = {}
          crater.r = math.random(width/80, width/53.33)    -- set up a circle for the crater
          crater.x = ball.x
          crater.y = ball.y
          table.insert(planet.craters, crater)    -- add the crater to the planet's list

          for j = #particles, 1, -1 do    -- remove particle trail
            table.remove(particles, j)
          end

          explode(ball.x, ball.y, 7, 10, width/80, width/55.3, -100, 100, 950, 400, 400, 50)

          local plant = {}
          plant.x = ball.x
          plant.y = ball.y
          plant.w = 2
          plant.h = 5
        end
      end

      if tempscore == 60 then   -- increase the score by 1 each second
        score = score + 1
        cooldown_timer = cooldown_timer + 1
        tempscore = 0
      else
        tempscore = tempscore + 1
      end

      if tempscore % 5 == 0 then    -- add a particle at the current position of the ball every fifth 1/60 of a second
        local particle = {}
        particle.x = ball.x
        particle.y = ball.y
        particle.r = math.random(width/266.6, width/160)
        particle.dx = math.random(-0.5, 0.5)
        particle.dy = math.random(-0.5, 0.5)
        table.insert(particles, particle)     -- add a particle at the ball's position with some random values
      end

      if score == 5 then    -- remove ball is it's been 5 seconds
        ball.isThrown = false
        score = 0
        turn = turn + 1
        cooldown_timer = 0
      end
    end

    for i = #particles, 1, -1 do    -- update the particle trail
      local p = particles[i]
      p.x = p.x + (p.dx * dt)*60   -- move the particle
      p.y = p.y + (p.dy * dt)*60

      p.dx = p.dx / 1.1   -- slow down the particle
      p.dy = p.dy / 1.1

      p.r = p.r - 0.1     -- reduce the particle's size

      if p.r < 0 then
        table.remove(particles, i)    -- when a particle gets too small, just delete it
      end
    end

    explosion_timer = explosion_timer + 1   -- go from 0 to 50 for the epxlosions' radius
    if explosion_timer > 50 then
      explosion_timer = 0
    end

    for i = #explosions, 1, -1 do   -- makes the explosion animation
      local e = explosions[i]
      e.x = e.x + (e.dx * dt)*60    -- move the particle
      e.y = e.y + (e.dy * dt)*60

      e.dx = e.dx / 1.01   -- slow down the particle
      e.dy = e.dy / 1.01

      e.r = 2 * (5*(math.sqrt(explosion_timer)-((1/7)*explosion_timer - 10))-50)     -- reduce the particle's size

      if e.r < 0 then
        table.remove(explosions, i)    -- when a particle gets too small, just delete it
      end
    end
  elseif scene == "pause" then
    mouseX = love.mouse.getX()
    mouseY = love.mouse.getY()

    resumeX = width/80
    resumeY = textBuffer + titleFontScale + textBuffer
    resumeW = width/2.5
    resumeH = buttonFontScale

    local button1 = {}
    button1.x = resumeX
    button1.y = resumeY
    button1.w = resumeW
    button1.h = resumeH
    table.insert(pauseButtons, button1)

    mainMenuX = width/80
    mainMenuY = textBuffer + titleFontScale + textBuffer + buttonFontScale + textBuffer
    mainMenuW = width/1.85
    mainMenuH = buttonFontScale

    local button2 = {}
    button2.x = mainMenuX
    button2.y = mainMenuY
    button2.w = mainMenuW
    button2.h = mainMenuH
    table.insert(pauseButtons, button2)

    if love.mouse.isDown(1) and mouseX > resumeX and mouseX < resumeX + resumeW and mouseY > resumeY and mouseY < resumeY + resumeH then
      if buttonCooldown > 5 then toPrevious() end
    elseif love.mouse.isDown(1) and mouseX > mainMenuX and mouseX < mainMenuX + mainMenuW and mouseY > mainMenuY and mouseY < mainMenuY + mainMenuH then
      if buttonCooldown > 5 then
        toScene("start")
        hasGenerated = false
      end
    end
  elseif scene == "win" then
    winScreenTimer = winScreenTimer + dt
    if winScreenTimer > 3 then
      hasGenerated = false
      generateWorld()
      revivePlayers()
      turn = 1
      ball.isThrown = false
      testNumPlayers = #players
      toScene("game")
      winScreenTimer = 0
    end
  end
end

function love.draw()
  if scene == "start" then
    g.setFont(scoreFont)
    g.setBackgroundColor(0.1, 0.1, 0.1)
    g.setColor(0.9, 0.3, 0.3)
    g.setFont(titleFont)
    g.print("Orbits", textBuffer, textBuffer)
    g.setFont(buttonFont)
    g.print("Start", textBuffer, textBuffer + titleFontScale + textBuffer)
    g.print("Quit", textBuffer, textBuffer + titleFontScale + textBuffer + buttonFontScale + textBuffer)

    g.setColor(0.3, 0.9, 0.3)
    g.circle("fill", titleBall.x, titleBall.y, titleBall.r)

    g.setColor(0.3, 0.3, 0.9)
    g.circle("fill", titlePlanet.x, titlePlanet.y, titlePlanet.r)

    -- for i = 1, #startButtons, 1 do
    --   local button = startButtons[i]
    --   g.setColor(0.9, 0.3, 0.3)
    --   g.rectangle("line", button.x, button.y, button.w, button.h)
    -- end
  elseif scene == "setup" then
    g.setColor(0.9, 0.3, 0.3)
    g.setFont(buttonFont)
    g.printf("Number of Players:", textBuffer, textBuffer, width - 2*textBuffer)
    g.setFont(largeFont)
    g.print(num_players, textBuffer, textBuffer + buttonFontScale + textBuffer)
    g.setFont(buttonFont)
    g.print("+", textBuffer + largeFontScale/1.5 + textBuffer, textBuffer + buttonFontScale + textBuffer + largeFontScale/2 - textBuffer/2 - buttonFontScale)
    g.setFont(titleFont)
    g.print("-", textBuffer + largeFontScale/1.5 + textBuffer, textBuffer + buttonFontScale + textBuffer + largeFontScale/2 + textBuffer/2)
    g.print("Go!", textBuffer + largeFontScale/1.5 + textBuffer + titleFontScale/1.5 + textBuffer, textBuffer + buttonFontScale + textBuffer + largeFontScale/2 - titleFontScale/2.5)

    -- for i = 1, #setupButtons, 1 do
    --   local button = setupButtons[i]
    --   g.setColor(0.9, 0.3, 0.3)
    --   g.rectangle("line", button.x, button.y, button.w, button.h)
    -- end
  elseif scene == "loading" then
    g.setColor(0.9, 0.3, 0.3)
    g.setFont(buttonFont)
    if showTip == false then
      tip = tips[math.random(1, #tips)]
      showTip = true
    end
    g.print("Tip:", textBuffer, textBuffer)
    g.printf(tip, textBuffer, textBuffer + buttonFontScale + textBuffer, width/1.14)
  elseif scene == "game" then
    g.setBackgroundColor((1 - random_color.r)/2, (1 - random_color.g)/2, (1 - random_color.b)/2)    -- draw the opposite color of the planets as the background

    g.setFont(scoreFont)
    g.setColor(random_color.r, random_color.b, random_color.g)
    if players[turn] ~= nil then
      g.print("Player " .. players[turn].turn, textBuffer, textBuffer)
      g.print("Score: " .. players[turn].score, textBuffer, textBuffer + scoreFontScale + textBuffer)
    end

    for i = 1, #planets, 1 do   -- draw the planets
      local planet = planets[i]
      g.setColor(random_color.r, random_color.b, random_color.g)
      g.circle("fill", planet.x, planet.y, planet.r)
    end

    for i = 1, #planets, 1 do
      for j = 1, #planets[i].craters, 1 do
        local crater = planets[i].craters[j]
        g.setColor((1 - random_color.r)/2, (1 - random_color.g)/2, (1 - random_color.b)/2)
        g.circle("fill", crater.x, crater.y, crater.r)
      end
    end

    for i = #explosions, 1, -1 do
      local e = explosions[i]
      g.setColor(e.red, e.green, e.blue)
      g.circle("fill", e.x, e.y, e.r)   -- draw the particles
    end

    for i = 1, #players, 1 do
      local player = players[i]
      if player.x ~= nil then
        g.setColor(player.red, player.green, player.blue)
        g.translate(player.x, player.y)
        g.rotate(player.rot + math.pi/2)    -- rotate the player so it's perpendicular to the surface of the planet
        g.translate(-player.x, -player.y)
        g.rectangle("fill", player.x, player.y, player.w, player.h)   -- draw the player
        g.origin()
      end
    end

    if ball.isThrown then
      g.setColor(0.5, 0.9, 0.7)
      g.circle("fill", ball.x, ball.y, ball.r)    -- draw the ball

      -- g.line(ball.x, ball.y, ball.x + ball.dx, ball.y + ball.dy)    -- draw a line to represent the ball's velocity
    end

    for i = #particles, 1, -1 do
      local p = particles[i]
      g.circle("fill", p.x, p.y, p.r)   -- draw the particles
    end

    -- for i = 1, #zones, 1 do
    --   local zone = zones[i]
    --   g.rectangle("line", zone.x, zone.y, zone.width, zone.height)    -- draw the zones
    -- end
  elseif scene == "pause" then
    g.setFont(scoreFont)
    g.setBackgroundColor(0.1, 0.1, 0.1)
    g.setColor(0.9, 0.3, 0.3)
    g.setFont(titleFont)
    g.print("Paused", textBuffer, textBuffer)
    g.setFont(buttonFont)
    g.print("Resume", textBuffer, textBuffer + titleFontScale + textBuffer)
    g.print("Main Menu", textBuffer, textBuffer + titleFontScale + textBuffer + buttonFontScale + textBuffer)

    -- for i = 1, #pauseButtons, 1 do
    --   local button = pauseButtons[i]
    --   g.setColor(0.9, 0.3, 0.3)
    --   g.rectangle("line", button.x, button.y, button.w, button.h)
    -- end
  elseif scene == "win" then
    g.setFont(scoreFont)
    g.setBackgroundColor(0.1, 0.1, 0.1)
    g.setColor(0.9, 0.3, 0.3)
    g.setFont(buttonFont)
    g.print("Player " .. playerWon.turn, textBuffer, textBuffer)
    g.print("wins!", textBuffer, textBuffer + buttonFontScale + textBuffer)

    local planet = {}
    planet.x = width/1.3
    planet.y = height/0.75
    planet.r = height/1.5
    g.setColor(random_color.r, random_color.b, random_color.g)
    g.circle("fill", planet.x, planet.y, planet.r)

    local player = {}
    player.w = width/8
    player.h = width/3
    player.x = planet.x - player.w/2
    player.y = planet.y - planet.r - player.h
    g.setColor(playerWon.red, playerWon.green, playerWon.blue)
    g.rectangle("fill", player.x, player.y, player.w, player.h)
  end
end

function toPrevious()
  buttonCooldown = 0
  if previousScene == scene then
    for i = #scenes, 1, -1 do
      if scenes[i] ~= scene then
        goTo = scenes[i]
      end
    end
    previousScene = scene
    scene = goTo
    table.insert(scenes, scene)
    debug:write("----------going back to " .. scene .. "----------\n")
  end
  tempCurrent = scene
  scene = previousScene
  previousScene = tempCurrent
  table.insert(scenes, scene)
  debug:write("----------going back to " .. scene .. "----------\n")
end
function toScene(newScene)
  table.insert(scenes, newScene)
  buttonCooldown = 0
  previousScene = scene
  scene = newScene
  debug:write("----------headed to " .. scene .. "----------\n")
end

function revivePlayers()
  debug:write("players length before revive: " .. #players .. "\n")
  debug:write("dead players length before revive: " .. #deadPlayers .. "\n")
  for i = #deadPlayers, 1, -1 do
    table.insert(players, table.remove(deadPlayers, i))
  end
  debug:write("players length after revive: " .. #players .. "\n")
  debug:write("dead players length after revive: " .. #deadPlayers .. "\n")
  turn = 1
end

function generatePlayers()
  players = nil
  players = {}

  for i = 1, num_players, 1 do    -- make players
    local player = {}
    player.w = width/80
    player.h = player.w*2
    player.x = -10
    player.y = -10
    player.rot = 0
    player.red = math.random(200, 800)/1000
    player.green = math.random(200, 800)/1000
    player.blue = math.random(200, 800)/1000
    player.planet = i
    player.score = 0
    player.turn = i
    table.insert(players, player)
  end
end

function generateWorld()
  random_color.r = math.random(300, 700)/1000    -- making a random color which will be the color of the planets
  random_color.g = math.random(300, 700)/1000
  random_color.b = math.random(300, 700)/1000

  num_planets = math.floor(math.random(num_players + 2, num_players + 4))   -- generate 2 to 4 more planets than players

  planets = nil
  planets = {}

  buffer = 50   -- how much room is between the zones
  x_zones = 4   -- how many zones along x-axis
  y_zones = 3   -- how many zones along y-axis
  zones = {}
  zone_width = (width - (buffer * (x_zones - 1)))/x_zones   -- find the width and height of each zone based on the screen size, buffer room, and number of zones
  zone_height = (height - (buffer * (y_zones - 1)))/y_zones

  for x = 0, x_zones - 1, 1 do
    for y = 0, y_zones - 1, 1 do
      local zone = {}
      zone.x = x * (zone_width + buffer)    -- go through each zone and set it x and y coors, and width and height
      zone.y = y * (zone_height + buffer)
      zone.width = zone_width
      zone.height = zone_height
      table.insert(zones, zone)   -- add the new zone to the list of zones
    end   -- make zones
  end

  table.remove(zones, 1)

  avaiable_zones = zones
  for i = 1, num_planets, 1 do    -- make planets
    num = math.random(1, #avaiable_zones)   -- pick a random zone and then take it out of the pool
    picked_zone = avaiable_zones[num]
    table.remove(avaiable_zones, num)

    local planet = {}
    planet.r = math.random(width/25, width/10)    -- make a new planet and place it within that random zone
    planet.x = math.random(picked_zone.x + planet.r, (picked_zone.x + picked_zone.width) - planet.r)
    planet.y = math.random(picked_zone.y + planet.r, (picked_zone.y + picked_zone.height) - planet.r)
    planet.craters = {}
    table.insert(planets, planet)   -- add the planet to the list
  end

  for i = 1, #players, 1 do    -- make players
    if players[i] ~= nil then
      local player = players[i]
      player.x = planets[player.planet].x - player.w/2   -- set player's position to be at top of the i planet
      player.y = planets[player.planet].y - planets[player.planet].r - player.h
      player.rot = -math.pi/2
    end
  end
end

function love.keypressed(key)
  if key == "escape" then
    toScene("pause")
  end
end

function love.mousepressed(x, y, button)
	if button == 1 and scene == "game" then
    if ball.isThrown == false then    -- throw ball is mouse is pressed
      ball.isThrown = true
      ball.x = players[turn].x
      ball.y = players[turn].y
      ball.dx = (love.mouse.getX() - ball.x) * throwing_multiplier    -- add velocity to the ball in the direction of the mouse
      ball.dy = (love.mouse.getY() - ball.y) * throwing_multiplier
    end
  end
end

function distanceBetween(a, b)
  return math.sqrt((a.y - b.y)^2 + (a.x - b.x)^2)   -- distance formula
end

function circleRectCollision(circle, rect)
  resolution = 2

  for i = 0, rect.w, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot - math.pi/2))
    point.y = rect.y + (i * math.sin(rect.rot - math.pi/2))

    if distanceBetween(point, circle) < circle.r then
      return true
    end

    opposite_point = {}
    opposite_point.x = point.x + (rect.h * math.cos(rect.rot + 2*math.pi))
    opposite_point.y = point.y + (rect.h * math.sin(rect.rot + 2*math.pi))

    if distanceBetween(point, circle) < circle.r then
      return true
    end
  end

  for i = 0, rect.h, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot + 2*math.pi))
    point.y = rect.y + (i * math.sin(rect.rot + 2*math.pi))

    if distanceBetween(point, circle) < circle.r then
      return true
    end

    opposite_point = {}
    opposite_point.x = point.x + (rect.h * math.cos(rect.rot - math.pi/2))
    opposite_point.y = point.y + (rect.h * math.sin(rect.rot - math.pi/2))

    if distanceBetween(point, circle) < circle.r then
      return true
    end
  end

  return false
end

function circleRectRotCollision(circle, rect)
  resolution = 2
  local rect_points = {}

  rect.rot = rect.rot + math.pi/2

  for i = 0, rect.w*2, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot + math.pi/2))
    point.y = rect.y + (i * math.sin(rect.rot + math.pi/2))

    table.insert(rect_points, point.x)
    table.insert(rect_points, point.y)

    opposite_point = {}
    opposite_point.x = point.x + (rect.h/2 * math.cos(rect.rot + 2*math.pi))
    opposite_point.y = point.y + (rect.h/2 * math.sin(rect.rot + 2*math.pi))

    table.insert(rect_points, opposite_point.x)
    table.insert(rect_points, opposite_point.y)
  end

  for i = 0, rect.h/2, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot - 2*math.pi))
    point.y = rect.y + (i * math.sin(rect.rot - 2*math.pi))

    table.insert(rect_points, point.x)
    table.insert(rect_points, point.y)

    opposite_point = {}
    opposite_point.x = point.x + (rect.h * math.cos(rect.rot + math.pi/2))
    opposite_point.y = point.y + (rect.h * math.sin(rect.rot + math.pi/2))

    table.insert(rect_points, opposite_point.x)
    table.insert(rect_points, opposite_point.y)
  end

  for i = 1, #rect_points, 2 do
    local point = {}
    point.x = rect_points[i]
    point.y = rect_points[i+1]
    if distanceBetween(point, circle) < circle.r then
      rect.rot = rect.rot - math.pi/2
      return true
    end
  end
  rect.rot = rect.rot - math.pi/2
  return false
end

function drawCollisionPoints(points_table, circle, rect)
  resolution = 2

  rect.rot = rect.rot + math.pi/2

  for theta = 0, 2*math.pi, math.pi/96 do
    x = circle.x + (circle.r * math.cos(theta))
    y = circle.y + (circle.r * math.sin(theta))
    table.insert(points_table, x)
    table.insert(points_table, y)
  end

  for i = 0, rect.w*2, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot + math.pi/2))
    point.y = rect.y + (i * math.sin(rect.rot + math.pi/2))

    table.insert(points_table, point.x)
    table.insert(points_table, point.y)

    opposite_point = {}
    opposite_point.x = point.x + (rect.h/2 * math.cos(rect.rot + 2*math.pi))
    opposite_point.y = point.y + (rect.h/2 * math.sin(rect.rot + 2*math.pi))

    table.insert(points_table, opposite_point.x)
    table.insert(points_table, opposite_point.y)
  end

  for i = 0, rect.h/2, resolution do
    local point = {}
    point.x = rect.x + (i * math.cos(rect.rot - 2*math.pi))
    point.y = rect.y + (i * math.sin(rect.rot - 2*math.pi))

    table.insert(points_table, point.x)
    table.insert(points_table, point.y)

    opposite_point = {}
    opposite_point.x = point.x + (rect.h * math.cos(rect.rot + math.pi/2))
    opposite_point.y = point.y + (rect.h * math.sin(rect.rot + math.pi/2))

    table.insert(points_table, opposite_point.x)
    table.insert(points_table, opposite_point.y)
  end

  rect.rot = rect.rot - math.pi/2
  return points_table
end

function explode(x, y, min_particles, max_particles, min_size, max_size, min_vel, max_vel, red, green, blue, color_range)
  num_particles = math.random(min_particles, max_particles)   -- make 10 - 15 explosion clouds with random values
  for i = 1, num_particles, 1 do
    local explosion = {}
    explosion.x = x
    explosion.y = y
    explosion.r = math.random(min_size, max_size)
    explosion.red = math.random(red - color_range, red + color_range)/1000   -- color should be close to red
    explosion.green = math.random(green - color_range, green + color_range)/1000
    explosion.blue = math.random(blue - color_range, blue + color_range)/1000
    explosion.dx = math.random(min_vel, max_vel)/100
    explosion.dy = math.random(min_vel, max_vel)/100
    table.insert(explosions, explosion)
  end
end

function angleBetween(a, b)   -- find the angle between two shapes
  x_diff = a.x - b.x
  y_diff = a.y - b.y

  angle = math.atan(y_diff/x_diff)
  if x_diff < 0 and y_diff < 0 then
    return angle + math.pi
  elseif x_diff < 0 then
    return angle - math.pi
  end
end
