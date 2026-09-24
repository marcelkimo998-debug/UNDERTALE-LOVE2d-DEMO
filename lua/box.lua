local Box = {}
Box.__index = Box

Box.Evade = "Box"

function Box.new(x, y, w, h)
    local self = setmetatable({}, Box)

    self.x, self.y, self.w, self.h = x, y, w, h

    self.startX, self.startY, self.startW, self.startH = x, y, w, h
    self.targetX, self.targetY, self.targetW, self.targetH = x, y, w, h

    self.timer = 1
    self.duration = 1

    return self
end

local function boxmenup(self)
    if game.state == "evade" or game.state == "AfterFight" then
        if self.targetX ~= 244.5 or self.targetY ~= 240
        or self.targetW ~= 155 or self.targetH ~= 150 then
            self:resize(244.5, 240, 155, 150, 1600)
        end

    elseif game.state == "menu" or game.state == "betwmenu" then
        if self.targetX ~= 25 or self.targetY ~= 240
        or self.targetW ~= 594 or self.targetH ~= 150 then
            self:resize(25, 240, 594, 150, 1600)
        end
    end
end

function Box:resize(x, y, w, h, speed)
    self.startX, self.startY, self.startW, self.startH =
        self.x, self.y, self.w, self.h

    self.targetX, self.targetY, self.targetW, self.targetH =
        x, y, w, h

    local maxDistance = math.max(
        math.abs(x - self.x),
        math.abs(y - self.y),
        math.abs(w - self.w),
        math.abs(h - self.h)
    )

    speed = speed or 500
    self.duration = maxDistance / speed
    self.timer = 0
end

function Box:update(dt)
    boxmenup(self)

    if self.timer < self.duration then
        self.timer = math.min(self.timer + dt, self.duration)

        local t = self.timer / self.duration

        self.x = self.startX + (self.targetX - self.startX) * t
        self.y = self.startY + (self.targetY - self.startY) * t
        self.w = self.startW + (self.targetW - self.startW) * t
        self.h = self.startH + (self.targetH - self.startH) * t

        self.x = math.floor(self.x + 0.5)
        self.y = math.floor(self.y + 0.5)
        self.w = math.floor(self.w + 0.5)
        self.h = math.floor(self.h + 0.5)
    end

    if game.state == "betwmenu" and self.timer >= self.duration then
        game.state = "menu"
    end
end

function Box:draw()
love.graphics.setLineWidth(4)
love.graphics.setColor(0, 0, 0, 1)

-- outline (black)
love.graphics.setColor(0, 0, 0, 1)
love.graphics.rectangle("line", self.x - 1, self.y - 1, self.w + 2, self.h + 2, 2)

--box 
love.graphics.setColor(1,1,1,1)
love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 2)
love.graphics.setColor(0, 0, 0, 0.7)
love.graphics.rectangle("fill", self.x +2, self.y +2, self.w -4, self.h -4, 2)
love.graphics.setLineWidth(2)
end

function Box:backround()
  
love.graphics.setColor(0, 0, 0)
-- top
love.graphics.rectangle("fill", -1000, -1000, 2640, 1000)

-- bottom
love.graphics.rectangle("fill", -1000, 480, 2640, 1000)

-- left
love.graphics.rectangle("fill", -1000, 0, 1000, 480)

-- right
love.graphics.rectangle("fill", 640, 0, 1000, 480)

love.graphics.setColor(1, 1, 1)
love.graphics.rectangle("line", 0, 0, 640, 480)
end


return Box