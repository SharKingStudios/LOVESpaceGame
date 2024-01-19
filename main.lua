-- It begins.

-- Strip down my other game and make it work in one lua script.
-- Also clean the formatting.

-- Using the Love2D (love2D.org) game engine to create the game.
-- Anything begining in "love" was not created by me and is a function from the Love2D library.

-- Virtual camera setup
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()
local virtualCameraX = 0
local virtualCameraY = 0
local cameraOffsetX = screenWidth / 2
local cameraOffsetY = screenHeight / 2
local playerCameraRelativeX
local playerCameraRelativeY
local cameraSmoothness = 0.5
local cameraShakeX = 0
local cameraShakeY = 0
local darkOffset = 0
local darkCurrent = 0

-- Store the active game objects
local activeObjects = {} -- Excludes the player
local activeStarObjects = {}
local activeSpaceObjects = {}
local bullets = {}
local enemies = {}
local particles = {}
local sources = {} -- Sounds

-- Bullet Stuff
local bulletCooldown = 0.1
local missileCooldown = 0.1
local missileVollyCooldown = 0.5
local missilesToFire = 0

local rocMissileImage = love.graphics.newImage("assets/objects/rocMissile.png")

-- Score
local playerScore = 0

-- Time / beats
local timeFreeze = 0
local songBPM = 136 * 2
local beatDuration = 60 / songBPM
local timeSinceBeat = 0
local beatIncrease = 0
local timeSinceHalfBeat = 0
local beatHalfIncrease = 0

local fps = 0
local smoothing = 0.9
local last_time = 0

-- GAME DATA

