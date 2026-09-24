local Dialogue = require("lua/Dialogue")
local soul = require("lua/soul")
local window = require("lua/window")
local Box = require("lua/box")
local bone = require("lua/bone")
local Menu = require("lua/Menu")
local subtxt = require("lua/Subtxt")
local Fight = require("lua/Fight")
local Gameover = require("lua/Gameover")
local name = require("lua/name")
local settings = require("lua/settings")
local Player = require("lua/player")
local stat = require("lua/stat")
local Hp = require("lua/Hp")
local Collision = require("lua/Collision")

love.graphics.setDefaultFilter("linear", "nearest")
love.mouse.setVisible(true)


    if settings.consumeRestartFullscreen() then
        love.window.setFullscreen(true)
    end

local battleBox
local uiFont
local quitFont

--------------------------------------------------------------------
-- Load / init
--------------------------------------------------------------------

function resetgame()--all those resets are like non temporary so like you lead save files in reset and stuff thats too why they get loaded at the beginning so i dont have to do love.restart or smt
stat.hp = stat.maxhp
stat.kr = 0
resetlove()
Gameover.reset()
Hp.reset()
name.reset()
Player:reset(320, 240)
soul.reset()
Menu.reset()

end

function resetlove()
    Escape = { ghost = 0, timer = 0 }
    game = { state = "overworld", indexselect = nil, timer = 0, room = "nothing" }
    substate = "Play" --Submenu
    subindex = 1
    love.graphics.setBackgroundColor(0, 0, 0)
    love.window.setTitle("Frisk - Undertale Style")
end

function love.load()
    resetlove()

    uiFont = love.graphics.newFont("Assets/font/UI.ttf", 16)
    quitFont = love.graphics.newFont("Assets/font/UI.ttf", 32)

    window.load()
    soul.load()
    Dialogue.load()
    Menu.load()

    Fight.load()
    Gameover.load(Dialogue) -- Gameover gets Dialogue

    name.load()
    Hp.load()
    Collision.load()
    player = Player.new(320, 240)
    battleBox = Box.new(218, 240, 155, 150)
end

--------------------------------------------------------------------
-- Battle selection
--------------------------------------------------------------------

local function selectedItem()
    if game.state == "Act" or game.state == "Acttxt" then
        return Act[submenu.index]
    elseif game.state == "subFight" then
        return Fight[submenu.index]
    elseif game.state == "Item" or game.state == "Itemtxt" then
        return Item[submenu.index]
    elseif game.state == "Mercy" or game.state == "Mercytxt" then
        return Mercy[submenu.index]
    elseif game.state == "SubAct" then
        return subAct[submenu.index]
    end
end

--------------------------------------------------------------------
-- Update
--------------------------------------------------------------------

function love.update(dt)
    waitup(dt)
    stat:checkChanges()
    waitupuntil(dt)
    window.update(dt)
    bone.update(dt, battleBox)
    Dialogue.updateText(dt)
    Menu.updateButtons()
    soul.update(dt, battleBox)
    Menu.updateSubmenu()
    Dialogue.updateSequence()
    Fight.update(dt)
    Gameover.update(dt)
    name.update(dt)
    Hp.update(dt)
    Collision.update()
     player:update(dt)

    if game.state == "Act"
    or game.state == "Item"
    or game.state == "Mercy"
    or game.state == "subFight" then
        local newIndex = selectedItem()

        if newIndex then
            game.indexselect = tostring(newIndex)
        end
    end

    battleBox:update(dt)
    subtxt.update(dt)

    if love.keyboard.isDown("escape") then
        Escape.ghost = Escape.ghost + dt
        Escape.timer = Escape.timer + dt
    else
        Escape.timer = 0
        Escape.ghost = 0
    end
end

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

