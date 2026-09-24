
local Collision = {}

Collision.COLLISION = "collision"
Collision.TOUCHING = "touching"

local collisions = {}

function Collision.create(name, x, y, width, height, kind)
    collisions[name] = {
        x = x,
        y = y,
        width = width,
        height = height,
        type = kind or Collision.COLLISION,
        istouching = false
    }
end

function Collision.setType(name, kind)
    local collision = collisions[name]

    if collision then
        collision.type = kind
    end
end

function Collision.getType(name)
    local collision = collisions[name]

    return collision and collision.type
end

function Collision.delete(name)
    collisions[name] = nil
end

function Collision.setPosition(name, x, y)
    local collision = collisions[name]

    if collision then
        collision.x = x
        collision.y = y
    end
end

function Collision.getPosition(name)
    local collision = collisions[name]

    if collision then
        return collision.x, collision.y
    end

    return nil, nil
end

function Collision.check(a, b)
    return a.x < b.x + b.width
       and a.x + a.width > b.x
       and a.y < b.y + b.height
       and a.y + a.height > b.y
end

function Collision.getSolidWallY(name, tolerance)
    local collision = collisions[name]
    if not collision or collision.type ~= Collision.COLLISION then
        return nil
    end

    tolerance = tolerance or 0

    for otherName, other in pairs(collisions) do
        if otherName ~= name and other.type == Collision.COLLISION then
            local overlapsX = collision.x < other.x + other.width
                and collision.x + collision.width > other.x
            local wallY = other.y + other.height

            if overlapsX and collision.y >= wallY and collision.y <= wallY + tolerance then
                return wallY
            end
        end
    end

    return nil
end

function Collision.isBlocked(name, direction)
    local collision = collisions[name]
    if not collision or collision.type ~= Collision.COLLISION then
        return false
    end

    for otherName, other in pairs(collisions) do
        if otherName ~= name and other.type == Collision.COLLISION then
            local overlapsX = collision.x < other.x + other.width
                and collision.x + collision.width > other.x

            if direction == "up" then
                if overlapsX and collision.y == other.y + other.height then
                    return true
                end
            elseif direction == "down" then
                if overlapsX and collision.y + collision.height <= other.y then
                    return true
                end
            elseif direction == "left" then
                if collision.y < other.y + other.height
                    and collision.y + collision.height > other.y
                    and collision.x >= other.x + other.width then
                    return true
                end
            elseif direction == "right" then
                if collision.y < other.y + other.height
                    and collision.y + collision.height > other.y
                    and collision.x + collision.width <= other.x then
                    return true
                end
            end
        end
    end

    return false
end

function Collision.update()
    local check = Collision.check

    for name, a in pairs(collisions) do
        a.istouching = false

        for otherName, b in pairs(collisions) do
            if name ~= otherName and check(a, b) then
                a.istouching = true
                break
            end
        end
    end
end

function Collision.resolve(name, newX, newY, axis)

    local collision = collisions[name]

    if not collision then
        return newX, newY
    end

    collision.x = newX
    collision.y = newY

    local check = Collision.check

    for otherName, other in pairs(collisions) do

        if otherName ~= name
        and collision.type == Collision.COLLISION
        and other.type == Collision.COLLISION
        then

            if check(collision, other) then

                if axis == "x" then

                    if collision.x < other.x then

                        collision.x =
                            other.x - collision.width

                    else

                        collision.x =
                            other.x + other.width

                    end

                elseif axis == "y" then

                    if collision.y < other.y then

                        collision.y =
                            other.y - collision.height

                    else

                        collision.y =
                            other.y + other.height

                    end

                end

            end

        end

    end

    return collision.x, collision.y
end

function Collision.load()

    Collision.create(
        "Playerhit",
        100,
        100,
        20,
        20,
        Collision.TOUCHING
    )

    Collision.create(
        "Wall",
        150,
        100,
        20,
        20,
        Collision.COLLISION
    )

    -- PLAYER HITBOX
    Collision.create(
        "Player",
        100,
        100,
        20,
        18,
        Collision.COLLISION
    )
end

function Collision.draw()

    if collisions["Player"] then

        love.graphics.setColor(1, 1, 1)

        love.graphics.print(
            "Collision Player x,y: "
            .. collisions["Player"].x
            .. ", "
            .. collisions["Player"].y,
            10,
            420
        )
    end

    if love.keyboard.isDown("h") then

        love.graphics.setColor(1, 1, 1)

        local text = ""

        for name, collision in pairs(collisions) do

            love.graphics.rectangle(
                "fill",
                collision.x,
                collision.y,
                collision.width,
                collision.height
            )

            text = text
                .. name
                .. " ["
                .. collision.type
                .. "]: "
                .. tostring(collision.istouching)
                .. "\n"
        end

        love.graphics.print(
            text,
            10,
            10
        )
    end
end

return Collision

