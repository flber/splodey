g = love.graphics

function love.load()
  width = g.getWidth()    -- get the width and height for future use
  height = g.getHeight()

  myFont = g.newFont(40)    -- making a larger font for the score

  throwing_multiplier = 0.2   -- this will affect the speed of the projectile

  num_players = 6

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
  num_planets = math.floor(math.random(num_players + 2, num_players + 4))   -- generate 2 to 4 more planets than players

  avaiable_zones = zones
  for i = 1, num_planets, 1 do    -- make planets
    num = math.random(1, #avaiable_zones)   -- pick a random zone and then take it out of the pool
    picked_zone = avaiable_zones[num]
    table.remove(avaiable_zones, num)

    local planet = {}
    planet.r = math.random(30, 70)    -- make a new planet and place it within that random zone
    planet.x = math.random(picked_zone.x + planet.r, (picked_zone.x + picked_zone.width) - planet.r)
    planet.y = math.random(picked_zone.y + planet.r, (picked_zone.y + picked_zone.height) - planet.r)
    planet.craters = {}
    table.insert(planets, planet)   -- add the planet to the list
  end

  players = {}
  for i = 1, num_players, 1 do    -- make players
    local player = {}
    player.w = 10
    player.h = 20
    player.x = planets[i].x -player.w/2   -- set player's position to be at top of the i planet
    player.y = planets[i].y - planets[i].r - player.h
    player.rot = -math.pi/2
    player.red = math.random(200, 800)/1000
    player.green = math.random(200, 800)/1000
    player.blue = math.random(200, 800)/1000
    player.planet = i
    table.insert(players, player)
  end

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

  turn = 1

  hit = false
end

function love.update(dt)
  if turn > #players then
    turn = 1
  end
  if #players == 0 then
    love.event.quit("restart")
  end
  local player = players[turn]

  for i = 1, #planets, 1 do
    local craters = planets[i].craters
    if #craters > 0 then
      for j = 1, #craters, 1 do
        local crater = craters[j]
        for k = 1, #players, 1 do
          local player = players[k]
          if player ~= nil and circleRectRotCollision(crater, player) then
            explode(ball.x, ball.y, 7, 10, 100, 150, -100, 100, player.red, player.green, player.blue, 50)
            table.remove(players, i)
            ball.isThrown = false
            score = 0
            cooldown_timer = 0
            turn = turn + 1
            hit = true
          end
        end
      end
    end
  end

  if turn > #players then
    turn = 1
  end
  if #players == 0 then
    love.event.quit("restart")
  end

  for i = 1, #players, 1 do
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

        if distanceBetween(new_point, crater) < crater.r then   -- check if it's inside the crater
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

        if distanceBetween(new_point, crater) < crater.r then
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

    for i = #players, 1, -1 do
      local player = players[i]

      temp_r = ball.r
      ball.r = ball.r + 5
      if circleRectRotCollision(ball, player) and cooldown_timer > 3 then
        explode(ball.x, ball.y, 7, 10, 100, 150, -100, 100, player.red, player.green, player.blue, 50)
        table.remove(players, i)
        ball.isThrown = false
        score = 0
        cooldown_timer = 0
        turn = turn + 1
        hit = true

        if turn > #players then
          turn = 1
        end
        if #players == 0 then
          love.event.quit("restart")
        end
      end
      ball.r = temp_r
    end

    for i = 1, #planets, 1 do
      local planet = planets[i]

      if true then    -- acceleration stuff
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
      end

      if distanceBetween(ball, planet) < planet.r + ball.r then   -- reset if the ball has hit the planet
        ball.isThrown = false
        cooldown_timer = 0
        explosion_timer = 0
        score = 0
        turn = turn + 1

        local crater = {}
        crater.r = math.random(10, 15)    -- set up a circle for the crater
        crater.x = ball.x
        crater.y = ball.y
        table.insert(planet.craters, crater)    -- add the crater to the planet's list

        for j = #particles, 1, -1 do    -- remove particle trail
          table.remove(particles, j)
        end

        explode(ball.x, ball.y, 7, 10, 10, 15, -100, 100, 950, 400, 400, 50)

        for j = #players, 1, -1 do
          local player = players[j]
          temp_r = crater.r
          crater.r = 20
          if circleRectRotCollision(crater, player) and cooldown_timer > 5 then    -- see if ball has hit player
            explode(ball.x, ball.y, 7, 10, 10, 15, -100, 100, 400, 850, 400, 50)
            table.remove(players, j)
            ball.isThrown = false
            score = 0
            cooldown_timer = 0
            turn = turn + 1
            hit = true

            if turn > #players then
              turn = 1
            end
            if #players == 0 then
              love.event.quit("restart")
            end
          end
          crater.r = temp_r
        end

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
      particle.r = math.random(3, 5)
      particle.dx = math.random(-0.5, 0.5)
      particle.dy = math.random(-0.5, 0.5)
      table.insert(particles, particle)     -- add a particle at the ball's position with some random values
    end

    if score == 5 then    -- remove ball is it's been 5 seconds
      ball.isThrown = false
      score = 0
      turn = turn + 1
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
end

function love.draw()
  g.setBackgroundColor((1 - random_color.r)/2, (1 - random_color.g)/2, (1 - random_color.b)/2)    -- draw the opposite color of the planets as the background

  -- if hit then
  --   g.setColor(0, 0, 0)
  --   g.rectangle("fill", 0, 0, width, height)
  --   -- hit = false
  -- end

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

  for i = 1, #players, 1 do
    local player = players[i]
    g.setColor(player.red, player.green, player.blue)
    g.translate(player.x, player.y)
    g.rotate(player.rot + math.pi/2)    -- rotate the player so it's perpendicular to the surface of the planet
    g.translate(-player.x, -player.y)
    g.rectangle("fill", player.x, player.y, player.w, player.h)   -- draw the player
    g.origin()

    -- local points = {}
    -- g.setColor(0, 0, 0)
    -- g.setPointSize(1)
    -- g.points(drawCollisionPoints(points, player))
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
end

function love.mousepressed(x, y, button)
	if button == 1 then
    if ball.isThrown == false then    -- throw ball is mouse is pressed
      ball.isThrown = true
      ball.x = players[turn].x
      ball.y = players[turn].y
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

function drawCollisionPoints(points_table, rect)
  resolution = 2

  rect.rot = rect.rot + math.pi/2

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
