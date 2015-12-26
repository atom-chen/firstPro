--module require
local BaseWidget = require('widget.BaseWidget')

local HeroUpWidget = class("HeroUpWidget", function()
    return BaseWidget:new()
end)

function HeroUpWidget:create(save, opt)
    return HeroUpWidget.new(save, opt)
end

function HeroUpWidget:getWidget()
    return self._widget
end

function HeroUpWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIhero_up.csb")
    
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
end

function HeroUpWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()
    
    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_hero_up_on_back_click",function(event) HeroUpWidget.back(self, event) end), 1)
end

function HeroUpWidget:onExit()
    self._widget:getEventDispatcher():removeCustomEventListeners("ui_hero_up_on_back_click")
end

--退出当前界面
function HeroUpWidget:back()
    UIManager.popWidget()
end

return HeroUpWidget

