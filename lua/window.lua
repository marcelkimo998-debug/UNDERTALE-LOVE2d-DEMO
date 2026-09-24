local window = {}

window.baseW = 640
window.baseH = 480

window.scale = 1
window.offsetX = 0
window.offsetY = 0

window.fullscreen = false

window.timer = 0
window.blackout = 0

-- if true, scale can go below 1 (window smaller than base res)
-- if false, scale is clamped to at least 1 (may crop on tiny windows)
window.allowShrink = true

function window.load()
    window.scale = 1
    window.offsetX = 0
    window.offsetY = 0
    window.timer = 0
    window.blackout = 0

    -- keep this in sync with reality (e.g. after settings.consumeRestartFullscreen)
    window.fullscreen = love.window.getFullscreen()
end

function window.update(dt)
    if window.timer > 0 then
        window.timer = window.timer - dt
        if window.timer < 0 then window.timer = 0 end
    end

    if window.blackout > 0 then
        window.blackout = window.blackout - dt
        if window.blackout < 0 then window.blackout = 0 end
    end
end

--------------------------------------------------------------------
-- Scale / offset calculation (shared so other functions can reuse it
-- without pushing a transform)
--------------------------------------------------------------------

local function recalc()
    local w, h = love.graphics.getDimensions()

    local rawScale = math.min(
        w / window.baseW,
        h / window.baseH
    )

    if window.allowShrink then
        -- pixel-perfect when possible, fractional only when the
        -- window is smaller than the base resolution
        if rawScale >= 1 then
            window.scale = math.floor(rawScale)
        else
            window.scale = rawScale
        end
    else
        window.scale = math.max(1, math.floor(rawScale))
    end

    window.offsetX = (w - window.baseW * window.scale) / 2
    window.offsetY = (h - window.baseH * window.scale) / 2
end

function window.begin()
    recalc()

    love.graphics.push()
    love.graphics.translate(window.offsetX, window.offsetY)
    love.graphics.scale(window.scale)
end

function window.finish()
    love.graphics.pop()
end

--------------------------------------------------------------------
-- Coordinate conversion (real screen px -> game px)
-- Useful for mouse input against your 640x480 game space
--------------------------------------------------------------------

function window.toGame(x, y)
    return (x - window.offsetX) / window.scale,
           (y - window.offsetY) / window.scale
end

function window.getMousePosition()
    local mx, my = love.mouse.getPosition()
    return window.toGame(mx, my)
end

--------------------------------------------------------------------
-- Input
--------------------------------------------------------------------

function window.keypressed(key)
    if window.timer == 0 then
        if key == "f4" then
            window.fullscreen = not window.fullscreen
            love.window.setFullscreen(window.fullscreen, "desktop")

            window.timer = 0.05
            window.blackout = 0.05
        end
    end
end

function window.resize(w, h)
    recalc()
end

--------------------------------------------------------------------
-- Blackout flash (used on fullscreen toggle to hide the resize pop)
--------------------------------------------------------------------

function window.black()
    if (window.blackout or 0) > 0 then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle(
            "fill",
            0, 0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )
        love.graphics.setColor(1, 1, 1, 1)
        return true
    end

    return false
end

return window