-- It begins.

-- Strip down my other game and make it work in one lua script.
-- Also clean the formatting.

function love.load()
    --
end

function love.update(dt)
    -- Time Manipulation
    time = dt

    -- Virtual Camera Update
    virtualCameraUpdate(time)

    -- Player Update
    playerMovement(time)

    -- Enemies Update
    enemiesUpdate(time)

    -- Bullets Update
    bulletsUpdate(time)
end

function love.draw()
    --
end

function virtualCameraUpdate(dt)
    --
end

function playerMovement(dt)
    --
end

function enemiesUpdate(dt)
    --
end

function bulletsUpdate(dt)
    --
end