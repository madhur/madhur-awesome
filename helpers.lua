local awful = require("awful")
local naughty = require("naughty")

local helpers = {
    resize_master = true
}
local capi = {
    client = client
}

function helpers.magnify(cls, gs, wa)
    if not awful.util.magnifier then
        return
    end

    local focus = capi.client.focus
    local master = awful.client.getmaster(awful.screen.focused())
    if not helpers.resize_master and focus==master then
        return
    end


    for c = 1,#cls do
        if focus == cls[c] then
            local geom = gs[cls[c]]
            local height = geom["height"]
            local width = geom["width"]
            local x = geom["x"]
            local y = geom["y"]
            local newWidth = width*1.3
            local newHeight = height*1.3
            local deltaHeight = newHeight - height
            local deltaWidth = newWidth - width
            if newWidth < wa["width"] then
                geom["width"] = newWidth
            end
            if newHeight < wa["height"] then
                geom["height"] = newHeight
            end
            if x > deltaWidth then
                geom["x"] = x - deltaWidth
            end
            if y > deltaHeight then
                geom["y"] = y - deltaHeight
            end
            return
        end
    end
end

function helpers.debug(text)
    naughty.notify({text=helpers.dump(text)})
end

function helpers.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end


return helpers