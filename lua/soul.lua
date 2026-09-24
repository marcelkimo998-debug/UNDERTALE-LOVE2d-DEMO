local soul = {}
local Box = require("lua/box")
local Gameover = require("lua/Gameover")
local stat = require("lua/stat")
local Hp = require("lua/hp")
--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

--------------------------------------------------------------------
-- Battle state watcher
--------------------------------------------------------------------

local function watchState()
    if game.state ~= "overworld" then
    waituntil(
        function() return game.state == "evade" end,
        function()
            soul.x = 322
            soul.y = 315

            waituntil(
                function() return game.state ~= "evade" end,
                function() watchState() end
            )
        end
    )
end
end

--------------------------------------------------------------------
-- Load / init
--------------------------------------------------------------------

function soul.reset() 
    soul.x = 0
    soul.y = 0

    soul.basespeed = 125
    soul.speed = 150

    soul.mode = "red"

    soul.falling = 1
    soul.movement = 0
    soul.jumpheight = 2.6

    soul.stoptimer = 0.016
    soul.stop = 0

    soul.direction = "down"
    soul.indpurp = 0

    soul.damtimer = 0

    soul.invisAlpha = 1
    soul.invisTimer = 0
    soul.invisState = 1

    soul.dirx = 0
    soul.diry = 0

    soul.dash = false
    soul.dashx = 0
    soul.dashy = 0
    soul.dashTimer = 0
    soul.dashCooldown = 0
    soul.dashrotation = 0
    soul.dashSpinDir = 1

    soul.brokentimer = 1.5
    soul.shardtimer = 2.5
end

function soul.load()
    soul.UIfont = love.graphics.newFont("Assets/font/UI.ttf", 24)

    local image = love.graphics.newImage("Assets/sprites/ut-heart.png")
    soul.broken = love.graphics.newImage("Assets/sprites/ut-heart-broken.png")

    soul.image = image
    soul.width = image:getWidth()
    soul.height = image:getHeight()

    shards = {
        [1] = love.graphics.newImage("Assets/sprites/Soulshard/Soulshard1.png"),
        [2] = love.graphics.newImage("Assets/sprites/Soulshard/Soulshard2.png"),
        [3] = love.graphics.newImage("Assets/sprites/Soulshard/Soulshard3.png"),
        [4] = love.graphics.newImage("Assets/sprites/Soulshard/Soulshard4.png")
    }

    soul.reset()
    watchState()
end

--------------------------------------------------------------------
-- Blue mode (gravity / jump)
--------------------------------------------------------------------

local blueDirections = {
    down = {
        jump = "up",
        moveFree = function(dt)
            if love.keyboard.isDown("right") then soul.x = soul.x + soul.speed * dt end
            if love.keyboard.isDown("left") then soul.x = soul.x - soul.speed * dt end
        end,
        moveJump = function(dt)
            soul.y = soul.y - soul.movement * 130 * dt
        end,
        moveFall = function(dt)
            soul.y = soul.y - soul.movement * 100 * dt
        end,
        landed = function(box)
            return soul.y >= box.y + box.h - soul.height + 7
        end,
        snap = function(box)
            soul.y = box.y + box.h - soul.height + 5
        end,
        onWall = function(box)
            return soul.y <= box.y + box.h - soul.height
        end
    },

    up = {
        jump = "down",
        moveFree = function(dt)
            if love.keyboard.isDown("right") then soul.x = soul.x + soul.speed * dt end
            if love.keyboard.isDown("left") then soul.x = soul.x - soul.speed * dt end
        end,
        moveJump = function(dt)
            soul.y = soul.y + soul.movement * 130 * dt
        end,
        moveFall = function(dt)
            soul.y = soul.y + soul.movement * 100 * dt
        end,
        landed = function(box)
            return soul.y <= box.y + 9
        end,
        snap = function(box)
            soul.y = box.y + 9
        end,
        onWall = function(box)
            return soul.y >= box.y
        end
    },

    left = {
        jump = "right",
        moveFree = function(dt)
            if love.keyboard.isDown("down") then soul.y = soul.y + soul.speed * dt end
            if love.keyboard.isDown("up") then soul.y = soul.y - soul.speed * dt end
        end,
        moveJump = function(dt)
            soul.x = soul.x + soul.movement * 130 * dt
        end,
        moveFall = function(dt)
            soul.x = soul.x + soul.movement * 100 * dt
        end,
        landed = function(box)
            return soul.x <= box.x + 9
        end,
        snap = function(box)
            soul.x = box.x + 9
        end,
        onWall = function(box)
            return soul.x >= box.x
        end
    },

    right = {
        jump = "left",
        moveFree = function(dt)
            if love.keyboard.isDown("down") then soul.y = soul.y + soul.speed * dt end
            if love.keyboard.isDown("up") then soul.y = soul.y - soul.speed * dt end
        end,
        moveJump = function(dt)
            soul.x = soul.x - soul.movement * 130 * dt
        end,
        moveFall = function(dt)
            soul.x = soul.x - soul.movement * 100 * dt
        end,
        landed = function(box)
            return soul.x >= box.x + box.w - soul.width + 9
        end,
        snap = function(box)
            soul.x = box.x + box.w - soul.width + 9
        end,
        onWall = function(box)
            return soul.x <= box.x + box.w - soul.width
        end
    }
}

