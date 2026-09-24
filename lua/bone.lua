local bone = {}
local window = require("lua/window")

local bones = {}

function bone.createbone(x, y, speed, dir, sprdir, size)
    local newbone = {
        x = x,
        y = y,
        speed = speed,
        dir = dir,
        size = love.graphics.newImage("Assets/sprites/Bone/Bone" .. size .. ".png"),
        sprdir = sprdir or 0
    }

    table.insert(bones, newbone)
end

function bone.update(dt, box)
    for i, currentbone in ipairs(bones) do
        if currentbone.dir == "up" then
            currentbone.y = currentbone.y - currentbone.speed * dt
        elseif currentbone.dir == "down" then
            currentbone.y = currentbone.y + currentbone.speed * dt
        elseif currentbone.dir == "right" then
            currentbone.x = currentbone.x + currentbone.speed * dt
        elseif currentbone.dir == "left" then
            currentbone.x = currentbone.x - currentbone.speed * dt
        end
    end

    for i = #bones, 1, -1 do
        local currentbone = bones[i]

        if currentbone.dir == "right" and currentbone.x > box.x + box.w + 50 then
            table.remove(bones, i)
        elseif currentbone.dir == "left" and currentbone.x < box.x - 50 then
            table.remove(bones, i)
        elseif currentbone.dir == "down" and currentbone.y > box.y + box.h + 50 then
            table.remove(bones, i)
        elseif currentbone.dir == "up" and currentbone.y < box.y - 50 then
            table.remove(bones, i)
        end
    end
end

function bone.draw(box)
    local scale = window.scale or 1
    local screenX = math.floor((window.offsetX or 0) + box.x * scale)
    local screenY = math.floor((window.offsetY or 0) + box.y * scale)
    local screenW = math.floor(box.w * scale)
    local screenH = math.floor(box.h * scale)

    love.graphics.setScissor(screenX, screenY, screenW, screenH)

    love.graphics.setColor(1, 1, 1, 1)
    for i, currentbone in ipairs(bones) do
        love.graphics.draw(
    currentbone.size,
    currentbone.x,
    currentbone.y,
    currentbone.sprdir,
    1, 1,
    currentbone.size:getWidth() / 2,
    currentbone.size:getHeight() / 2
)
    end

    love.graphics.setScissor()
end

return bone
