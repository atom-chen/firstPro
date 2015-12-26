local tParameter = require('src/config/t_parameter')
local t_vip = require('src/config/t_vip')

local BaseWidget = require('widget.BaseWidget')

local TiliBuyWidget = class("TiliBuyWidget", function()
    return BaseWidget:new()
end)

function TiliBuyWidget:create(save, opt)
    return TiliBuyWidget.new(save, opt)
end

function TiliBuyWidget:getWidget()
    return self._widget
end

function TiliBuyWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UItili_buy.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)

    --要兑换的钻石
    self._widget.label_diamond_num:setString(tostring(tParameter.strength_price.var))

    --兑换后的体力
    self._widget.label_gold_num:setString(tostring(1))

    --退出按钮
    self._widget.btn_no:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_TiliBuyWidget_on_close_click")
        end
    end)

    --确定按钮
    self._widget.btn_yes:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_TiliBuyWidget_on_yes_click")
        end
    end)

    self:reflashCurNum()
end

function TiliBuyWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_TiliBuyWidget_on_close_click",function(event)TiliBuyWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_TiliBuyWidget_on_yes_click",function(event)TiliBuyWidget.onYes(self,event)end)
end

function TiliBuyWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function TiliBuyWidget:onClose(event)
    UIManager.popWidget()
end

--确定按钮
function TiliBuyWidget:onYes(event)
    if self:upNum() == 0 then
        self:showTip("VIP等级不足，无法购买！")
        return
    end

    if Character.daily.strength >= self:upNum() then
        self:showTip("已达到每日上限！")
        return
    end

    self:request("copy.copyHandler.buyStrength",{num = 1},function(msg)
        if msg["code"] == 200 then
            self:reflashCurNum()
            self:showTip("兑换成功！")
        end
    end)
end

--查询当前兑换上限
function TiliBuyWidget:upNum()
    local num = 0
    local vipInfo = t_vip[Character.vipLevel]
    if vipInfo then
        num = vipInfo["tili_add_max"]
    end
    
    return num
end

--刷新今日次数
function TiliBuyWidget:reflashCurNum()
    --当前兑换情况
    self._widget.label_num:setString((self:upNum() - Character.daily.strength).."/"..self:upNum())
end

return TiliBuyWidget