local function updateBlueDirection(dt, box)
    if game.state ~= "evade" then return end

    local data = blueDirections[soul.direction]
    if not data then return end

    data.moveFree(dt)

    local jumpHeld = love.keyboard.isDown(data.jump)

    if jumpHeld then
        if soul.falling ~= 1 and math.abs(soul.stoptimer) == 0 then
            if soul.movement > 0 then
                soul.movement = soul.movement - 5 * dt
                data.moveJump(dt)
            else
                soul.falling = 1
            end
        end
    end

    if soul.falling == 1 then
        soul.movement = soul.movement - 10 * dt
        data.moveFall(dt)
    end

    if data.landed(box) then
        data.snap(box)
        soul.movement = soul.jumpheight
        soul.falling = 0
        soul.stoptimer = 0
        soul.stop = 1
    end

    if data.onWall(box) and jumpHeld and soul.stoptimer < 0 then
        soul.falling = 1
    end

    if data.onWall(box) and not jumpHeld then
        if soul.stoptimer < 0 then
            soul.falling = 1
        end

        if soul.stop == 1 then
            soul.stoptimer = 0.16
            soul.stop = 0
        end

        if soul.falling ~= 1 then
            soul.movement = 0.15
        else
            soul.stop = 0
        end
    end
end

--------------------------------------------------------------------
-- Orange mode (trail afterimage)
--------------------------------------------------------------------

local Orsoul = {}
local orangeWaiting = false

local function aniOrange(dt)
    if soul.mode ~= "orange" or game.state ~= "evade" then
        orangeWaiting = false
        return
    end

    if not orangeWaiting then
        orangeWaiting = true

        local x = soul.x
        local y = soul.y

        wait(0.1, function()
            table.insert(Orsoul, {
                x = x,
                y = y,
                Alpha = 1
            })

            orangeWaiting = false
        end)
    end
end

local function updOrange(dt)
    if soul.mode == "orange" and game.state == "evade" then
        soul.x = soul.x + soul.dirx * dt
        soul.y = soul.y + soul.diry * dt
    end
end

local function movOrange(dt)
    if soul.mode ~= "orange" then
        return
    end

    local dx, dy = 0, 0

    if love.keyboard.isDown("left") then
        dx = -soul.speed
    elseif love.keyboard.isDown("right") then
        dx = soul.speed
    end

    if love.keyboard.isDown("up") then
        dy = -soul.speed
    elseif love.keyboard.isDown("down") then
        dy = soul.speed
    end

    -- Only update if at least one key is pressed.
    if game.state == "evade" then
    if dx ~= 0 or dy ~= 0 then
        soul.dirx = dx
        soul.diry = dy
    end
    else
        soul.diry = 0 
        soul.dirx = 0
    end
end

local function deleOrange(dt)
    for i = #Orsoul, 1, -1 do
        Orsoul[i].Alpha = Orsoul[i].Alpha - 2 * dt

        if Orsoul[i].Alpha <= 0 then
            table.remove(Orsoul, i)
        elseif game.state ~= "evade" then
            table.remove(Orsoul, i)
        end
    end
end

