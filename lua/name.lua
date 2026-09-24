local name = {}
local window = require("lua/window")
local stat = require("lua/stat")
local letters = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z"
}

local actions = {"QUIT", " BACKSPACE", "       DONE"}

local UPPER_COUNT = 26
local MAX_NAME_LENGTH = 6

local index = 1
local font
local bigFont

local chosen = {}
local downShortcutOrigin = nil

-- confirm screen ("choosename") state
local confirmIndex = 1 -- 1 = NO, 2 = YES

-- animation state for the name growing into the middle
local anim = {
    timer = 0,
    duration = 0.9,

    startX = 0, startY = 0, startScale = 1,
    endX = 0, endY = 0, endScale = 1,

    questionAlpha = 0,
}

local cols = 7
local cellW = 40
local cellH = 30
local gapX = 20
local gapY = 0
local extraGapY = 7
local startX = 130
local startY = 130

local actionGapX = 100
local actionExtraGapY = 20

local letterShake = 0.7 -- how many pixels each letter can jitter, set to 0 to disable
local shakeInterval = 1 / 30 -- how often the jitter re-rolls (seconds). Higher = slower shake.

local shakeTimer = 0
local shakeOffsets = {} -- [i] = {x = ..., y = ...}
local noShake = { x = 0, y = 0 }

local upperRows = math.ceil(UPPER_COUNT / cols)
local lowerCount = #letters - UPPER_COUNT
local lowerRows = math.ceil(lowerCount / cols)
local totalRows = upperRows + lowerRows + 1

function name.reset()
    index = 1
    chosen = {}
    downShortcutOrigin = nil
    confirmIndex = 1    
end

function name.load()
    name.reset()
    font = love.graphics.newFont("Assets/font/dete.ttf", 16 * 2)
    bigFont = love.graphics.newFont("Assets/font/dete.ttf", 48)
end

function name.update(dt)
    if game.state == "choosename" and anim.timer < anim.duration then
        anim.timer = math.min(anim.timer + dt, anim.duration)

        local t = anim.timer / anim.duration
        t = 1 - (1 - t) ^ 3 -- ease-out cubic

        anim.questionAlpha = t
    end

    shakeTimer = shakeTimer + dt

    if shakeTimer >= shakeInterval then
        shakeTimer = shakeTimer - shakeInterval

        for i = 1, #letters do
            local offset = shakeOffsets[i]
            if not offset then
                offset = {}
                shakeOffsets[i] = offset
            end

            offset.x = love.math.random(-letterShake, letterShake)
            offset.y = love.math.random(-letterShake, letterShake)
        end
    end
end

