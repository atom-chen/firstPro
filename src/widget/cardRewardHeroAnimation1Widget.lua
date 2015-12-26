local t_item = require('src/config/t_item')
local t_hero = require('src/config/t_hero')

local BaseWidget = require('widget.BaseWidget')

local CardRewardHeroAnimation1Widget = class("CardRewardHeroAnimation1Widget", function()
    return BaseWidget:new()
end)

function CardRewardHeroAnimation1Widget:create(save, opt)
    return CardRewardHeroAnimation1Widget.new(save, opt)
end

function CardRewardHeroAnimation1Widget:getWidget()
    return self._widget
end

function CardRewardHeroAnimation1Widget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_hero_animation1.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    widgetUtil.widgetReader(self._widget)

    local itemID = opt["itemID"]
    self._bClicked = false
    
    self._widget:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if self._bClicked == false then
                self._bClicked = true
                eventUtil.dispatchCustom("ui_CardRewardHeroAnimation1Widget_on_close_click")
                UIManager.pushWidget('cardRewardHeroAnimation2Widget', {itemID = itemID}, true)
            end
        end
    end)
    
    local item = t_item[itemID]
    if not item then
        return
    end
    
    local hero = t_hero[item.reward_hero]
    if not hero then
        return
    end
    
    --英雄圆头像
    local icon = string.format("res/story_icon/%d.png", hero.icon)
    if cc.FileUtils:getInstance():isFileExist(icon) then
        self._widget.image_icon:loadTexture(icon)  
    end
    
    --英雄全身像
    local img = string.format("res/img/%d.png", hero.img)
    if cc.FileUtils:getInstance():isFileExist(img) then
        self._widget.image_hero:loadTexture(img)  
    end
    
    --描述
    self._widget.label_desc:setString(hero.desc3)
    
    --名称
    self._widget.label_name1:setString(hero.name)
    self._widget.label_name2:setString(hero.name)
    
    --特效
    local animBegin = commonUtil.getAnim(9003)
    animBegin:setPosition(self._widget.image_anchor:getPosition())
    self._widget:addChild(animBegin, 0)
    animBegin:PlaySection("s1", false)

end

function CardRewardHeroAnimation1Widget:onEnter()
    eventUtil.addCustom(self._widget,"ui_CardRewardHeroAnimation1Widget_on_close_click",function(event)CardRewardHeroAnimation1Widget.onClose(self,event)end)
end

function CardRewardHeroAnimation1Widget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function CardRewardHeroAnimation1Widget:onClose(event)
    UIManager.popWidget()
end

return CardRewardHeroAnimation1Widget