--------------------------------------------------------------------
-- Cyan mode (trail afterimage)
--------------------------------------------------------------------
local DASH_SPEED = 100
local DASH_TIME = 0.20
local DASH_COOLDOWN = 0.7

-- Initialize somewhere
-- soul.dash = false
-- soul.dashTimer = 0
-- soul.dashCooldown = 0
-- soul.dashx = 0
-- soul.dashy = 0

local function cyanUp(dt)
    if game.state == "evade" and soul.mode == "cyan" then
    -- Cooldown countdown
    if soul.dashCooldown > 0 then
        soul.dashCooldown = soul.dashCooldown - dt
    end

    -- Dash movement
    if soul.dash then
        soul.x = soul.x + soul.dashx * DASH_SPEED / DASH_TIME * dt
        soul.y = soul.y + soul.dashy * DASH_SPEED / DASH_TIME * dt

        soul.dashrotation = soul.dashrotation
        + soul.dashSpinDir * math.rad(360 / DASH_TIME) * dt

        soul.dashTimer = soul.dashTimer - dt

        if soul.dashTimer <= 0 then
            soul.dash = false
            soul.dashx = 0
            soul.dashy = 0
            soul.dashrotation = 0
        end
    end
end
end

local function cyankey(key)
    if game.state == "evade" and soul.mode == "cyan" then
    if key ~= "c" then return end
    if soul.dash or soul.dashCooldown > 0 then return end

    local dx, dy = 0, 0

    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("up") then dy = dy - 1 end
    if love.keyboard.isDown("down") then dy = dy + 1 end

    -- No direction pressed
    if dx == 0 and dy == 0 then
        return
    end

    -- Normalize so diagonal isn't faster
    local length = math.sqrt(dx * dx + dy * dy)
    dx = dx / length
    dy = dy / length

soul.dash = true
soul.dashx = dx
soul.dashy = dy
soul.dashTimer = DASH_TIME
soul.dashCooldown = DASH_COOLDOWN

-- Right/Up = clockwise, Left/Down = counterclockwise
if dx > 0 or dy < 0 then
    soul.dashSpinDir = 1
else
    soul.dashSpinDir = -1
end
end
end

local Cyansoul = {}
local cyanWaiting = false

local function aniCyan(dt)
   
    if soul.mode ~= "cyan" or game.state ~= "evade" or not soul.dash then
        cyanWaiting = false
        return
    end
local x = soul.x
local y = soul.y
local rot = soul.dashrotation 
    if not cyanWaiting then
        cyanWaiting = true

        

        wait(0.03, function()
            table.insert(Cyansoul, {
                x = x,
                y = y,
                rotation = rot,
                Alpha = 1
            })

            cyanWaiting = false
        end)
    end
end

local function deleCyan(dt)
    for i = #Cyansoul, 1, -1 do
        Cyansoul[i].Alpha = Cyansoul[i].Alpha - 4 * dt

        if Cyansoul[i].Alpha <= 0 or game.state ~= "evade" then
            table.remove(Cyansoul, i)
        end
    end
end
--------------------------------------------------------------------
-- Menu / submenu positioning
--------------------------------------------------------------------

local menuPositions = { 37, 209, 367, 526 }

local function updateMenuSoul()
    if game.state == "menu" or game.state == "betwmenu" then
        soul.dash = false
        soul.dashrotation = 0
        soul.dashx = 0
        soul.dashy = 0

        soul.y = 454
        soul.x = menuPositions[menu.select]
        soul.indpurp = 1
    end
end

local function sSubmenu(dt)
    if game.state == "subFight"
    or game.state == "Act"
    or game.state == "Item"
    or game.state == "Mercy"
    or game.state == "subAct" then

        local slot = ((submenu.index - 1) % 4) + 1

        if slot == 1 then
            soul.x = 60
            soul.y = 278
        elseif slot == 2 then
            soul.x = 380
            soul.y = 278
        elseif slot == 3 then
            soul.x = 60
            soul.y = 305
        elseif slot == 4 then
            soul.x = 380
            soul.y = 305
        end
    end
end

--------------------------------------------------------------------
-- Damage invisibility flicker
--------------------------------------------------------------------

