g = love.graphics

function love.load()
  width = g.getWidth()    -- get the width and height for future use
  height = g.getHeight()

  myFont = g.newFont(40)    -- making a larger font for the score

  throwing_multiplier = 0.2   -- this will affect the speed of the projectile

  math.randomseed(os.time())    -- seeding random number generation
  random_color = {}
  random_color.r = math.random(300, 700)/1000    -- making a random color which will be the color of the planets
  random_color.g = math.random(300, 700)/1000
  random_color.b = math.random(300, 700)/1000

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
    end
  end

  planets = {}
  num_planets = math.floor(math.random(4, 6))   -- generate between 2 and 4 planets

  avaiable_zones = zones
  for i = 1, num_planets, 1 do
    num = math.random(1, #avaiable_zones)   -- pick a random zone and then take it out of the pool
    picked_zone = avaiable_zones[num]
    table.remove(avaiable_zones, num)

    local planet = {}
    planet.r = math.random(20, 90)    -- make a new planet and place it within that random zone
    planet.x = math.random(picked_zone.x + planet.r, (picked_zone.x + picked_zone.width) - planet.r)
    planet.y = math.random(picked_zone.y + planet.r, (picked_zone.y + picked_zone.height) - planet.r)
    planet.craters = {}
    table.insert(planets, planet)   -- add the planet to the list
  end

  player = {}
  player.w = 10
  player.h = 20
  player.x = planets[1].x -player.w/2   -- set player's position to be at top of the 1st planet
  player.y = planets[1].y - planets[1].r - player.h
  player.rot = -math.pi/2

  player_collision = {}
  player_collision.x = player.x   -- make a circle with an r = half the player's height to act as a collision detector
  player_collision.y = player.y
  player_collision.r = player.h/2

  ball = {}
  ball.x = 0    -- set up the ball's values
  ball.y = 0
  ball.dx = 0
  ball.dy = 0
  ball.r = 5
  ball.isThrown = false

  score = 0
  tempscore = 0
  cooldown_timer = 0

  plants = {}

  particles = {}

  explosions = {}
  explosion_timer = 0
end

function love.update(dt)
  player_collision.x = player.x   -- make sure the player collision cirrcle is at the position of the player
  player_collision.y = player.y

  if player.rot > 2*math.pi then
    player.rot = 0
  end
  temporary_radius = planets[1].r + player.h    -- makes a temporary radius equal to the radius of the planet + the height of the player
  if love.keyboard.isDown("a") then   -- rotate the player counter clockwise around the planet
    if #planets[1].craters == 0 then    -- if there are no craters, just move
      player.rot = player.rot - 2*dt
    else

      move = true   -- start by saying you're able to move

      for i = 1, #planets[1].craters, 1 do    -- go through each crater on the planet
        local crater = planets[1].craters[i]

        new_point = {}
        new_point.x = (planets[1].r * math.cos(player.rot - 2*dt)) + planets[1].x   -- calculate your new coordinate (at left foot of player)
        new_point.y = (planets[1].r * math.sin(player.rot - 2*dt)) + planets[1].y

        if distanceBetween(new_point, crater) < crater.r then   -- check if it's inside the crater
          move = false    -- if it is, set move to false
        end
      end

      if move then    -- if you can still move, move
        player.rot = player.rot - 2*dt
      end
    end

  elseif love.keyboard.isDown("d") then   -- rotate the player clockwise around the planet (same as going counter clockwise)
    if #planets[1].craters == 0 then
      player.rot = player.rot + 2*dt
    else

      move = true

      for i = 1, #planets[1].craters, 1 do
        local crater = planets[1].craters[i]

        new_point = {}
        new_point.x = (planets[1].r * math.cos(player.rot + 2*dt + (4*math.pi/planets[1].r))) + planets[1].x    -- calculates right foot of player if moved
        new_point.y = (planets[1].r * math.sin(player.rot + 2*dt + (4*math.pi/planets[1].r))) + planets[1].y

        if distanceBetween(new_point, crater) < crater.r then
          move = false
        end
      end

      if move then
        player.rot = player.rot + 2*dt
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
  elseif love.keyboard.isDown("r") then   -- reset the ball
    ball.isThrown = false
    score = 0
  end
  player.x = (temporary_radius * math.cos(player.rot)) + planets[1].x   -- move the player around the planet based on its rotation
  player.y = (temporary_radius * math.sin(player.rot)) + planets[1].y

 if ball.isThrown then    -- run when the ball is thrown
    for i = 1, #planets, 1 do
      local planet = planets[i]

      ball.x = ball.x + (ball.dx * dt)    -- add the ball's velocity to the position
      ball.y = ball.y + (ball.dy * dt)

      mass_multiplier = 1000    -- affects gravitational influence
      G = 10    -- gravitational constant

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

      if distanceBetween(ball, planet) < planet.r + ball.r then   -- reset if the ball has hit the planet
        ball.isThrown = false
        cooldown_timer = 0
        explosion_timer = 0
        score = 0

        for i = #particles, 1, -1 do    -- remove particle trail
          table.remove(particles, i)
        end

        num_particles = math.random(10, 15)   -- make 10 - 15 explosion clouds with random values
        for i = 1, num_particles, 1 do
          local explosion = {}
          explosion.x = ball.x
          explosion.y = ball.y
          explosion.r = math.random(10, 15)
          explosion.red = math.random(950, 1000)/1000   -- color should be close to red
          explosion.green = math.random(250, 350)/1000
          explosion.blue = math.random(250, 350)/1000
          explosion.dx = math.random(-100, 100)/100
          explosion.dy = math.random(-100, 100)/100
          table.insert(explosions, explosion)
        end

        local crater = {}
        crater.r = math.random(10, 15)    -- set up a circle for the crater
        crater.x = ball.x
        crater.y = ball.y
        table.insert(planet.craters, crater)    -- add the crater to the planet's list

        local plant = {}
        plant.x = ball.x
        plant.y = ball.y
        plant.w = 2
        plant.h = 5
      end
    end

    if distanceBetween(ball, player_collision) < player_collision.r + ball.r and cooldown_timer > 1 then    -- see if player has caught ball
      ball.isThrown = false
      cooldown_timer = 0

      for i = #particles, 1, -1 do    -- clear the particle trail
        table.remove(particles, i)
      end
    end

    if tempscore == 60 then   -- increase the score by 1 each second
      score = score + 1
      cooldown_timer = cooldown_timer + 1
      tempscore = 0
    else
      tempscore = tempscore + 1
    end

    if tempscore%5 == 0 then    -- add a particle at the current position of the ball every fifth 1/60 of a second
      local particle = {}
      particle.x = ball.x
      particle.y = ball.y
      particle.r = math.random(3, 5)
      particle.dx = math.random(-0.5, 0.5)
      particle.dy = math.random(-0.5, 0.5)
      table.insert(particles, particle)     -- add a particle at the ball's position with some random values
    end
  end

  for i = #particles, 1, -1 do    -- the particle trail
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

  explosion_timer = explosion_timer + 1
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
end

function love.draw()
  g.setBackgroundColor((1 - random_color.r)/2, (1 - random_color.g)/2, (1 - random_color.b)/2)    -- draw the opposite color of the planets as the background

  -- g.setColor(random_color.r, random_color.b, random_color.g)
  -- g.setFont(myFont)
  -- g.print("Score: " .. score)   -- draw the score

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

  g.setColor(1, 0.3, 0.3)
  g.translate(player.x, player.y)
  g.rotate(player.rot + math.pi/2)    -- rotate the player so it's perpendicular to the surface of the planet
  g.translate(-player.x, -player.y)
  g.rectangle("fill", player.x, player.y, player.w, player.h)   -- draw the player
  g.origin()

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
end

function love.mousepressed(x, y, button)
	if button == 1 then
    if ball.isThrown == false then    -- throw ball is mouse is pressed
      ball.isThrown = true
      ball.x = player.x
      ball.y = player.y
      ball.dx = (love.mouse.getX() - ball.x) * throwing_multiplier    -- add velocity to the ball in the direction of the mouse
      ball.dy = (love.mouse.getY() - ball.y) * throwing_multiplier
    end
  end
end

function love.keypressed(k)   -- quit if esc pressed
   if k == 'escape' then
      love.event.quit()
   elseif k == 'p' then
     love.event.quit("restart")
   end
end

function distanceBetween(a, b)
  return math.sqrt((a.y - b.y)^2 + (a.x - b.x)^2)   -- distance formula
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
