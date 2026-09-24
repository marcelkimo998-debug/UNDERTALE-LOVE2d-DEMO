
local stat = {
    ATT = 0,
    DEF = 0,

    Weapon = 0,
    Armor = 0,

    Weopentype = "idk",
    Armotyp = "knive",

    EXP = 1000,
    nxEXP = 0,

    G = 100,
    name = "Kimo",

    lv = 1,

    maxhp = 20,
    hp = 20,
    kr = 0,
}


--------------------------------------------------
-- AUTOMATIC EXP CURVE
--------------------------------------------------

local function getEXPRequired(level)

    if level <= 1 then
        return 0
    end

    return math.floor(10 * (level - 1) ^ 2.2)

end


--------------------------------------------------
-- GET LEVEL FROM EXP
--------------------------------------------------

local function getLevelFromEXP(exp)

    local level = 1

    while exp >= getEXPRequired(level + 1) do
        level = level + 1
    end

    return level

end


--------------------------------------------------
-- UPDATE LEVEL STATS
--------------------------------------------------

function stat:updateStats()
    -- LV
    self.lv = getLevelFromEXP(self.EXP)
    -- MAX HP
    self.maxhp = 20 + ((self.lv - 1) * 4)
    -- ATT
    local baseATT = (self.lv - 1) * 2
    self.ATT = baseATT + self.Weapon
    -- DEF
    local baseDEF = math.floor((self.lv - 1) / 4)
    self.DEF = baseDEF + self.Armor
    -- NEXT EXP
    self.nxEXP =
        getEXPRequired(self.lv + 1) - self.EXP
end


--------------------------------------------------
-- AUTOMATIC EXP CHECK
--------------------------------------------------

local lastEXP = stat.EXP
function stat:checkChanges()

    if self.EXP ~= lastEXP then
        self:updateStats()
        lastEXP = self.EXP
    end

end


--------------------------------------------------
-- INITIAL UPDATE
--------------------------------------------------
stat:updateStats()

return stat

