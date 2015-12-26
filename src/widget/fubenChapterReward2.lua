local t_chapter = require('src/config/t_chapter')
local t_item = require('src/config/t_item')

local BaseWidget = require('widget.BaseWidget')

local FubenChapterReward2 = class("FubenChapterReward2", function()
    return BaseWidget:new()
end)

function FubenChapterReward2:create(save, opt)
    return FubenChapterReward2.new(save, opt)
end

function FubenChapterReward2:getWidget()
    return self._widget
end

function FubenChapterReward2:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_chapter_reward2.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)

    --退出按钮
    --[[self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_FubenChapterReward2_on_close_click")
        end
    end)]]
    
    self._bClicked = false --防止连续点击
    
    self._widget:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if self._bClicked == false then
                self._bClicked=true
                eventUtil.dispatchCustom("ui_FubenChapterReward2_on_close_click")
            end
        end
    end)
    
    local chapterID = opt["chapter"]
    local rewardItem = t_chapter[chapterID]["reward_item"]
    local item = t_item[rewardItem]
    if item["item"] == 1 then --英雄
        widgetUtil.getHeroWeaponQuality(0, self._widget.image_icon_bottom, self._widget.image_icon_grade)
    else
        widgetUtil.getItemQuality(0, self._widget.image_icon_bottom, self._widget.image_icon_grade)
    end
    
    widgetUtil.createIconToWidget(item["icon"], self._widget.image_icon)

end

function FubenChapterReward2:onEnter()
    eventUtil.addCustom(self._widget,"ui_FubenChapterReward2_on_close_click",function(event)FubenChapterReward2.onClose(self,event)end)
end

function FubenChapterReward2:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function FubenChapterReward2:onClose(event)
    UIManager.popWidget()
end

return FubenChapterReward2