local function updateInvis(dt)
    if soul.invis then
        soul.invisTimer = soul.invisTimer + dt

        if soul.invisTimer >= 0.2 then -- wait time
            soul.invisTimer = 0

            if soul.invisState == 1 then
                soul.invisAlpha = 0.5
                soul.invisState = 2
            else
                soul.invisAlpha = 1
                soul.invisState = 1
            end
        end
    else
        soul.invisAlpha = 1
        soul.invisTimer = 0
        soul.invisState = 1
    end
end


--------------------------------------------------------------------
-- Broken soul shards
--------------------------------------------------------------------

local Shards = {}
local shardIndex = 0
local shardsCreated = false

local SHARD_GRAVITY = 500
local SHARD_SPEED = 180
local SHARD_LIFETIME = 5


local function createShards()

    if shardsCreated then
        return
    end

    shardsCreated = true

    for i = 1, 4 do

        local angle = math.random() * math.pi * 2
        local speed = math.random(100, SHARD_SPEED)

        table.insert(Shards, {
            index = i,

            x = soul.x,
            y = soul.y,

            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,

            rotation = math.random() * math.pi * 2,
            rotationSpeed = math.random(-8, 8),

            gravity = SHARD_GRAVITY
        })
    end
end


local function updateShards(dt)

    for i = #Shards, 1, -1 do

        local shard = Shards[i]

        -- Gravity
        shard.vy = shard.vy + shard.gravity * dt

        -- Movement
        shard.x = shard.x + shard.vx * dt
        shard.y = shard.y + shard.vy * dt

        -- Rotation
        shard.rotation =
            shard.rotation + shard.rotationSpeed * dt

        -- Remove shard when it leaves the screen
        if shard.y > love.graphics.getHeight() + 50 then
            table.remove(Shards, i)
        end
    end
end


local function drawShards()

    for _, shard in ipairs(Shards) do

        local image = shards[shard.index]

        if image then
            love.graphics.draw(
                image,
                shard.x,
                shard.y,
                shard.rotation,
                1,
                1,
                image:getWidth() / 2,
                image:getHeight() / 2
            )
        end
    end
end


--------------------------------------------------------------------
-- Game Over
--------------------------------------------------------------------

local function gameover(dt)
    if stat.hp <= 0 and stat.kr == 0 then
        if game.state ~= "Gameover" then
            game.state = "Gameover"
            Shards = {}
            shardIndex = 0
            shardsCreated = false
            soul.brokentimer = 1.5
            soul.shardtimer = 2.5
        end

        soul.brokentimer =
            soul.brokentimer - dt

        soul.shardtimer =
            soul.shardtimer - dt

        if soul.shardtimer <= 0
            and not shardsCreated then
            createShards()
        end

        if shardsCreated
            and #Shards == 0 then
            Gameover.start()
        end
    end
end

--------------------------------------------------------------------
-- Follow overworld player
--------------------------------------------------------------------

local playerReference = nil

local function goto(dt)
    if game.state == "overworld" and playerReference then
        soul.x = playerReference.x
        soul.y = playerReference.y
    end
end

function soul.setPlayer(player)
    playerReference = player
end

--------------------------------------------------------------------
-- OV submenu
--------------------------------------------------------------------
local function subup(dt)
    if game.state ~= "overworld" then
        subindex = 1
        return
    end

    if substate == "submenu" or substate == "subinfo" then
        soul.x = 58

        if subindex == 1 then
            soul.y = 200
        elseif subindex == 2 then
            soul.y = 236
        elseif subindex == 3 then
            soul.y = 272
        end
    else
        subindex = 1
    end
end
--------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------

