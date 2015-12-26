local tParameter = require('src/config/t_parameter')

local BaseWidget = require('widget.BaseWidget')

local GoldBuyWidget = class("GoldBuyWidget", function()
    return BaseWidget:new()
end)

function GoldBuyWidget:create(save, opt)
    return GoldBuyWidget.new(save, opt)
end

function GoldBuyWidget:getWidget()
    return self._widget
end

function GoldBuyWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIgold_buy.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)
    
    --要兑换的钻石
    self._widget.label_diamond_num:setString(tostring(tParameter.buygold_pay_diamond.var))
    
    --兑换后的金币
    self._widget.label_gold_num:setString(tostring(tParameter.buygold_get_gold.var))

    --退出按钮
    self._widget.btn_no:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_GoldBuyWidget_on_close_click")
        end
    end)
    
    --确定按钮
    self._widget.btn_yes:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_GoldBuyWidget_on_yes_click")
        end
    end)

    self:reflashCurNum()
end

function GoldBuyWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_GoldBuyWidget_on_close_click",function(event)GoldBuyWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_GoldBuyWidget_on_yes_click",function(event)GoldBuyWidget.onYes(self,event)end)
end

function GoldBuyWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function GoldBuyWidget:onClose(event)
    UIManager.popWidget()
end

--确定按钮
function GoldBuyWidget:onYes(event)
    if Character.daily.gold >= tParameter.daily_buygold_max.var then
        self:showTip("已达到每日上限！")
    	return
    end
    
    self:request("main.userHandler.buyGold",{},function(msg)
        if msg["code"] == 200 then
            self:reflashCurNum()
            self:showTip("兑换成功！")
        end
     end)
end

--刷新今日次数
function GoldBuyWidget:reflashCurNum()
    --当前兑换情况
    self._widget.label_num:setString((tParameter.daily_buygold_max.var - Character.daily.gold).."/"..tParameter.daily_buygold_max.var)
end

return GoldBuyWidget