-- Position im Grid für Index i (1..#letters+#actions)
local function getGridPos(i)
    if i <= UPPER_COUNT then
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        return col, row
    elseif i <= #letters then
        local j = i - UPPER_COUNT - 1
        local col = j % cols
        local row = upperRows + math.floor(j / cols)
        return col, row
    else
        local j = i - #letters - 1
        return j, upperRows + lowerRows
    end
end

local function rowCount(row)
    if row < upperRows then
        local startIdx = row * cols
        return math.min(cols, UPPER_COUNT - startIdx)
    elseif row < upperRows + lowerRows then
        local lrow = row - upperRows
        local startIdx = lrow * cols
        return math.min(cols, lowerCount - startIdx)
    else
        return #actions
    end
end

local function getIndexFromGrid(col, row)
    local rc = rowCount(row)
    if rc <= 0 then return nil end

    if col >= rc then col = rc - 1 end

    if row < upperRows then
        return row * cols + col + 1
    elseif row < upperRows + lowerRows then
        local lrow = row - upperRows
        return UPPER_COUNT + lrow * cols + col + 1
    else
        return #letters + col + 1
    end
end

-- ===== Confirm screen ("choosename") =====

local function startConfirmAnim()
    local w, h = window.baseW, window.baseH
    local nameText = table.concat(chosen)

    anim.timer = 0

    -- where the name currently sits (small font, top area)
    anim.startX = startX + 150
    anim.startY = startY - 40
    anim.startScale = font:getHeight() / bigFont:getHeight()

    -- where it should end up: dead center of the screen
    local bigWidth = bigFont:getWidth(nameText)
    local bigHeight = bigFont:getHeight()

    anim.endX = (w - bigWidth) / 2.5
    anim.endY = (h - bigHeight) / 2.5
    anim.endScale = 2

    anim.questionAlpha = 0
end

local function drawConfirm()
    local w, h = window.baseW, window.baseH
    local nameText = table.concat(chosen)

    local t = anim.timer / anim.duration
    t = 1 - (1 - t) ^ 3

    local x = anim.startX + (anim.endX - anim.startX) * t
    local y = anim.startY + (anim.endY - anim.startY) * t
    local scale = anim.startScale + (anim.endScale - anim.startScale) * t

    -- big centered name
    love.graphics.setFont(bigFont)
    love.graphics.setColor(1, 1, 1, 1)
    printOutlined(nameText, x, y, 0, scale, scale)

    love.graphics.setFont(font)

    -- question sits ABOVE the name, fading in as the animation plays
    local question = "Is this name correct?"
    local qWidth = font:getWidth(question)
    love.graphics.setColor(1, 1, 1, anim.questionAlpha)
    printOutlined(question, (w - qWidth) / 2, h / 2 - 140)

    -- NO / YES sit below the name
    if confirmIndex == 1 then
        love.graphics.setColor(1, 1, 0, anim.questionAlpha)
    else
        love.graphics.setColor(1, 1, 1, anim.questionAlpha)
    end
    printOutlined("NO", w / 2 - 80, h / 2 + 60)

    if confirmIndex == 2 then
        love.graphics.setColor(1, 1, 0, anim.questionAlpha)
    else
        love.graphics.setColor(1, 1, 1, anim.questionAlpha)
    end
    printOutlined("YES", w / 2 + 40, h / 2 + 60)

    love.graphics.setColor(1, 1, 1, 1)
end

local function confirmKeypressed(key)

    if key == "left" then
        confirmIndex = 1
    elseif key == "right" then
        confirmIndex = 2
    elseif key == "z" or key == "return" then
        if confirmIndex == 1 then
            game.state = "Name"
        else
            stat.name = table.concat(chosen)
            game.state = "menu"
        end
    end
end

-- ===== Letter selection screen ("Name") =====

function name.draw()
    if game.state == "choosename" then
        drawConfirm()
        return
    end

    love.graphics.setFont(font)

    for i, letter in ipairs(letters) do
        local col, row = getGridPos(i)

        local x = startX + col * (cellW + gapX)
        local y = startY + row * (cellH + gapY)

        if i > UPPER_COUNT then
            y = y + extraGapY
        end

        local offset = shakeOffsets[i] or noShake
        local shakeX = offset.x
        local shakeY = offset.y

        if i == index then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        printOutlined(letter, x + shakeX, y + shakeY)
    end

    local actionRow = upperRows + lowerRows
    local actionY = startY + actionRow * (cellH + gapY) + extraGapY + actionExtraGapY

    for j, actionLabel in ipairs(actions) do
        local x = startX + (j - 1) * actionGapX
        local i = #letters + j

        if i == index then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        printOutlined(actionLabel, x, actionY)
    end

    love.graphics.setColor(1, 1, 1, 1)
    printOutlined(table.concat(chosen), startX + 150, startY - 40)
    printOutlined("Name the fallen Human", 130, 30)
end

local function doAction(label)
    if label == "QUIT" then
        love.event.quit()

    elseif label == " BACKSPACE" then
        table.remove(chosen)

    elseif label == "       DONE" then
        if #chosen == 0 then
            return
        end

        confirmIndex = 1
        game.state = "choosename"
        startConfirmAnim()
    end
end

function name.keypressed(key)
    if game.state == "choosename" then
        confirmKeypressed(key)
        return
    end

    local totalItems = #letters + #actions

    if key == "right" then
        index = index + 1
        if index > totalItems then index = 1 end

    elseif key == "left" then
        index = index - 1
        if index < 1 then index = totalItems end

    elseif key == "down" then
        local selected = index <= #letters and letters[index]
        local quitIndex = #letters + 1
        local backspaceIndex = #letters + 2

        if selected == "v" or selected == "w" then
            downShortcutOrigin = index
            index = quitIndex
        elseif selected == "x" or selected == "y" or selected == "z" then
            downShortcutOrigin = index
            index = backspaceIndex
        else
            local col, row = getGridPos(index)
            local newRow = row + 1
            if newRow >= totalRows then newRow = 0 end
            index = getIndexFromGrid(col, newRow) or index
        end

    elseif key == "up" then
        if downShortcutOrigin and (index == #letters + 1 or index == #letters + 2) then
            index = downShortcutOrigin
            downShortcutOrigin = nil
        else
            local col, row = getGridPos(index)
            local newRow = row - 1
            if newRow < 0 then newRow = totalRows - 1 end
            index = getIndexFromGrid(col, newRow) or index
        end

    elseif key == "z" or key == "return" then
        if index <= #letters then
            if #chosen < MAX_NAME_LENGTH then
                table.insert(chosen, letters[index])
            end
        else
            local actionLabel = actions[index - #letters]
            doAction(actionLabel)
        end

    elseif key == "backspace" or key == "x" or key == "lshift" then
        table.remove(chosen)
    end
end

function name.getSelected()
    if index <= #letters then
        return letters[index]
    else
        return actions[index - #letters]
    end
end

function name.getChosen()
    return table.concat(chosen)
end

return name