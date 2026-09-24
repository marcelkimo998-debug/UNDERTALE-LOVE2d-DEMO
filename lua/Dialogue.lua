local Dialogue = {}

Dialogue.index = 0
Dialogue.lines = nil
Dialogue.running = false
Dialogue.onComplete = nil
Dialogue.texts = nil
Dialogue.alltxtcounter = 0

local fonts = {}
local bubbles = {}

local function createFont(fontPath, size)
    local key = fontPath .. "_" .. size
    if fonts[key] then
        return fonts[key]
    end

    local newFont = love.graphics.newFont("Assets/font/" .. fontPath .. ".ttf", size)
    fonts[key] = newFont
    return newFont
end

local function createBubble(name)
    if bubbles[name] then
        return bubbles[name]
    end

    local image = love.graphics.newImage("Assets/sprites/bub/" .. name .. ".png")
    bubbles[name] = image
    return image
end

function Dialogue.load()
    Dialogue.texts = {}
    Dialogue.alltxtcounter = 0
    Dialogue.index = 0
    Dialogue.lines = nil
    Dialogue.running = false
    Dialogue.onComplete = nil
end

function Dialogue.setText(text, speed, x, y, size, fontPath, r, g, b, a, skip, bubble, sound)
    Dialogue.texts = {}

    local newText = {
        fulltxt = text,
        currenttxt = "",
        counter = 0,
        x = x,
        y = y,
        waitspeed = speed,
        state = "typing",
        skip = skip or "no",
        color = { r, g, b, a },
        font = createFont(fontPath, size),
        sound = nil,
        bubble = nil,
        bubblestore = bubble,
    }

    if sound then
        newText.sound = love.audio.newSource("Assets/sound/voice/" .. sound .. ".wav", "static")
    end

    if bubble and bubble ~= "nobub" then
        newText.bubble = createBubble(bubble)
    end

    Dialogue.texts[1] = newText
end

function Dialogue.play(lines, onComplete)
    Dialogue.lines = lines
    Dialogue.onComplete = onComplete
    Dialogue.index = 1
    Dialogue.running = true
    Dialogue.next()
end

function Dialogue.next()
    local line = Dialogue.lines[Dialogue.index]

    if not line then
        Dialogue.running = false
        Dialogue.lines = nil
        Dialogue.index = 0

        local callback = Dialogue.onComplete
        Dialogue.onComplete = nil

        if callback then
            callback()
        end

        return
    end

    Dialogue.setText(
        line[1],
        line[2],
        line[3],
        line[4],
        line[5],
        line[6],
        line[7][1],
        line[7][2],
        line[7][3],
        line[7][4],
        line[8],
        line[9],
        line[10]
    )

    Dialogue.texts[1].action = line[11]
end

function Dialogue.updateText(dt)
    for _, text in ipairs(Dialogue.texts) do
        if text.state == "typing" then
            local length = #text.fulltxt
            text.counter = text.counter + text.waitspeed * dt

            local chars = math.min(math.floor(text.counter), length)

            if chars ~= (text.lastChars or 0) then
                if text.sound and text.fulltxt:sub(chars, chars) ~= " " then
                    text.sound:stop()
                    text.sound:play()
                end
                text.lastChars = chars
            end

            text.currenttxt = text.fulltxt:sub(1, chars)

            if text.counter >= length then
                text.state = "ready"
            end
        end
    end

end

function Dialogue.updateSequence()
    if Dialogue.running and #Dialogue.texts == 0 then
        Dialogue.index = Dialogue.index + 1
        Dialogue.next()
    end
end

function Dialogue.update(dt)
    Dialogue.updateText(dt)
    Dialogue.updateSequence()
end

function Dialogue.draw()
    for _, text in ipairs(Dialogue.texts) do
        if text.bubble then
            love.graphics.setColor(1, 1, 1, 1)

            local bubbleX = text.x - 35
            local bubbleY = text.y

            if text.bubblestore == "bubble2" then
                bubbleX = text.x - 5
                bubbleY = text.y + 7
            elseif text.bubblestore == "bubble3"
                or text.bubblestore == "bubble4"
                or text.bubblestore == "bubble5" then
                bubbleX = text.x - 15
                bubbleY = text.y + 5
            end

            love.graphics.draw(text.bubble, bubbleX, bubbleY)
        end

        love.graphics.setFont(text.font)
        love.graphics.setColor(text.color[1], text.color[2], text.color[3], text.color[4])
        love.graphics.print(text.currenttxt, text.x, text.y + 15)
    end
end

function Dialogue.keypressed(key)
    for i, text in ipairs(Dialogue.texts) do
        if text.state == "typing" then
            if text.skip ~= "noskip" and (key == "x" or key == "rshift") then
                text.counter = #text.fulltxt
                text.currenttxt = text.fulltxt
                text.state = "ready"
            end
        elseif text.state == "ready" and (key == "z" or key == "return") then
            if text.action then
                text.action()
            end
            table.remove(Dialogue.texts, i)
        end
    end
end

return Dialogue
