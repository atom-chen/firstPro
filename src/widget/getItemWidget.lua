local t_item = require('config/t_item')

local BaseWidget = require('widget.BaseWidget')

local GetItemWidget = class("GetItemWidget", function()
    return BaseWidget:new()
end)

function GetItemWidget:create(save, opt)
    return GetItemWidget.new(save, opt)
end

function GetItemWidget:getWidget()
    return self._widget
end

function GetItemWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImessage_box_6.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)
    
    self._bClicked = false --防止连续点击

    --退出按钮
    --[[
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_GetItemWidget_on_close_click")
        end
    end)
    ]]
    
    self._widget:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if self._bClicked == false then
                self._bClicked=true
                eventUtil.dispatchCustom("ui_GetItemWidget_on_close_click")
            end
        end
    end)
            
    local have = 0
    local items = Item.getRewardItems()
    local num = #items
    for i=1, 4 do
        self._widget["rewards"..i]:setVisible(false)
    end
    
    local panel = self._widget["rewards"..num]
    if panel then
        panel:setVisible(true)
        if num == 1 then
            self:setItem(1)
        elseif num == 2 then
            for j=2, 3 do
                self:setItem(j, j-1)
            end
        elseif num == 3 then
            for j=4, 6 do
                self:setItem(j, j-3)
            end
        elseif num == 4 then
            for j=7, 10 do
                self:setItem(j, j-6)
            end
        end
    end
end

function GetItemWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_GetItemWidget_on_close_click",function(event)GetItemWidget.onClose(self,event)end)
end

function GetItemWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function GetItemWidget:onClose(event)
    UIManager.popWidget()
    eventUtil.dispatchCustom("ui_copy_event")
end

--设置物品
function GetItemWidget:setItem(j, index)
    local items = Item.getRewardItems()
    local node = self._widget["panel_item"..j]
    local item = t_item[items[index].itemID]
    widgetUtil.setItemInfo(node, item.grade, item.icon, items[index].num, item.item, item.xlv)
end

return GetItemWidget