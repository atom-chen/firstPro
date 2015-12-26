--module require
local t_music=require("config/t_music")

local BaseScene = require "scene/BaseScene"

local ChapterScene = class("ChapterScene", function()
    return BaseScene:new()
end)

function ChapterScene:ctor(save, opt)
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
end

function ChapterScene:create(save, opt)
    return ChapterScene.new(save, opt)
end

function ChapterScene:onEnter()
    commonUtil.playBakGroundMusic(1010)
end

function ChapterScene:onExit()
end

return ChapterScene