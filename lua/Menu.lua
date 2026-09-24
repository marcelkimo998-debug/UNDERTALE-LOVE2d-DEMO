local Menu = {}

local ITEMS_PER_PAGE = 4
local lists = {}
local font

local function isMenuSelectionState()
    local state = game.state
    return state == "menu"
        or state == "Act"
        or state == "subAct"
        or state == "Item"
        or state == "Mercy"
        or state == "subFight"
end

local function isSelectable(value)
    return value and value ~= " "
end

function Menu.reset()
    menu.select = 1
end

function Menu.load()
    menu = {
        select = 1,
        move = love.audio.newSource("Assets/sound/menumove.ogg", "static"),
        selectsound = love.audio.newSource("Assets/sound/snd_select.wav", "static")
    }

    menu.fight = love.graphics.newImage("Assets/sprites/UI/spr_fightbt_center_0.png")
    menu.fight1 = love.graphics.newImage("Assets/sprites/UI/spr_fightbt_center_1.png")
    menu.act = love.graphics.newImage("Assets/sprites/UI/spr_actbt_center_0.png")
    menu.act1 = love.graphics.newImage("Assets/sprites/UI/spr_actbt_center_1.png")
    menu.item = love.graphics.newImage("Assets/sprites/UI/spr_itembt_0.png")
    menu.item1 = love.graphics.newImage("Assets/sprites/UI/spr_itembt_1.png")
    menu.mercy = love.graphics.newImage("Assets/sprites/UI/spr_mercybt_0.png")
    menu.mercy1 = love.graphics.newImage("Assets/sprites/UI/spr_mercybt_1.png")

    menu.fightbl = love.graphics.newImage("Assets/sprites/UI/spr_fightbl_center_0.png")
    menu.fightbl1 = love.graphics.newImage("Assets/sprites/UI/spr_fightbl_center_1.png")
    menu.actbl = love.graphics.newImage("Assets/sprites/UI/spr_actbl_center_0.png")
    menu.actbl1 = love.graphics.newImage("Assets/sprites/UI/spr_actbl_center_1.png")
    menu.itembl = love.graphics.newImage("Assets/sprites/UI/spr_itembl_0.png")
    menu.itembl1 = love.graphics.newImage("Assets/sprites/UI/spr_itembl_1.png")
    menu.mercybl = love.graphics.newImage("Assets/sprites/UI/spr_mercybl_0.png")
    menu.mercybl1 = love.graphics.newImage("Assets/sprites/UI/spr_mercybl_1.png")

    Fight = { "* Enemy" }
    Act = { "* Check", "* Talk", "* Pose", "* Command", "* Act5", "* something" }
    subAct = { "* Enemy" }
    Item = { "* Pie" }
    Mercy = { "* Spare", " ", "* Flee" }
    submenu = { index = 0, page = 0 }

    lists = {
        Act = Act,
        subFight = Fight,
        Item = Item,
        Mercy = Mercy,
        subAct = subAct,
    }

    font = font or love.graphics.newFont("Assets/font/dete.ttf", 16 * 2)
end

function Menu.updateButtons()
    if menu.select > 4 then
        menu.select = 1
    elseif menu.select < 1 then
        menu.select = 4
    end
end

