local BaseWidget = require('widget.BaseWidget')

local FubenChapterReward3 = class("FubenChapterReward3", function()
    return BaseWidget:new()
end)

function FubenChapterReward3:create(save, opt)
    return FubenChapterReward3.new(save, opt)
end

function FubenChapterReward3:getWidget()
    return self._widget
end

function FubenChapterReward3:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_chapter_reward3.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)


    --重置按钮
    self._widget.btn_reset:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_FubenChapterReward3_on_reset_click")
        end
    end)
    
    --结束副本按钮
    self._widget.btn_end:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_FubenChapterReward3_on_end_click")
        end
    end)

end

function FubenChapterReward3:onEnter()
    eventUtil.addCustom(self._widget,"ui_FubenChapterReward3_on_reset_click",function(event)FubenChapterReward3.onReset(self,event)end)
    eventUtil.addCustom(self._widget,"ui_FubenChapterReward3_on_end_click",function(event)FubenChapterReward3.onEnd(self,event)end)
end

function FubenChapterReward3:onExit()
    eventUtil.removeCustom(self._widget)
end

function FubenChapterReward3:onReset(event)
    UIManager.popWidget()
    eventUtil.dispatchCustom("ui_copy_on_reset_click")
end

function FubenChapterReward3:onEnd(rid)
    UIManager.popWidget(true)
    UIManager.popWidget()
end

return FubenChapterReward3