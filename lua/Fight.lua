local Fight = {}

local Bar
local Target
local Slice

local bounceCount = 0
local direction = 1

--------------------------------------------------------------------
-- Load / init
--------------------------------------------------------------------

function Fight.load()
    Bar = {
        x = 30,
        y = 250,
        color = "light",
        lightspr = love.graphics.newImage("Assets/sprites/UI/target/spr_targetchoice_0.png"),
        darkspr = love.graphics.newImage("Assets/sprites/UI/target/spr_targetchoice_1.png"),
        pressed = false,
        timer = 0,
        mode = "nothing",
        blinkTimer = 0,
        speed = 400,
        maxcounter = 3,
    }

    Target = {
        sprite = love.graphics.newImage("Assets/sprites/UI/spr_target_0.png"),
        x = 21,
        y = 233,
        sizeX = 602,
        sizeY = 163,
        ghost = 1,
    }

    Slice = {
        x = 285,
        y = 25,
        spr0 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_0.png"),
        spr1 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_1.png"),
        spr2 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_2.png"),
        spr3 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_3.png"),
        spr4 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_4.png"),
        spr5 = love.graphics.newImage("Assets/sprites/UI/slice/spr_slice_o_5.png"),
        sound = love.audio.newSource("Assets/sound/slice.wav", "static"),
        counter = 0,
        timer = 0,
    }

    Slice.sprites = {
        Slice.spr0,
        Slice.spr1,
        Slice.spr2,
        Slice.spr3,
        Slice.spr4,
        Slice.spr5,
    }
end

--------------------------------------------------------------------
-- Bar logic
--------------------------------------------------------------------

local function moveBar(dt)
    Bar.x = Bar.x + direction * Bar.speed * dt

    if Bar.x >= 602 then
        direction = -1
        bounceCount = bounceCount + 1
    elseif Bar.x <= 30 then
        direction = 1
        bounceCount = bounceCount + 1
    end

    -- MISSED
    if bounceCount == Bar.maxcounter then
        Bar.mode = "Flee"
        bounceCount = 0
    end
end

local function fleeBar(dt)
    -- MOVE RIGHT OFF SCREEN
    Bar.x = Bar.x + Bar.speed * dt

    if Bar.x > 700 then
        game.state = "AfterFight"
    end
end

local function updateBlink(dt)
    Bar.blinkTimer = Bar.blinkTimer + dt

    if Bar.blinkTimer >= 0.1 then
        Bar.blinkTimer = 0

        if Bar.color == "light" then
            Bar.color = "dark"
        else
            Bar.color = "light"
        end
    end
end

local function updateDamage(dt)
    Slice.timer = Slice.timer + dt
        Slice.sound:play()

    if Slice.timer >= 0.0833 then
        Slice.timer = 0
        Slice.counter = Slice.counter + 1
    end

    if Slice.counter > 5 then
        Slice.counter = 0
        Bar.pressed = false
        Bar.mode = "nothing"
        game.state = "AfterFight"
         Slice.sound:stop()
    end
end

--------------------------------------------------------------------
-- AfterFight
--------------------------------------------------------------------

local function updateAfterFight(dt)
    Target.x = Target.x + 1000 * dt
    Target.sizeX = Target.sizeX - 2000 * dt

    if Target.ghost < 10 then
        Target.ghost = Target.ghost - 3 * dt
    end

    if Target.sizeX <= 0 then
        Target.sizeX = 0
        game.state = "evade"
    end
end

--------------------------------------------------------------------
-- Reset
--------------------------------------------------------------------

local function resetFight()
    Bar.timer = 0
    Slice.counter = 0
    Bar.x = 30
    Bar.y = 250
    Bar.color = "light"
    Bar.mode = "nothing"
    Bar.pressed = false

    direction = 1
    bounceCount = 0

    Target.x = 21
    Target.y = 233
    Target.sizeX = 602
    Target.sizeY = 163
    Target.ghost = 1
end

--------------------------------------------------------------------
-- Update
--------------------------------------------------------------------

function Fight.update(dt)
    if game.state == "Fight" then
        Bar.timer = Bar.timer + dt

        if not Bar.pressed then
            if Bar.mode == "nothing" then
                moveBar(dt)
            elseif Bar.mode == "Flee" then
                fleeBar(dt)
            end
        else
            if Bar.mode == "Damage" then
                updateDamage(dt)
            end

            updateBlink(dt)
        end

    elseif game.state == "AfterFight" then
        updateAfterFight(dt)

    else
        resetFight()
    end
end

--------------------------------------------------------------------
-- Input
--------------------------------------------------------------------

function Fight.keypressed(key)
    if game.state ~= "Fight" then
        return
    end

    if Bar.timer <= 0.05 then
        return
    end

    if Bar.mode ~= "nothing" then
        return
    end

    if key == "z" or key == "return" then
        Bar.pressed = true
        Bar.mode = "Damage"
    end
end

--------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------

local function drawTarget()
    love.graphics.draw(
        Target.sprite,
        Target.x,
        Target.y,
        0,
        Target.sizeX / Target.sprite:getWidth(),
        Target.sizeY / Target.sprite:getHeight()
    )
end

local function drawBar()
    if Bar.color == "light" then
        love.graphics.draw(Bar.lightspr, Bar.x, Bar.y)
    elseif Bar.color == "dark" then
        love.graphics.draw(Bar.darkspr, Bar.x, Bar.y)
    end
end

local function drawSlice()
    love.graphics.draw(Slice.sprites[Slice.counter + 1], Slice.x, Slice.y, 0, 2, 2)
end

function Fight.draw()
    if game.state == "Fight" then
        drawTarget()
        drawBar()

        if Bar.mode == "Damage" then
            drawSlice()
        end

    elseif game.state == "AfterFight" then
        love.graphics.setColor(1, 1, 1, Target.ghost)
        drawTarget()
    end
end

return Fight
