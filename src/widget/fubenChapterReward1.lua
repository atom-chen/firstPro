local t_chapter = require('src/config/t_chapter')
local BaseWidget = require('widget.BaseWidget')

local FubenChapterReward1 = class("FubenChapterReward1", function()
    return BaseWidget:new()
end)

function FubenChapterReward1:create(save, opt)
    return FubenChapterReward1.new(save, opt)
end

function FubenChapterReward1:getWidget()
    return self._widget
end

function FubenChapterReward1:onSave()
    return {chapter=self.chapter}
end

function FubenChapterReward1:ctor(save, opt)
    self:setScene(save._scene)
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_chapter_reward1.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)
    
    if save._save then
        self.chapter = save._save["chapter"]
    else
        self.chapter = opt["charpterID"]
    end    

    local charpterID = self.chapter
    local nextID = Copy.getNextChapterID(charpterID)

    if nextID == 0 then
        self._widget.label_chapter:setString("全部通关")
    elseif nextID ~= charpterID then
        local name = t_chapter[nextID]["name3"]
        self._widget.label_chapter:setString(name)
    else
        self._widget.label_chapter:setString("")
    end

    --确定按钮
    self._widget.Button_18:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_FubenChapterReward1_on_close_click")
        end
    end)
end

function FubenChapterReward1:onEnter()
    eventUtil.addCustom(self._widget,"ui_FubenChapterReward1_on_close_click",function(event)FubenChapterReward1.onClose(self,event)end)
end

function FubenChapterReward1:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function FubenChapterReward1:onClose(event)
    UIManager.popWidget(true)
    UIManager.popWidget()
end

return FubenChapterReward1