function soul.update(dt, box)
    updateMenuSoul()
    sSubmenu(dt)
    updateInvis(dt)
    updOrange(dt)
    movOrange(dt)
    aniOrange(dt)
    deleOrange(dt)
    cyanUp(dt)
    aniCyan(dt)
    deleCyan(dt)
    gameover(dt)
    updateShards(dt)
    subup(dt)
    goto(dt)

    -- Damage invisibility timer (always runs)
    if soul.damtimer > 0 then
        soul.damtimer = soul.damtimer - dt
    else
        soul.invis = false
    end

    if game.state == "evade" then

        if soul.mode == "red" or soul.mode == "cyan" then
            if love.keyboard.isDown("right") then
                soul.x = soul.x + soul.speed * dt
            end

            if love.keyboard.isDown("left") then
                soul.x = soul.x - soul.speed * dt
            end

            if love.keyboard.isDown("up") then
                soul.y = soul.y - soul.speed * dt
            end

            if love.keyboard.isDown("down") then
                soul.y = soul.y + soul.speed * dt
            end

            soul.movement = 0
        end

        if soul.mode == "purple" then
            local spacing = 40
            local lineOffset = 15

            local lineCount = 0
            for y = box.y + spacing / 2, box.y + box.h - spacing / 2, spacing do
                lineCount = lineCount + 1
            end

            local maxIndex = lineCount - 1

            soul.indpurp = math.max(0, math.min(soul.indpurp, maxIndex))

            local targetY = box.y + spacing / 2 + lineOffset + soul.indpurp * spacing

            soul.y = smoothMove(soul.y, targetY, 20, dt)

            if love.keyboard.isDown("right") then
                soul.x = soul.x + soul.speed * dt
            end

            if love.keyboard.isDown("left") then
                soul.x = soul.x - soul.speed * dt
            end
        end
        -----------------------------------------------------------------------------------------------
        if love.keyboard.isDown("x") or love.keyboard.isDown("lshift") then
            soul.speed = soul.basespeed /2
        else
            soul.speed = soul.basespeed
        end

        if soul.mode == "blue" then
            updateBlueDirection(dt, box)

            if soul.stoptimer > 0 then
                soul.stoptimer = soul.stoptimer - dt
            end
        end

        soul.clampToBox(box)
    end
end

function soul.inv(damage)
    Hp.damage(damage)
    soul.damtimer = 0.6
    soul.invis = true
    soul.invisAlpha = 0.5
    soul.invisState = 2
    soul.invisTimer = 0
end

function soul.clampToBox(box)
    if game.state ~= "evade" then return end
    if not box then return end

    if soul.mode ~= "purple" then
        local minX = box.x + soul.width / 2 + 2
        local minY = box.y + soul.height / 2 + 2
        local maxX = box.x + box.w - soul.width / 2 - 2
        local maxY = box.y + box.h - soul.height / 2 - 2

        if soul.x < minX then soul.x = minX end
        if soul.y < minY then soul.y = minY end
        if soul.x > maxX then soul.x = maxX end
        if soul.y > maxY then soul.y = maxY end
    else
        local minX = box.x + soul.width / 2 + soul.width * 1.26
        local minY = box.y + soul.height / 2
        local maxX = box.x + box.w - soul.width / 2 - soul.width * 1.26
        local maxY = box.y + box.h - soul.height / 2

        if soul.x < minX then soul.x = minX end
        if soul.y < minY then soul.y = minY end
        if soul.x > maxX then soul.x = maxX end
        if soul.y > maxY then soul.y = maxY end
    end
end

function soul.draw(box)
    if game.state ~= "Acttxt"
    and game.state ~= "Itemtxt"
    and game.state ~= "Fight"
    and game.state ~= "Mercytxt"
    and game.state ~= "AfterFight"
    and game.state ~= "betwmenu"
    and game.state ~= "Gameover" then
        local w = soul.width
        local h = soul.height

        if soul.mode == "blue" then
            love.graphics.setColor(0, 0, 1, soul.invisAlpha)

            local rotation = 0

            if soul.direction == "down" then
                rotation = 0
            elseif soul.direction == "left" then
                rotation = math.pi / 2
            elseif soul.direction == "up" then
                rotation = math.pi
            elseif soul.direction == "right" then
                rotation = math.pi * 1.5
            end

            love.graphics.draw(
                soul.image,
                soul.x,
                soul.y,
                rotation,
                1, 1,
                soul.width / 2,
                soul.height / 2
            )

        elseif soul.mode == "red" then
            love.graphics.setColor(1, 0,0,1, soul.invisAlpha)

            love.graphics.draw(
                soul.image,
                soul.x,
                soul.y,
                0,
                1, 1,
                soul.width / 2,
                soul.height / 2
            )

        elseif soul.mode == "purple" then
            if game.state == "evade" then
                local paddingX = 10
                local spacing = 40

                if box then
                    love.graphics.setColor(59 / 255, 33 / 255, 53 / 255)
                    love.graphics.setLineWidth(2)

                    for y = box.y + spacing / 2, box.y + box.h - spacing / 2, spacing do
                        love.graphics.line(
                            box.x + paddingX + 10,
                            y + 15,
                            box.x + box.w - paddingX - 10,
                            y + 15
                        )
                    end
                end
            end

            love.graphics.setColor(244 / 255, 77 / 255, 222 / 255, soul.invisAlpha)
            love.graphics.draw(
                soul.image,
                soul.x,
                soul.y,
                0,
                1, 1,
                soul.width / 2,
                soul.height / 2
            )

        elseif soul.mode == "orange" then
            for _, v in ipairs(Orsoul) do
                love.graphics.setColor(252 / 255, 167 / 255, 0, v.Alpha)

                love.graphics.draw(
                    soul.image,
                    v.x,
                    v.y,
                    0,
                    1, 1,
                    soul.width / 2,
                    soul.height / 2
                )
            end

            love.graphics.setColor(252 / 255, 167 / 255, 0, soul.invisAlpha)
            love.graphics.draw(
                soul.image,
                soul.x,
                soul.y,
                0,
                1, 1,
                soul.width / 2,
                soul.height / 2
            )
