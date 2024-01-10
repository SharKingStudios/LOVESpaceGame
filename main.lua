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

function love.load() -- Runs once at the start of the game.
    -- Load the font
    -- font = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 100) -- The font (Commented out because I forgot to add it lol)
    -- font1 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 50)
    -- font2 = love.graphics.newFont("fonts/VCR_OSD_MONO.ttf", 25)
    -- love.graphics.setFont(font)

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
    -- Check for song beats
    beatUpdate()

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

    beatIncrease = 0
end

function love.draw() -- Draws every frame / Runs directly after love.update()
    --
end

-- High Level Functions

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

function loadObject()
    --
end

function loadMapObject()
    --
end

function virtualCameraUpdate(dt)
    --
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
    --
end

-- Low Level Functions

