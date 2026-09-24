
local Gameover = {}

local font
local Dialogue
local settings = require("lua/settings")

Gameover.alpha = 0
Gameover.timer = 0
Gameover.started = false


function Gameover.load(dialogue)
    font = love.graphics.newFont("Assets/font/8-BITWONDER.ttf", 64)

    Dialogue = dialogue
end


function Gameover.reset()
    Gameover.alpha = 0
    Gameover.timer = 0
    Gameover.started = false
end


function Gameover.start()
    if Gameover.started then
        return
    end

    Gameover.started = true
    Gameover.alpha = 0
    Gameover.timer = 0

    Dialogue.play({
        {"* You cannot give up yet.", 20, 40, 360, 16 * 2, "dete", {1, 1, 1, 1}, "no", "nobub", nil},
        {"* This is not the end.",    20, 40, 360, 16 * 2, "dete", {1, 1, 1, 1}, "no", "nobub", nil}
    }, function()
        settings.markFullscreenForRestart(love.window.getFullscreen())
        resetgame()
    end)
end


function Gameover.update(dt)
    if not Gameover.started then
        return
    end

    Gameover.timer = Gameover.timer + dt
    Gameover.alpha = Gameover.alpha + dt * 0.5

    if Gameover.alpha > 1 then
        Gameover.alpha = 1
    end
end


function Gameover.draw()
    if not Gameover.started then
        return
    end

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, Gameover.alpha)

    printOutlined("GAME", 40, 0, 0, 2, 2)
    printOutlined("\nOVER", 60, 0, 0, 2, 2)

    love.graphics.setColor(1, 1, 1, 1)
end


return Gameover