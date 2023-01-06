---------------------------------------------------------------------------
--- Tiled layouts module for awful
--
-- @author Donald Ephraim Curtis &lt;dcurtis@cs.uiowa.edu&gt;
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Donald Ephraim Curtis
-- @copyright 2008 Julien Danjou
-- @module awful.layout
---------------------------------------------------------------------------

-- Grab environment we need
local tag = require("awful.tag")
local awful = require("awful")
local helpers = require("madhur.helpers")

local capi =
{
    client = client,
    mouse = mouse,
    screen = screen,
    mousegrabber = mousegrabber
}

local resizedmagnifier = {}

function resizedmagnifier.arrange(p) 
    local gs = p.geometries
    local cls = p.clients
    local area = p.workarea

    if #cls == 0 then return end

    if #cls > 2 then 
        helpers.debug("This layout does not support more than 2 clients")
    end

    if #cls == 1 then
        local g = {
            x = area.x,
            y = area.y,
            width = area.width,
            height = area.height
        }
        p.geometries[cls[1]] = g
        return
    end

    if #cls == 2 then
        local focus  = capi.client.focus
        local width = area["width"]
        local height = area["height"]
        local filled_space = 0

        for c = 1,2 do
            local geom = {}
            geom.height = height
            geom.y = area["y"]
            if focus == cls[c] then
                geom.width = width * 0.5
                if awful.util.magnifier then geom.width = geom.width * 1.3 end
                geom.x = filled_space
                filled_space = filled_space +  geom.width
            else
                geom.width = width  * 0.5
                if awful.util.magnifier then geom.width = geom.width * 0.7 end
                geom.x = filled_space
                filled_space = filled_space + geom.width
            end
            p.geometries[cls[c]] = geom
        end

    end

end


resizedmagnifier.name = "resizedmagnifier"
return resizedmagnifier

