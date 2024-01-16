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

-- GAME DATA

local fps = 0
local smoothing = 0.9
local last_time = 0

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
    -- Load the font
    font = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 100) -- The font (Commented out because I forgot to add it lol)
    font1 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 50)
    font2 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 25)
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
    -- Check for song beats (I dont know how to slow down the song, so this runs without any time manipulation)
    beatUpdate(dt)

    -- Time Manipulation
    time = dt

    -- Virtual Camera Update
    virtualCameraUpdate(time)

    -- Player Update
    playerUpdate(time)

    -- Enemies Update
    enemiesUpdate(time)

    -- Bullets Update
    bulletsUpdate(time)

    print(FPSUPDATE(dt))
    beatIncrease = 0
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

end

-- Update Functions

function FPSUPDATE(dt) -- For Debugging. (Made using Bing Copilot)
    local current_time = last_time + dt
    local elapsed_time = current_time - last_time
    last_time = current_time
    fps = (fps * smoothing) + ((1.0 - smoothing) * (1.0 / elapsed_time))
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
end

function enemiesUpdate(dt)
    --
end

function bulletsUpdate(dt)
    --
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
end