elseif soul.mode == "cyan" then
    for _, v in ipairs(Cyansoul) do
        love.graphics.setColor(68/255, 251/255, 255/255, v.Alpha)
        love.graphics.draw(
            soul.image,
            v.x,
            v.y,
            v.rotation,
            1, 1,
            soul.width / 2,
            soul.height / 2
        )
    end

    love.graphics.setColor(68/255, 251/255, 255/255, soul.invisAlpha)
    love.graphics.draw(
        soul.image,
        soul.x,
        soul.y,
        soul.dashrotation,
        1, 1,
        soul.width / 2,
        soul.height / 2
    )
end

elseif game.state == "Gameover" then

        if soul.mode == "red" then
        love.graphics.setColor(1, 0, 0, 1)

    elseif soul.mode == "blue" then
        love.graphics.setColor(0, 0, 1, 1)

    elseif soul.mode == "purple" then
        love.graphics.setColor(244 / 255, 77 / 255, 222 / 255, 1)

    elseif soul.mode == "orange" then
        love.graphics.setColor(252 / 255, 167 / 255, 0, 1)

    elseif soul.mode == "cyan" then
        love.graphics.setColor(68 / 255, 251 / 255, 255 / 255, 1)
    end

    if soul.shardtimer > 0 then
    if soul.brokentimer <= 0 then
        love.graphics.draw(
            soul.broken,
            soul.x - soul.width /4,
            soul.y,
            0,
            1, 1,
            soul.width / 2,
            soul.height / 2
        )
    else
        love.graphics.draw(
        soul.image,
        soul.x,
        soul.y,
        0,
        1, 1,
        soul.width / 2,
        soul.height / 2
    )
    end
elseif soul.shardtimer < 0 then
drawShards()
end
else
        soul.x = 322
        soul.y = 315
    end

if game.state ~= "Gameover"
and not (game.state == "overworld" and substate == "submenu") then
    love.graphics.setColor(1, 1, 1, 1)
end
end

--------------------------------------------------------------------
-- submenu OV
--------------------------------------------------------------------
local move = love.audio.newSource("Assets/sound/menumove.ogg", "static")
local function submenu(key)
    if game.state == "overworld" or substate == "submenu" then
    if key == "up" then
        if subindex > 1 then
            subindex = subindex - 1
            move:play()
        end

    elseif key == "down" then
        if subindex < 3 then
            subindex = subindex + 1
            move:play()
        end
    elseif key == "z" or key == "return" then
        if subindex == 2 then
            substate = "subinfo"
        end
    end
end
end
--------------------------------------------------------------------
-- Cyan soul controls
--------------------------------------------------------------------
function soul.keypressed(key)
    cyankey(key)
submenu(key)
    if soul.mode == "purple" and game.state == "evade" then
        if key == "up" then
            soul.indpurp = soul.indpurp - 1
        elseif key == "down" then
            soul.indpurp = soul.indpurp + 1
        end
    end

    if key == "l" then
        soul.inv(10)
    end
end

return soul