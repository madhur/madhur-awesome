-- Three col mid layout similar to xmonad's

local floor = math.floor
local max = math.max
local mouse = mouse
local mousegrabber = mousegrabber
local screen = screen

local threecolmid = {
    name = "threecolmid"
}

local function arrange(p, layout)
    local t = p.tag or screen[p.screen].selected_tag
    local wa = p.workarea
    local cls = p.clients

    if #cls == 0 then
        return
    elseif #cls ==1 then
        local area
        area = p.workarea
        local g = {
            x = area.x,
            y = area.y,
            width = area.width,
            height = area.height
        }
        p.geometries[cls[1]] = g
        return
    end
    

    local g = {}

    -- Main column, fixed width and height
    local mwfact = t.master_width_factor
    local mainhei = floor(wa.height * mwfact)
    local mainwid = floor(wa.width * mwfact)
    local slavewid = wa.width - mainwid
    local slaveLwid = floor(slavewid / 2)
    local slaveRwid = slavewid - slaveLwid
    local slavehei = wa.height - mainhei
    local slaveThei = floor(slavehei / 2)
    local slaveBhei = slavehei - slaveThei
    local nbrFirstSlaves = floor(#cls / 2)
    local nbrSecondSlaves = floor((#cls - 1) / 2)

    local slaveFirstDim, slaveSecondDim = 0, 0

    if nbrFirstSlaves > 0 then
        slaveFirstDim = floor(wa.height / nbrFirstSlaves)
    end
    if nbrSecondSlaves > 0 then
        slaveSecondDim = floor(wa.height / nbrSecondSlaves)
    end

    g.height = wa.height
    g.width = mainwid

    g.x = wa.x + slaveLwid
    g.y = wa.y

    g.width = max(g.width, 1)
    g.height = max(g.height, 1)

    p.geometries[cls[1]] = g

    -- Auxiliary clients
    if #cls <= 1 then
        return
    end
    for i = 2, #cls do
        g = {}
        local idxChecker, dimToAssign

        local rowIndex = floor(i / 2)

        if i % 2 == 0 then -- left slave
            g.x = wa.x
            g.y = wa.y + (rowIndex - 1) * slaveFirstDim
            g.width = slaveLwid

            idxChecker, dimToAssign = nbrFirstSlaves, slaveFirstDim
        else -- right slave
            g.x = wa.x + slaveLwid + mainwid
            g.y = wa.y + (rowIndex - 1) * slaveSecondDim
            g.width = slaveRwid

            idxChecker, dimToAssign = nbrSecondSlaves, slaveSecondDim
        end

        -- if last slave in row, use remaining space for it
        if rowIndex == idxChecker then
            g.height = wa.y + wa.height - g.y
        else
            g.height = dimToAssign
        end

        g.width = max(g.width, 1)
        g.height = max(g.height, 1)

        p.geometries[cls[i]] = g
    end
end

local function mouse_resize_handler(c, _, _, _, orientation)
    local wa = c.screen.workarea
    local mwfact = c.screen.selected_tag.master_width_factor
    local g = c:geometry()
    local offset = 0
    local cursor = "cross"

    local corner_coords

    if orientation == "vertical" then
        if g.height + 15 >= wa.height then
            offset = g.height * .5
            cursor = "sb_h_double_arrow"
        elseif g.y + g.height + 15 <= wa.y + wa.height then
            offset = g.height
        end
        corner_coords = {x = wa.x + wa.width * (1 - mwfact) / 2, y = g.y + offset}
    else
        if g.width + 15 >= wa.width then
            offset = g.width * .5
            cursor = "sb_v_double_arrow"
        elseif g.x + g.width + 15 <= wa.x + wa.width then
            offset = g.width
        end
        corner_coords = {y = wa.y + wa.height * (1 - mwfact) / 2, x = g.x + offset}
    end

    mouse.coords(corner_coords)

    local prev_coords = {}

    mousegrabber.run(
        function(m)
            if not c.valid then
                return false
            end
            for _, v in ipairs(m.buttons) do
                if v then
                    prev_coords = {x = m.x, y = m.y}
                    local new_mwfact
                    if orientation == "vertical" then
                        new_mwfact = 1 - (m.x - wa.x) / wa.width * 2
                    else
                        new_mwfact = 1 - (m.y - wa.y) / wa.height * 2
                    end
                    c.screen.selected_tag.master_width_factor = math.min(math.max(new_mwfact, 0.01), 0.99)
                    return true
                end
            end
            return prev_coords.x == m.x and prev_coords.y == m.y
        end,
        cursor
    )
end

function threecolmid.arrange(p)
    return arrange(p, threecolmid)
end


function threecolmid.mouse_resize_handler(c, corner, x, y)
    return mouse_resize_handler(c, corner, x, y, "vertical")
end


--[[
Make focus.byidx and swap.byidx behave more consistently with other layouts.
--]]
local awful = require("awful")
local gears = require("gears")
local client = client

local function compare_position(a, b)
    if a.x == b.x then
        return a.y < b.y
    else
        return a.x < b.x
    end
end

local function clients_by_position()
    local this = client.focus
    if this then
        local sorted = {}
        for _, c in ipairs(client.focus.first_tag:clients()) do
            if not c.minimized then
                sorted[#sorted + 1] = c
            end
        end
        table.sort(sorted, compare_position)

        local idx = 0
        for i, that in ipairs(sorted) do
            if this.window == that.window then
                idx = i
            end
        end

        if idx > 0 then
            return {sorted = sorted, idx = idx}
        end
    end
    return {}
end

local function in_centerwork()
    return client.focus and client.focus.first_tag.layout.name == "threecolmid"
end

threecolmid.focus = {}

--[[
Drop in replacements for awful.client.focus.byidx and awful.client.swap.byidx
that behaves consistently with other layouts.
--]]
function threecolmid.focus.byidx(i)
    if in_centerwork() then
        local cls = clients_by_position()
        if cls.idx then
            local target = cls.sorted[gears.math.cycle(#cls.sorted, cls.idx + i)]
            awful.client.focus.byidx(0, target)
        end
    else
        awful.client.focus.byidx(i)
    end
end

threecolmid.swap = {}

function threecolmid.swap.byidx(i)
    if in_centerwork() then
        local cls = clients_by_position()
        if cls.idx then
            local target = cls.sorted[gears.math.cycle(#cls.sorted, cls.idx + i)]
            client.focus:swap(target)
        end
    else
        awful.client.swap.byidx(i)
    end
end

return threecolmid
