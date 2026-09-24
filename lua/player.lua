
local Player = {}
Player.__index = Player

local Collision = require("lua/Collision")


--------------------------------------------------
-- RESET
--------------------------------------------------

function Player:reset(x, y)

    self.x = x
    self.y = y

    self.speed = 100

    self.direction = "down"
    self.moving = false

    self.frameTimer = 0

    self.frameSpeed = 0.20
    self.horizontalFrameSpeed = 0.20

    self.frameIndex = 1
    self.primaryDirection = nil
end


--------------------------------------------------
-- CREATE PLAYER
--------------------------------------------------

function Player.new(x, y)

    local self = setmetatable({}, Player)

    self:reset(x, y)

    local spritePath =
        "Assets/sprites/overworld/Player/"

    self.sprites = {

        down = {
            love.graphics.newImage(
                spritePath .. "Friskstanddown.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkdown1.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskstanddown.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkdown2.png"
            ),
        },

        left = {
            love.graphics.newImage(
                spritePath .. "Friskstandleft.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkleft.png"
            ),
        },

        right = {
            love.graphics.newImage(
                spritePath .. "Friskstandright.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkright.png"
            ),
        },

        up = {
            love.graphics.newImage(
                spritePath .. "Friskstandup.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkup1.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskstandup.png"
            ),

            love.graphics.newImage(
                spritePath .. "Friskwalkup2.png"
            ),
        },
    }

    return self
end


--------------------------------------------------
-- UPDATE
--------------------------------------------------

function Player:update(dt)

    --------------------------------------------------
    -- SPEED
    --------------------------------------------------

    if
        (
            love.keyboard.isDown("x")
            or love.keyboard.isDown("lshift")
            or love.keyboard.isDown("rshift")
        )
        and substate == "Play"
    then

        self.speed =
            math.min(
                self.speed + 1000 * dt,
                250
            )

    else

        self.speed =
            math.max(
                self.speed - 1000 * dt,
                100
            )

    end


    --------------------------------------------------
    -- ONLY WORK IN OVERWORLD
    --------------------------------------------------

    if game.state ~= "overworld" then
        return
    end


    local wasMoving = self.moving

    self.moving = false


    --------------------------------------------------
    -- INPUT
    --------------------------------------------------

    local left = false
    local right = false
    local up = false
    local down = false

    if substate == "Play" then

        left = love.keyboard.isDown("left")
        right = love.keyboard.isDown("right")
        up = love.keyboard.isDown("up")
        down = love.keyboard.isDown("down")

    end


    --------------------------------------------------
    -- MOVEMENT
    --------------------------------------------------

    local dx = 0
    local dy = 0


    if left and not right then

        dx = -1

    elseif right and not left then

        dx = 1

    end


    if up and not down then

        dy = -1

    elseif down and not up then

        dy = 1

    end


    --------------------------------------------------
    -- PRIMARY DIRECTION
    --------------------------------------------------

    if self.primaryDirection == nil then

        if left and not right then

            self.primaryDirection = "left"

        elseif right and not left then

            self.primaryDirection = "right"

        elseif up and not down then

            self.primaryDirection = "up"

        elseif down and not up then

            self.primaryDirection = "down"

        end

    end


    --------------------------------------------------
    -- KEEP PRIMARY DIRECTION
    --------------------------------------------------

    if self.primaryDirection == "left" then

        if left then

            self.direction = "left"

        else

            if up and not down then

                self.primaryDirection = "up"
                self.direction = "up"

            elseif down and not up then

                self.primaryDirection = "down"
                self.direction = "down"

            else

                self.primaryDirection = nil

            end
        end


    elseif self.primaryDirection == "right" then

        if right then

            self.direction = "right"

        else

            if up and not down then

                self.primaryDirection = "up"
                self.direction = "up"

            elseif down and not up then

                self.primaryDirection = "down"
                self.direction = "down"

            else

                self.primaryDirection = nil

            end
        end


    elseif self.primaryDirection == "up" then

        if up then

            self.direction = "up"

        else

            if left and not right then

                self.primaryDirection = "left"
                self.direction = "left"

            elseif right and not left then

                self.primaryDirection = "right"
                self.direction = "right"

            else

                self.primaryDirection = nil

            end
        end


    elseif self.primaryDirection == "down" then

        if down then

            self.direction = "down"

        else

            if left and not right then

                self.primaryDirection = "left"
                self.direction = "left"

            elseif right and not left then

                self.primaryDirection = "right"
                self.direction = "right"

            else

                self.primaryDirection = nil

            end
        end
    end


    --------------------------------------------------
    -- MOVE HITBOX
    --------------------------------------------------

    if dx ~= 0 or dy ~= 0 then

        self.moving = true


        local currentX, currentY =
            Collision.getPosition("Player")


        if currentX ~= nil and currentY ~= nil then

local length = math.sqrt(dx * dx + dy * dy)

if length > 0 then
    dx = dx / length
    dy = dy / length
end

local newX =
    currentX + dx * self.speed * dt

local newY =
    currentY + dy * self.speed * dt


-- MOVE X
local resolvedX, resolvedY =
    Collision.resolve(
        "Player",
        newX,
        currentY,
        "x"
    )


-- MOVE Y
resolvedX, resolvedY =
    Collision.resolve(
        "Player",
        resolvedX,
        newY,
        "y"
    )