function removeValue(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end

    return false
end

local waits = {}

function wait(seconds, callback)
    table.insert(waits, {
        time = seconds,
        callback = callback
    })
end

function waitup(dt)
    for i = #waits, 1, -1 do
        waits[i].time = waits[i].time - dt

        if waits[i].time <= 0 then
            waits[i].callback()
            table.remove(waits, i)
        end
    end
end

local waituntils = {}

function waituntil(condition, callback)
    table.insert(waituntils, {
        condition = condition,
        callback = callback
    })
end

function waitupuntil(dt)
    for i = #waituntils, 1, -1 do
        if waituntils[i].condition() then
            waituntils[i].callback()
            table.remove(waituntils, i)
        end
    end
end

function printOutlined(text, x, y, r_, sx, sy, ox, oy)
    r_ = r_ or 0
    sx = sx or 1
    sy = sy or sx
    ox = ox or 0
    oy = oy or 0

    local red, g, b, a = love.graphics.getColor()

    love.graphics.setColor(0, 0, 0, a)
    love.graphics.print(text, x - 1, y,     r_, sx, sy, ox, oy)
    love.graphics.print(text, x + 1, y,     r_, sx, sy, ox, oy)
    love.graphics.print(text, x, y - 1,     r_, sx, sy, ox, oy)
    love.graphics.print(text, x, y + 1,     r_, sx, sy, ox, oy)

    love.graphics.setColor(red, g, b, a)
    love.graphics.print(text, x, y, r_, sx, sy, ox, oy)
end

function smoothMove(variable, target, speed, dt)
    return variable + (target - variable) * speed * dt
end

--------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------

function love.draw()
    window.black()
    window.begin()

    -- Main game states
    if game.state == "Name" or game.state == "choosename" then
        name.draw()

    elseif game.state == "overworld" then
        player:draw()
        Collision.draw()
        if substate == "submenu" then
            soul.draw(battleBox)
        end
    else
        -- Battle screen
        if game.state ~= "Gameover" then
            battleBox:draw()
            bone.draw(battleBox)
            Menu.drawSubmenu()
            Fight.draw()
            Menu.drawButtons()
            Box:backround()
            Hp.draw()
        end
        Dialogue.draw()
        soul.draw(battleBox)
        Gameover.draw()
    end

    -- Debug information
    if love.keyboard.isDown("f1") then
        love.graphics.setFont(uiFont)

        printOutlined(
            "FPS: " .. tostring(love.timer.getFPS()) ..
            "\nhp = " .. tostring(stat.hp) ..
            "\nkr = " .. tostring(stat.kr) ..
            "\nname = " .. tostring(stat.name) ..
            "\nindex = " .. tostring(submenu.index) ..
            "\nitem = " .. tostring(selectedItem() or "nil") ..
            "\ngame.state = " .. tostring(game.state) ..
            "\nindexselect = " .. tostring(game.indexselect),
            10,
            40
        )
    end

    -- Quit message
    if game.state ~= "Gameover" and game.state ~= "Name" then
        love.graphics.setFont(quitFont)
        love.graphics.setColor(1, 1, 1, Escape.ghost)

        if Escape.timer > 0 and Escape.timer < 1 then
            love.graphics.print("QUITTING.", 10, 10)

        elseif Escape.timer > 1 and Escape.timer < 2 then
            love.graphics.print("QUITTING..", 10, 10)

        elseif Escape.timer > 2 and Escape.timer < 3 then
            love.graphics.print("QUITTING...", 10, 10)

        elseif Escape.timer > 3 and Escape.timer < 4 then
            love.graphics.print("GOODBY...", 10, 10)
            love.event.quit()
        end
    end

    -- Letterbox / screen borders
    love.graphics.setColor(0, 0, 0)

    -- Top
    love.graphics.rectangle("fill", -1000, -1000, 2640, 1000)

    -- Bottom
    love.graphics.rectangle("fill", -1000, 480, 2640, 1000)

    -- Left
    love.graphics.rectangle("fill", -1000, 0, 1000, 480)

    -- Right
    love.graphics.rectangle("fill", 640, 0, 1000, 480)

    -- Screen outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 0, 0, 640, 480)

    window.finish()
end

--------------------------------------------------------------------
-- Input
--------------------------------------------------------------------
function love.keypressed(key)
    window.keypressed(key)
    Dialogue.keypressed(key)

    -- State-specific input
    if game.state == "Name" or game.state == "choosename" then
        name.keypressed(key)

    elseif game.state == "overworld" then
        Player:keypressed(key)
        if substate == "submenu" then
            soul.keypressed(key)
        end
    elseif game.state ~= "Gameover" then
        Menu.keypressed(key)
        soul.keypressed(key)
        Fight.keypressed(key)

        -- Battle shortcuts
        if key == "r" then
            game.state = "betwmenu"

        elseif key == "f" then
            game.state = "evade"
        end
    end

    -- Debug / testing shortcuts
    if key == "1" then
        game.state = "Name"

    elseif key == "2" then
        game.state = "menu"

    elseif key == "3" then
        stat.hp = 0
        stat.kr = 0

    elseif key == "4" then
        game.state = "overworld"
    end
end