function Menu.updateSubmenu()
    local list = lists[game.state]
    if list and #list > 0 then
        submenu.index = math.max(1, math.min(submenu.index, #list))
        submenu.page = math.floor((submenu.index - 1) / ITEMS_PER_PAGE)
    else
        submenu.page = 0
        submenu.index = 1
    end
end

local function navigateSubmenu(key, list)
    if not list or #list == 0 then
        return
    end

    local oldIndex = submenu.index
    local oldPage = submenu.page
    local maxPages = math.ceil(#list / ITEMS_PER_PAGE)
    local posInPage = (submenu.index - 1) % ITEMS_PER_PAGE
    local col = posInPage % 2
    local row = math.floor(posInPage / 2)

    local function trySet(newPage, newCol, newRow)
        local newIndex = newPage * ITEMS_PER_PAGE + newRow * 2 + newCol + 1
        if isSelectable(list[newIndex]) then
            submenu.page = newPage
            submenu.index = newIndex
        end
    end

    if key == "right" then
        if col == 0 then
            trySet(submenu.page, 1, row)
        elseif submenu.page < maxPages - 1 then
            if submenu.index == submenu.page * ITEMS_PER_PAGE + 4 then
                local savedIndex, savedPage = submenu.index, submenu.page
                trySet(submenu.page + 1, 0, 1)
                if submenu.index == savedIndex and submenu.page == savedPage then
                    trySet(submenu.page + 1, 0, 0)
                end
            else
                trySet(submenu.page + 1, 0, row)
            end
        elseif row == 0 and isSelectable(list[1]) then
            submenu.page = 0
            submenu.index = 1
        elseif row == 1 and isSelectable(list[3]) then
            submenu.page = 0
            submenu.index = 3
        elseif row == 1 and isSelectable(list[1]) then
            submenu.page = 0
            submenu.index = 1
        end
    elseif key == "left" then
        if col == 1 then
            trySet(submenu.page, 0, row)
        elseif submenu.page > 0 then
            trySet(submenu.page - 1, 1, row)
        else
            local lastPage = maxPages - 1
            local target = lastPage * ITEMS_PER_PAGE + (row == 0 and 2 or 4)
            local fallback = lastPage * ITEMS_PER_PAGE + 2
            if isSelectable(list[target]) then
                submenu.page, submenu.index = lastPage, target
            elseif row == 1 and isSelectable(list[fallback]) then
                submenu.page, submenu.index = lastPage, fallback
            end
        end
    elseif key == "down" then
        if row == 0 then
            trySet(submenu.page, col, 1)
        else
            local targetIndex = submenu.page * ITEMS_PER_PAGE + 1 + col
            if isSelectable(list[targetIndex]) then
                submenu.index = targetIndex
            end
        end
    elseif key == "up" then
        if row == 1 then
            trySet(submenu.page, col, 0)
        else
            local targetIndex = submenu.page * ITEMS_PER_PAGE + 3 + col
            if isSelectable(list[targetIndex]) then
                submenu.index = targetIndex
            end
        end
    end

    if submenu.index ~= oldIndex or submenu.page ~= oldPage then
        menu.move:play()
    end
end

function Menu.keypressed(key)
    if game.state == "menu" then
        if key == "right" then
            menu.move:play()
            menu.select = math.min(menu.select + 1, 5)
        elseif key == "left" then
            menu.move:play()
            menu.select = math.max(menu.select - 1, 0)
        elseif key == "z" or key == "return" then
            if menu.select == 1 and #Fight > 0 then
                game.state = "subFight"
            elseif menu.select == 2 and #Act > 0 then
                game.state = "subAct"
            elseif menu.select == 3 and #Item > 0 then
                game.state = "Item"
            elseif menu.select == 4 and #Mercy > 0 then
                game.state = "Mercy"
            end

            menu.selectsound:play()
            submenu.index = 1
        end
        return
    end

    if key == "z" or key == "return" then
        if game.state == "Act" then
            game.state = "Acttxt"
            menu.selectsound:play()
        elseif game.state == "Item" then
            game.state = "Itemtxt"
            menu.selectsound:play()
        elseif game.state == "Mercy" then
            game.state = "Mercytxt"
            menu.selectsound:play()
        elseif game.state == "subFight" then
            game.state = "Fight"
            menu.selectsound:play()
        elseif game.state == "subAct" then
            game.state = "Act"
            menu.selectsound:play()
        end
    end

    if (game.state == "Act"
        or game.state == "Item"
        or game.state == "Mercy"
        or game.state == "subFight"
        or game.state == "subAct")
        and (key == "x" or key == "rshift") then
        game.state = "menu"
        menu.move:play()
    end

    navigateSubmenu(key, lists[game.state])
end

local function chooseSprite(selected, active, index, count, normal, selectedSprite, blank, blankSelected)
    if count == 0 then
        return selected == index and active and blankSelected or blank
    end

    return selected == index and active and selectedSprite or normal
end

function Menu.drawButtons()
    local x = 432
    local selected = menu.select
    local active = isMenuSelectionState()

    local fightSprite = chooseSprite(selected, active, 1, #Fight, menu.fight, menu.fight1, menu.fightbl, menu.fightbl1)
    local actSprite = chooseSprite(selected, active, 2, #Act, menu.act, menu.act1, menu.actbl, menu.actbl1)
    local itemSprite = chooseSprite(selected, active, 3, #Item, menu.item, menu.item1, menu.itembl, menu.itembl1)
    local mercySprite = chooseSprite(selected, active, 4, #Mercy, menu.mercy, menu.mercy1, menu.mercybl, menu.mercybl1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fightSprite, 20, x)
    love.graphics.draw(actSprite, 190, x)
    love.graphics.draw(itemSprite, 350, x)
    love.graphics.draw(mercySprite, 510, x)
end

function Menu.drawSubmenu()
    local list = lists[game.state]
    if not list then
        return
    end

    love.graphics.setFont(font)
    local start = submenu.page * ITEMS_PER_PAGE
    printOutlined((list[start + 1] or "") .. "\n" .. (list[start + 3] or ""), 100, 265)
    printOutlined((list[start + 2] or "") .. "\n" .. (list[start + 4] or ""), 425, 265)
    if math.ceil(#list / ITEMS_PER_PAGE) > 1 then
        printOutlined("\n\n  PAGE " .. submenu.page, 425, 265)
    end
end

return Menu