Collision.setPosition(
    "Player",
    resolvedX,
    resolvedY
)

    end


        --------------------------------------------------
        -- START WALKING ANIMATION
        --------------------------------------------------

        if not wasMoving then

            self.frameIndex = 2
            self.frameTimer = 0

        end

    else

        self.moving = false

    end

    local hitboxX, hitboxY =
        Collision.getPosition("Player")


    if hitboxX ~= nil and hitboxY ~= nil then

        self.x = hitboxX - 12
        self.y = hitboxY - 44

    end


    --------------------------------------------------
    -- ANIMATION
    --------------------------------------------------

    local frames =
        self:getFrameSet()


    if self.moving then

        local currentFrameSpeed =
            self.frameSpeed


        if
            self.direction == "left"
            or self.direction == "right"
        then

            currentFrameSpeed =
                self.horizontalFrameSpeed

        end


        self.frameTimer =
            self.frameTimer + dt


        if self.frameTimer >= currentFrameSpeed then

            self.frameTimer =
                self.frameTimer - currentFrameSpeed


            self.frameIndex =
                self.frameIndex + 1


            if self.frameIndex > #frames then

                self.frameIndex = 1

            end
        end

    else

        self.frameIndex = 1
        self.frameTimer = 0

    end

end


--------------------------------------------------
-- MENU SOUND
--------------------------------------------------

local move =
    love.audio.newSource(
        "Assets/sound/menumove.ogg",
        "static"
    )


--------------------------------------------------
-- KEY PRESSED
--------------------------------------------------

function Player:keypressed(key)

    if
        (key == "c" and substate ~= "subinfo")
        or
        (
            (substate == "submenu"
            or substate == "subinfo")
            and key == "x"
        )
    then

        if substate == "Play" then

            substate = "submenu"
            move:play()

        elseif substate == "submenu" then

            substate = "Play"

        elseif substate == "subinfo" then

            substate = "submenu"
            move:play()

        end
    end
end


--------------------------------------------------
-- GET FRAME SET
--------------------------------------------------

function Player:getFrameSet()

    return
        self.sprites[self.direction]
        or self.sprites.down

end


--------------------------------------------------
-- DRAW
--------------------------------------------------

function Player:draw()

    local frames =
        self:getFrameSet()


    local sprite =
        frames[self.frameIndex]
        or frames[1]


    --------------------------------------------------
    -- PLAYER SPRITE
    --------------------------------------------------

    love.graphics.draw(
        sprite,
        math.floor(self.x + 0.5),
        math.floor(self.y + 0.5),
        0,
        2,
        2
    )


    --------------------------------------------------
    -- MENU
    --------------------------------------------------

    if
        substate == "submenu"
        or substate == "subinfo"
    then

        local box1Y
        local box2Y


        if self.y > 240 then

            box1Y = 320
            box2Y = 165

        else

            box1Y = 50
            box2Y = 165

        end


        --------------------------------------------------
        -- BOX 1
        --------------------------------------------------

        love.graphics.setColor(0, 0, 0)

        love.graphics.rectangle(
            "fill",
            36,
            box1Y,
            135,
            102
        )


        love.graphics.setColor(1, 1, 1)

        love.graphics.setLineWidth(6)

        love.graphics.rectangle(
            "line",
            36,
            box1Y,
            135,
            102
        )


        --------------------------------------------------
        -- BOX 2
        --------------------------------------------------

        love.graphics.setColor(0, 0, 0)

        love.graphics.rectangle(
            "fill",
            36,
            box2Y,
            135,
            142
        )


        love.graphics.setColor(1, 1, 1)

        love.graphics.setLineWidth(6)

        love.graphics.rectangle(
            "line",
            36,
            box2Y,
            135,
            142
        )


        --------------------------------------------------
        -- BOX 1 INFO
        --------------------------------------------------

        local font =
            love.graphics.newFont(
                "Assets/font/UI.ttf",
                16
            )

        love.graphics.setFont(font)

        love.graphics.setColor(1, 1, 1)


        love.graphics.print(
            "LV " .. stat.lv ..
            "\nHP " .. stat.hp ..
            "/" .. stat.maxhp ..
            "\nG   " .. stat.G,
            48,
            box1Y + 45
        )


        local font =
            love.graphics.newFont(
                "Assets/font/dete.ttf",
                16 * 2
            )

        love.graphics.setFont(font)


        love.graphics.print(
            stat.name,
            48,
            box1Y + 10
        )


        --------------------------------------------------
        -- BOX 2 INFO
        --------------------------------------------------

        love.graphics.print(
            "ITEM",
            78,
            box2Y + 22
        )

        love.graphics.print(
            "STAT",
            78,
            box2Y + 58
        )

        love.graphics.print(
            "CELL",
            78,
            box2Y + 94
        )


        --------------------------------------------------
        -- SUBINFO
        --------------------------------------------------

        if substate == "subinfo" then

            love.graphics.setColor(0, 0, 0)

            love.graphics.rectangle(
                "fill",
                192,
                50,
                330,
                415
            )


            love.graphics.setColor(1, 1, 1)

            love.graphics.setLineWidth(6)

            love.graphics.rectangle(
                "line",
                192,
                50,
                330,
                415
            )


            love.graphics.print(
                "\"" .. stat.name ..
                "\" \n \n" ..
                "LV " .. stat.lv ..
                "\nHP " .. stat.hp ..
                "/" .. stat.maxhp ..
                "\n\nAT " .. stat.ATT,
                212,
                84
            )

        end
    end


    --------------------------------------------------
    -- RESET COLOR
    --------------------------------------------------

    love.graphics.setColor(1, 1, 1)

end


return Player