local objects = {
  player = {image = "assets/ships/Player_Ship.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 75, health = 50, maxSpeed = 4},
  enemy1 = {image = "assets/ships/Enemy1_Ship.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 85, health = 5, maxSpeed = 1000, maxRotationSpeed = 2, fireCooldown = 2, points = 50},
  enemy2 = {image = "assets/ships/Enemy2_Ship.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 85, health = 7, maxSpeed = 750, maxRotationSpeed = 4, fireCooldown = 8, points = 100},
  enemy3 = {image = "assets/ships/Enemy3_Ship.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 85, health = 7, maxSpeed = 1250, maxRotationSpeed = 5, fireCooldown = 16, points = 150},
  enemy4 = {image = "assets/ships/Enemy4_Ship.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 85, health = 7, maxSpeed = 750, maxRotationSpeed = 1, fireCooldown = 16, points = 200},
  normalBullet = {image = "assets/objects/normalBullet.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 10, health = 7, maxSpeed = 1500, speed = 1500, rotationSpeed = 0, maxRotationSpeed = 0, damage = 1},
  circularBullet = {image = "assets/objects/circularBullet.png", rotateX = 16, rotateY = 16, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 10, health = 7, maxSpeed = 400, speed = 400, rotationSpeed = 4, maxRotationSpeed = 4, damage = 1},
  rocMissile = {image = "assets/objects/rocMissileNoFlame.png", rotateX = 4, rotateY = 18, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 10, health = 7, maxSpeed = 1200, speed = 15, rotationSpeed = 0, maxRotationSpeed = 6, damage = 7},
  enemyMissile = {image = "assets/objects/side_winder.png", rotateX = 4, rotateY = 18, scaleX = 3, scaleY = 3, velocityX = 0, velocityY = 0, radius = 10, health = 7, maxSpeed = 1200, speed = 15, rotationSpeed = 0, maxRotationSpeed = 3, damage = 5},
  -- Space Stuff
  spaceObjects = {x = 0, y = 0, rotation = 0, image = "assets/objects/Space_Objects.png", rotateX = 1500, rotateY = 1500, scaleX = 1, scaleY = 1},
  spaceStars = {x = 0, y = 0, rotation = 0, image = "assets/objects/Space_Stars.png", rotateX = 1500, rotateY = 1500, scaleX = 1, scaleY = 1},
}

function love.load() -- Runs once at the start of the game.
  -- Load window values
  love.window.setMode(1280, 720) -- Set to 1920 x 1080 on launch
  love.window.setTitle("Hi CollegeBoard.")
  love.window.setFullscreen(true)

  -- Reseed RNG
  love.math.setRandomSeed(os.time())

  -- Load the font
  font = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 100) -- The font (Got it from the interwebs)
  font1 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 50) -- Smaller Font
  font2 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 25) -- Even Smaller Font
  love.graphics.setFont(font)

  -- Load reused sounds
  bulletFireSound = love.audio.newSource("assets/sounds/sfx/sfx_wpn_laser7.wav", "static")
  missileAmbient = love.audio.newSource("assets/sounds/sfx/sfx_exp_short_soft6.wav", "static")

  -- Reset object containers
  activeObjects = {} -- Excludes the player
  activeStarObjects = {}
  activeSpaceObjects = {}
  bullets = {}
  enemies = {}
  particles = {}
  sources = {}

  -- Reset time
  timeFreeze = 0

  -- Load the player object
  player = loadObject("player", 0, 0, 0, 3, 3)
  player.image:setFilter("nearest", "nearest")

  -- Load space objects
  spaceObjects = loadMapObject("spaceObjects", 0, 0, 0, 3, 3)
  table.insert(activeSpaceObjects, spaceObjects)

  -- Load space stars
  spaceStars = loadMapObject("spaceStars", 0, 0, 0, 3, 3)
  table.insert(activeStarObjects, {x = (spaceStars.x), y = (spaceStars.y), width = spaceStars.width, height = spaceStars.height, scaleX = spaceStars.scaleX, scaleY = spaceStars.scaleY})

  spaceObjects.image:setFilter("nearest", "nearest")
  spaceStars.image:setFilter("nearest", "nearest")

  -- Start some music (So I can hear something...)
  bgrMusic = love.audio.newSource("assets/sounds/music/Digital_Slash.mp3", "static")
  bgrMusic:setLooping(true)
  bgrMusic:play()

  beatDuration = 60 / songBPM -- NOTE: Change this wherever I change the song.
end

function love.update(dt) -- Runs every frame.
  -- Check for song beats (I dont know how to slow down the song, so this must run without any time manipulation)
  beatUpdate(dt)

  -- Time Manipulation
  time = dt

  -- Virtual Camera Update
  virtualCameraUpdate(time)

  -- Bullets Update
  bulletsUpdate(time)

  -- Player Update
  playerUpdate(time)

  -- Enemies Update
  enemiesUpdate(time) -- Not Implemented

  fpsValue = FPSUPDATE(dt)

  beatIncrease = 0
  love.audio.update()
end

function love.draw() -- Draws every frame / Runs directly after love.update()
  love.graphics.setColor(1 - darkCurrent, 1 - darkCurrent, 1 - darkCurrent, 1)

  -- Draw the Map  
  drawMap()

  -- Draw the Bullets
  drawBullets()

  -- Draw the Ships
  drawShips()

  -- Draw the GUI
  drawGUI()

  -- Controls the Spawning of Enemies
  enemySpawner()
end

-- Update Functions

function FPSUPDATE(dt) -- For Debugging. (Made using Bing Copilot)
  local current_time = last_time + dt
  local elapsed_time = current_time - last_time
  last_time = current_time
  fps = (fps * smoothing) + ((1.0 - smoothing) * (1.0 / elapsed_time))
  fps = math.floor(fps * 100) / 100
  return fps
end

function beatUpdate(dt)
  -- Calculate the beats of the song.
  timeSinceBeat = timeSinceBeat + dt
  timeSinceHalfBeat = timeSinceHalfBeat + dt

  -- Check if a beat has passed
  if timeSinceBeat >= beatDuration then
    -- Reset the time since the last beat
    timeSinceBeat = timeSinceBeat - beatDuration
    beatIncrease = 1
  end
  -- Half beat
  if timeSinceHalfBeat >= (beatDuration / 2) then
    -- Reset the time since the last beat
    timeSinceHalfBeat = timeSinceHalfBeat - (beatDuration / 2)
    beatHalfIncrease = 1
  end
end

function virtualCameraUpdate(dt) -- Virtual Camera calculations
  -- Recalculate the center of the screen in case it changed
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()
  cameraOffsetX = screenWidth / 2
  cameraOffsetY = screenHeight / 2

  -- Calculate the player relative to the camera
  playerCameraRelativeX = player.x - virtualCameraX + cameraOffsetX
  playerCameraRelativeY = player.y - virtualCameraY + cameraOffsetY

  -- Calculate the player relative to the map
  playerMapRelativeX = player.x + playerCameraRelativeX
  playerMapRelativeY = player.y + playerCameraRelativeY
  
  -- Change the virtual cameras position
  virtualCameraX = virtualCameraX + ((player.x - virtualCameraX) * cameraSmoothness)
  virtualCameraY = virtualCameraY + ((player.y - virtualCameraY) * cameraSmoothness)

  -- Run camera shake after camera positioning as to not get overwritten.
  if boosting == true then
    cameraShake(1)
  end
end

function playerUpdate(dt)
  -- Move the Player
  playerMovement(dt)

  -- Handle player shooting
  playerBulletFire(dt)

  -- Check for Damage
  playerCheckDamage(dt)
end

function enemiesUpdate(dt)
  -- Update enemies
  for e, enemy in ipairs(enemies) do
    enemy.image:setFilter("nearest", "nearest")
    -- Calculate the angle to the player
    local angleToPlayer = math.atan2(player.y - enemy.y, player.x - enemy.x) + math.pi/2
  
    -- Adjust the rotation speed to turn towards the player
    local angleDifference = angleToPlayer - enemy.rotation
    angleDifference = (angleDifference - math.pi) % (2 * math.pi) - math.pi
    
    -- print(angleDifference*57.2958)

    local rotationDir = 1
    if angleDifference < 0 then
      rotationDir = -1
    end
  
    -- Apply rotation speed with a maximum turning speed
    if enemy.type == "enemy1" then
      enemy.rotationSpeed = rotationDir * math.min(math.abs(angleDifference * (enemy.maxSpeed/20)), enemy.maxRotationSpeed) -- Dives at the player
    elseif enemy.type == "enemy2" or enemy.type == "enemy4" then
      enemy.rotationSpeed = rotationDir * math.min(math.abs(angleDifference), enemy.maxRotationSpeed) -- Circles around the player
    end
  
    -- print(enemy.rotationSpeed*57.2958) -- Converted to degrees
    -- Update the enemy's rotation and apply speed
    enemy.rotation = enemy.rotation + enemy.rotationSpeed * dt
    enemy.speed = enemy.maxSpeed -- Adjust later
  
    -- Update the position based on the enemy's speed and rotation
    local displacementX = calculateDisplacementX(enemy.rotation - (math.pi / 2), enemy.speed * dt)
    local displacementY = calculateDisplacementY(enemy.rotation - (math.pi / 2), enemy.speed * dt)
    enemy.x = enemy.x + displacementX
    enemy.y = enemy.y + displacementY

    -- Check for collisions with bullet objects
    for i, bullet in ipairs(bullets) do
      if checkCircleCollision(enemy, bullet) and bullet.origin == "player" then
        enemy.health = enemy.health - bullet.damage
        table.remove(bullets, i)
        love.audio.play("assets/sounds/sfx/sfx_damage_hit2.wav", "stream")
        cameraShake(5)
      end
    end
    -- Check if the enemy is dead
    if enemy.health <= 0 then
      table.remove(enemies, e)
      love.audio.play("assets/sounds/sfx/sfx_exp_short_hard15.wav", "stream")
      cameraShake(20)
      playerScore = playerScore + enemy.points
    end

    -- Check firing cooldown
    if beatIncrease == 1 then
      enemy.fireTimer = enemy.fireTimer + 1
      -- print(beatIncrease)
    end

    enemy.fireTimer = math.max(0, enemy.fireTimer)
    if enemy.fireTimer >= enemy.fireCooldown then
      -- Fire bullets
      if enemy.type == "enemy1" then
        clampedRotation = (enemy.rotation - math.pi) % (2 * math.pi) - math.pi
        local fireAngle = math.max((clampedRotation - math.pi/6), math.min((clampedRotation + math.pi/6), angleToPlayer))
        -- print(clampedRotation - fireAngle)
        local bullet = loadBullet("normalBullet", enemy.x, enemy.y, displacementX/2, displacementY/2, fireAngle, 1, 1, "enemy")
        bullet.image:setFilter("nearest", "nearest")
        bullet.alpha = 1
        table.insert(bullets, bullet)
        -- enemyDistanceToPlayer = findDistance(player, enemy)
        love.audio.play("assets/sounds/sfx/sfx_wpn_laser8.wav", "stream")
      elseif enemy.type == "enemy2" then
        for a = 1, 6 do
          local bullet = loadBullet("circularBullet", enemy.x, enemy.y, displacementX/10, displacementY/10, (enemy.rotation + (math.pi/3) * a), 2, 2, "enemy")
          bullet.image:setFilter("nearest", "nearest")
          bullet.alpha = 1
          table.insert(bullets, bullet)
        end
        love.audio.play("assets/sounds/sfx/sfx_wpn_laser3.wav", "stream")
      elseif enemy.type == "enemy4" then
        local bullet = loadBullet("enemyMissile", enemy.x, enemy.y, displacementX/2, displacementY/2, enemy.rotation, 2, 2, "enemy")
        bullet.image:setFilter("nearest", "nearest")
        bullet.alpha = 1
        table.insert(bullets, bullet) -- (Needs to be balanced / Way to OP)
        love.audio.play("assets/sounds/sfx/sfx_wpn_laser8.wav", "stream")
      end
      
      -- Reset the firing cooldown
      enemy.fireTimer = 0
    end
  end
end

function bulletsUpdate(dt)
  -- Update bullets
  for i, bullet in ipairs(bullets) do
    bullet.lifeTimer = bullet.lifeTimer + dt
    if bullet.type == "normalBullet" or bullet.type == "circularBullet" then
      bullet.x = bullet.x + calculateDisplacementX(bullet.initialRotation - (math.pi / 2), bullet.speed * dt) + bullet.velocityX
      bullet.y = bullet.y + calculateDisplacementY(bullet.initialRotation - (math.pi / 2), bullet.speed * dt) + bullet.velocityY
      bullet.rotation = bullet.rotation + bullet.rotationSpeed * dt

      -- Remove bullets after 3 seconds
      if bullet.timer == nil then
        bullet.timer = 3
      else
        bullet.timer = bullet.timer - dt
        if bullet.timer <= 0 then
          table.remove(bullets, i)
        end
      end
      bullet.alpha = -1 * math.pow(100, -bullet.timer) + 1 -- Took me a while to figure out math.pow
    elseif bullet.type == "rocMissile" or bullet.type == "enemyMissile" then
      bullet.velocityX = bullet.velocityX * 0.97
      bullet.velocityY = bullet.velocityY * 0.97

      if bullet.lifeTimer >= 0.5 or bullet.type == "enemyMissile" then
        if bullet.type == "rocMissile" then
          bullet.image = rocMissileImage
        end
        -- Calculate the angle to the closest enemy (If there is one)

        if #enemies >= 1 then
          if bullet.type == "rocMissile" then
            angleToEnemy = math.atan2(enemies[1].y - bullet.y, enemies[1].x - bullet.x) + math.pi/2
          elseif bullet.type == "enemyMissile" then
            angleToEnemy = math.atan2(player.y - bullet.y, player.x - bullet.x) + math.pi/2
          end
          -- Adjust the rotation speed to turn towards the enemy
          local angleDifference = angleToEnemy - bullet.rotation
          angleDifference = (angleDifference - math.pi) % (2 * math.pi) - math.pi
          
          -- print(angleDifference*57.2958)
        
          
          local rotationDir = 1
          if angleDifference < 0 then
            rotationDir = -1
          end
          
          -- Apply rotation speed with a maximum turning speed
          bullet.rotationSpeed = rotationDir * math.min(math.abs(angleDifference * (bullet.maxSpeed/20)), bullet.maxRotationSpeed)
        end
        
        -- Update the enemy's rotation and apply speed
        bullet.rotation = bullet.rotation + bullet.rotationSpeed * dt
        if bullet.speed < bullet.maxSpeed then
          bullet.speed = bullet.speed + (bullet.maxSpeed - bullet.speed) * 0.1
        end
        bullet.soundTimer = bullet.soundTimer - 1 * dt
        if bullet.soundTimer <= 0 then
          missileAmbient:setVolume(0.5)
          missileAmbient:play()
          bullet.soundTimer = 0.05
        end
      end

      local displacementX = calculateDisplacementX(bullet.rotation - (math.pi / 2), bullet.speed * dt) + bullet.velocityX
      local displacementY = calculateDisplacementY(bullet.rotation - (math.pi / 2), bullet.speed * dt) + bullet.velocityY
      bullet.x = bullet.x + displacementX
      bullet.y = bullet.y + displacementY
    end
  end
end

-- Middle Level Functions

function playerMovement(dt)
  -- The speed of the movement in pixels per second
  local speed = 4
  local speedH = 0.5 -- Speed Horizontal
  local boostSpeed = 1
  boosting = false
  -- The speed of the rotation (Note: Player.rotation is in radians)
  local rotation_speed = 0.5
  -- Check which keys are pressed and adjust the position and rotation accordingly
  local displacementX = 0
  local displacementY = 0
  if love.keyboard.isDown("w") then
    player.speed = (player.speed * 0.97) + (speed * dt)
    displacementX = displacementX + calculateDisplacementX(player.rotation - (math.pi / 2), player.speed)
    displacementY = displacementY + calculateDisplacementY(player.rotation - (math.pi / 2), player.speed)
    -- Check if the player is boosting
    if love.keyboard.isDown("lshift") then --and love.keyboard.isDown("w") then
      player.speed = (player.speed * 0.97) + (boostSpeed * dt)
      displacementX = displacementX + calculateDisplacementX(player.rotation - (math.pi / 2), player.speed)
      displacementY = displacementY + calculateDisplacementY(player.rotation - (math.pi / 2), player.speed)
      boosting = true
    end
  end
  if love.keyboard.isDown("q") then
    player.speedH = (player.speedH * 0.99) + (speedH * dt)
    displacementX = displacementX + calculateDisplacementX(player.rotation + math.pi, player.speedH)
    displacementY = displacementY + calculateDisplacementY(player.rotation + math.pi, player.speedH)
  end
  if love.keyboard.isDown("s") then
    player.speed = (player.speed * 0.97) - ((speed/2) * dt)
    displacementX = displacementX + calculateDisplacementX(player.rotation - (math.pi / 2), player.speed)
    displacementY = displacementY + calculateDisplacementY(player.rotation - (math.pi / 2), player.speed)
  end
  if love.keyboard.isDown("e") then
    player.speedH = (player.speedH * 0.99) + (speedH * dt)
    displacementX = displacementX + calculateDisplacementX(player.rotation, player.speedH)
    displacementY = displacementY + calculateDisplacementY(player.rotation, player.speedH)
  end
  if love.keyboard.isDown("a") then
    player.rotationSpeed = player.rotationSpeed - rotation_speed * dt
  end
  if love.keyboard.isDown("d") then
    player.rotationSpeed = player.rotationSpeed + rotation_speed * dt
  end
  
  -- Decrease the player values a little bit.
  player.speed = player.speed * 0.97
  player.speedH = player.speedH * 0.99
  player.velocityX = player.velocityX * 0.97
  player.velocityY = player.velocityY * 0.97
  player.rotationSpeed = player.rotationSpeed * 0.9

  -- Recalculate the players position
  player.velocityX = player.velocityX + displacementX
  player.velocityY = player.velocityY + displacementY
  player.x = player.x + player.velocityX
  player.y = player.y + player.velocityY
  player.rotation = player.rotation + player.rotationSpeed
end

-- Camera Shake
function cameraShake(strength)
  cameraShakeX = love.math.random(-strength, strength)
  cameraShakeY = love.math.random(-strength, strength)
  virtualCameraX = virtualCameraX + cameraShakeX
  virtualCameraY = virtualCameraY + cameraShakeY
end

-- Loading Functions

function loadObject(objectName, x, y, rotation, scaleX, scaleY)
  local object = {
    x = x,
    y = y,
    rotation = rotation,
    rotateX = objects[objectName].rotateX,
    rotateY = objects[objectName].rotateY,
    scaleX = scaleX,
    scaleY = scaleY,
    velocityX = 0,
    velocityY = 0,
    speed = 0,
    speedH = 0,
    maxSpeed = objects[objectName].maxSpeed,
    rotationSpeed = 0,
    radius = objects[objectName].radius,
    health = objects[objectName].health,
    image = love.graphics.newImage(objects[objectName].image)
  }
  return object
end

function loadMapObject(objectName, x, y, rotation, scaleX, scaleY)
  local object = {
    x = x,
    y = y,
    rotation = rotation,
    rotateX = objects[objectName].rotateX,
    rotateY = objects[objectName].rotateY,
    scaleX = scaleX,
    scaleY = scaleY,
    width = 3000,
    height = 3000,
    image = love.graphics.newImage(objects[objectName].image)
  }
  return object
end

function loadBullet(type, x, y, velocityX, velocityY, rotation, scaleX, scaleY, origin)
  local bullet = {
    x = x,
    y = y,
    velocityX = velocityX,
    velocityY = velocityY,
    rotation = rotation,
    initialRotation = rotation,
    scaleX = scaleX,
    scaleY = scaleY,
    speed = objects[type].speed,
    maxSpeed = objects[type].maxSpeed,
    damage = objects[type].damage,
    origin = origin,
    rotationSpeed = objects[type].rotationSpeed,
    maxRotationSpeed = objects[type].maxRotationSpeed,
    health = objects[type].health,
    radius = objects[type].radius,
    soundTimer = 0,
    lifeTimer = 0,
    type = type,
    image = love.graphics.newImage(objects[type].image)
  }
  return bullet
end

function loadEnemy(type, x, y, rotation, scaleX, scaleY) -- maxSpeed, maxRotationSpeed, fireCooldown)
  local enemy = {
    x = x,
    y = y,
    rotation = rotation,
    scaleX = scaleX,
    scaleY = scaleY,
    speed = 0,
    maxSpeed = objects[type].maxSpeed,
    rotationSpeed = 0,
    maxRotationSpeed = objects[type].maxRotationSpeed,
    fireCooldown = objects[type].fireCooldown,
    fireTimer = 0,
    health = objects[type].health,
    radius = objects[type].radius,
    points = objects[type].points,
    type = type,
    image = love.graphics.newImage(objects[type].image)
  }  
  return enemy
end

-- Angle displacement calculations (Thanks Mr. Bing Chat.)
function calculateDisplacementX(angle, speed)
  -- Calculates the x displacement using the Pythagorean theorem
  local xDisplacement = speed * math.cos(angle)

  return xDisplacement
end
function calculateDisplacementY(angle, speed)
  -- Calculates the y displacement using the Pythagorean theorem
  local yDisplacement = speed * math.sin(angle)

  return yDisplacement
end

function drawMap()
  for i, starObject in ipairs(activeStarObjects) do
    love.graphics.draw(spaceStars.image, ((virtualCameraX*-.5) + starObject.x), ((virtualCameraY*-.5) + starObject.y), spaceStars.rotation, spaceStars.scaleX, spaceStars.scaleY, spaceStars.rotateX, spaceStars.rotateY)
  end

  love.graphics.draw(spaceObjects.image, (virtualCameraX*-1), (virtualCameraY*-1), spaceObjects.rotation, spaceObjects.scaleX, spaceObjects.scaleY, spaceObjects.rotateX, spaceObjects.rotateY)
end

function drawBullets()
  for _, bullet in ipairs(bullets) do
    love.graphics.setColor(1 - darkCurrent, 1 - darkCurrent, 1 - darkCurrent, bullet.alpha)
    love.graphics.draw(bullet.image, bullet.x - virtualCameraX + cameraOffsetX, bullet.y - virtualCameraY + cameraOffsetY, (bullet.rotation - math.pi/2), bullet.scaleX, bullet.scaleY, (bullet.image:getWidth() / 2), (bullet.image:getHeight() / 2))
    love.graphics.setColor(1 - darkCurrent, 1 - darkCurrent, 1 - darkCurrent, 1)
  end
end

function drawShips()
  for _, enemy in ipairs(enemies) do
    love.graphics.draw(enemy.image, enemy.x - virtualCameraX + cameraOffsetX, enemy.y - virtualCameraY + cameraOffsetY, enemy.rotation, enemy.scaleX, enemy.scaleY, enemy.image:getWidth() / 2, enemy.image:getHeight() / 2)
  end

  -- Draw the Player
  love.graphics.draw(player.image, playerCameraRelativeX, playerCameraRelativeY, player.rotation, player.scaleX, player.scaleY, player.rotateX, player.rotateY)
end

function drawGUI()
  love.graphics.print(playerScore, 10 + cameraShakeX, 10 + cameraShakeY, 0)
  love.graphics.print(player.health, 10 + cameraShakeX, screenHeight - 110 + cameraShakeY, 0)
  love.graphics.print(fpsValue, 10 + cameraShakeX, screenHeight - 220 + cameraShakeY, 0)
end

function playerBulletFire(dt)
  -- Bullet firing logic
  bulletCooldown = math.max(0, bulletCooldown - dt)
  missileCooldown = math.max(0, missileCooldown - dt)
  missileVollyCooldown = math.max(0, missileVollyCooldown - dt)
  if love.keyboard.isDown("space") and bulletCooldown == 0 then
    local bullet = loadBullet("normalBullet", player.x, player.y, player.velocityX, player.velocityY, player.rotation, 1, 1, "player")
    bullet.image:setFilter("nearest", "nearest")
    bullet.alpha = 1
    table.insert(bullets, bullet)
    love.audio.play("assets/sounds/sfx/sfx_wpn_laser7.wav", "stream")
    bulletCooldown = 0.1 -- Reset the cooldown
  end
  -- Missile firing logic
  if love.keyboard.isDown("f") and missileVollyCooldown == 0 then
    missilesToFire = 3
    missileVollyCooldown = 0.5 -- Reset the cooldown
  end
  if missilesToFire > 0 and missileCooldown == 0 and beatHalfIncrease == 1 then
    if (missilesToFire % 2) == 0 then
      bullet = loadBullet("rocMissile", player.x, player.y, player.velocityX + calculateDisplacementX(player.rotation, 25), player.velocityY + calculateDisplacementY(player.rotation, 25), player.rotation, 3, 3, "player")
    elseif (missilesToFire % 2) == 1 then
      bullet = loadBullet("rocMissile", player.x, player.y, player.velocityX + calculateDisplacementX((player.rotation + math.pi), 25), player.velocityY + calculateDisplacementY((player.rotation + math.pi), 25), player.rotation, 3, 3, "player")
    end
    bullet.image:setFilter("nearest", "nearest")
    bullet.alpha = 1
    table.insert(bullets, bullet)
    love.audio.play("assets/sounds/sfx/sfx_exp_medium3.wav", "stream")
    missilesToFire = missilesToFire - 1
    missileCooldown = 0.1
  end
end

-- Circular collision detection using pythagorean theorem
function checkCircleCollision(object1, object2)
  return findDistance(object1, object2) < object1.radius + object2.radius
end

function findDistance(object1, object2)
  local dx = object2.x - object1.x
  local dy = object2.y - object1.y
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance
end

-- A simple sound manager. Not made by me. Found on the Love2D open documentation.
-- Sound Manager Found on: https://love2d.org/wiki/Minimalist_Sound_Manager
do
  -- will hold the currently playing sources
  local sources = {}

  -- check for sources that finished playing and remove them
  -- add to love.update
  function love.audio.update()
      -- local remove = {} isStopped() does not work / not sure why...
      -- for _, s in pairs(sources) do
      --     if s:isStopped() then
      --         remove[#remove + 1] = s
      --     end
      -- end

      -- for i, s in ipairs(remove) do
      --     sources[s] = nil
      -- end
  end

  -- overwrite love.audio.play to create and register source if needed
  local play = love.audio.play
  function love.audio.play(what, how, loop)
      local src = what
      if type(what) ~= "userdata" or not what:typeOf("Source") then
          src = love.audio.newSource(what, how)
          src:setLooping(loop or false)
      end

      play(src)
      sources[src] = src
      return src
  end

  -- stops a source
  local stop = love.audio.stop
  function love.audio.stop(src)
      if not src then return end
      stop(src)
      sources[src] = nil
  end
end

function enemySpawner()
  -- Add new enemies if there are none
  if #enemies == 0 then
    for i=1, 100 do
      -- table.insert(enemies, loadEnemy("enemy1", (player.x + love.math.random(-1000, 1000)), (player.y + love.math.random(-1000, 1000)), 0, 3, 3))
      -- table.insert(enemies, loadEnemy("enemy1", (player.x + love.math.random(-1000, 1000)), (player.y + love.math.random(-1000, 1000)), 0, 3, 3))
      table.insert(enemies, loadEnemy("enemy2", (player.x + love.math.random(-1000, 1000)), (player.y + love.math.random(-1000, 1000)), 0, 3, 3))
      -- table.insert(enemies, loadEnemy("enemy4", (player.x + love.math.random(-1000, 1000)), (player.y + love.math.random(-1000, 1000)), 0, 3, 3))
    end
  end
end

function playerCheckDamage()
  -- Check player collisions
  for i, bullet in ipairs(bullets) do
    if checkCircleCollision(player, bullet) and bullet.origin == "enemy" then
      player.health = player.health - bullet.damage
      table.remove(bullets, i)
      love.audio.play("assets/sounds/sfx/sfx_damage_hit10.wav", "stream")
      cameraShake(10)
    end
  end

  -- Check if the player is dead
  if player.health <= 0 then
    player = loadObject("player", 0, 0, 0, 3, 3)
    player.image:setFilter("nearest", "nearest")
    love.audio.play("assets/sounds/sfx/sfx_damage_hit10.wav", "stream") -- Change this sound
    cameraShake(20)
  end
end