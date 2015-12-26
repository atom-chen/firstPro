local tParameter = require('src/config/t_parameter')
local t_item =require('src/config/t_item')

local BaseWidget = require('widget.BaseWidget')

local ArenaPointWidget = class("ArenaPointWidget", function()
    return BaseWidget:new()
end)

function ArenaPointWidget:create(save, opt)
    return ArenaPointWidget.new(save, opt)
end

function ArenaPointWidget:getWidget()
    return self._widget
end

function ArenaPointWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    self.isGetting = false

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_point.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)

    --退出按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arenaPoint_on_close_click")
        end
    end)
    
    --刷新
    self._widget.btn_refresh:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arenaPoint_on_refresh_click")
        end
    end)

    local list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_point_item.csb")
    local list = self._widget.list_item  --物品列表
    list:removeAllItems()
    list:setItemModel(list_item_widget)
    
    self:flashRewardItem()
end

function ArenaPointWidget:onEnter()
    self._updateID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(ArenaPointWidget.update,0.33,false)
    eventUtil.addCustom(self._widget,"ui_arenaPoint_on_close_click",function(event)ArenaPointWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arenaPoint_on_refresh_click",function(event)ArenaPointWidget.onRefresh(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arenaPoint_on_item_click",function(event)ArenaPointWidget.onItemClick(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arenaPoint_on_reflesh_time",function(event)ArenaPointWidget.onReflesh(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arenaPoint_on_reflesh_reward_item",function(event)ArenaPointWidget.flashRewardItem(self,event)end)
end

function ArenaPointWidget:onExit()
    eventUtil.dispatchCustom("ui_arena_reflash_score") --刷新竞技场的积分
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateID)
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function ArenaPointWidget:onClose(event)
    UIManager.popWidget()
end

--刷新按钮
function ArenaPointWidget:onRefresh(event)
    local pay = tParameter.arena_point_refresh_pay.var
    if Character.diamond < pay then
        widgetUtil.showConfirmBox("钻石数量不足，是否进行充值？", 
            function(msg)
                --购买
                self:showTip(Str.FUNCTION_NOT_OPEN)
            end)

        return
    end
    
    widgetUtil.showConfirmBox(string.format("将花费%d钻石,确认刷新？", pay), 
        function(msg)
            self:request("arena.arenaHandler.refleshExchange", {}, function(msg)
                if msg['code'] == 200 then
                    self:flashRewardItem()
                end
            end)
        end)
end

--点击物品
function ArenaPointWidget:onItemClick(event)
    local pos = event.param.pos
    local items = Arena.getSelfInfoList()
    items = items["exchange"]
    if nil == items or (#items < 6) then
        return
    end
    
    local item = items[pos]
    if nil == item then
    	return
    end
    
    if item.state == 1 then --已经领取
        return
    end

    widgetUtil.showConfirmBox(string.format("将消耗%d积分，确认兑换？", item.score), 
        function(msg)
            local selfInfo = Arena.getSelfInfoList()
            if selfInfo.score < item.score then --当前格子需要的积分
                self:showTip("您所拥有的积分不足！")
                return
            else
                self:request("arena.arenaHandler.exchange", {itemID = item.id}, function(msg)
                    if msg['code'] == 200 then
                        self:flashRewardItem()
                    end
                end)
            end
        end)
end

--倒计时
function ArenaPointWidget.update(dt)
    local recordTime = function(lessTime)
        local h = math.floor(lessTime / 3600) --小时
        local m = math.floor((lessTime - h * 3600)/60) --分钟
        local s = math.floor(lessTime % 60) --秒
        eventUtil.dispatchCustom("ui_arenaPoint_on_reflesh_time", {strTime = string.format("%02d:%02d:%02d", h, m, s), lessTime = lessTime})
    end
    
    local now = Game.time() --当前时间
    local midnight = Game.midnight()
    
    local time1 = midnight + tParameter.arena_reflesh_time_1.var
    local time2 = midnight + tParameter.arena_reflesh_time_2.var
    
    local selfInfo = Arena.getSelfInfoList()
    if now >= time1 then
        if now >= time2 then
            if selfInfo["refleshTime"] ~= time2 then
                recordTime(0)
            else
                recordTime(time1+24*3600 - now)
            end                
        else
            if selfInfo["refleshTime"] ~= time1 then
                recordTime(0)
            else
                recordTime(time2 - now)
            end                
        end
    else
        recordTime(time1 - now)
    end
end

--刷新倒计时计算器
function ArenaPointWidget:onReflesh(event)
    self._widget.label_free_time:setString(event.param.strTime)
    if event.param.lessTime == 0 and not self.isGetting then --倒计时结束
        self.isGetting = true
        self:request("arena.arenaHandler.getExchange", {}, function(msg)
            self.isGetting = false
            if msg['code'] == 200 then
                self:flashRewardItem()
            end
        end)
    end
end

--刷新抽奖的物品列表
function ArenaPointWidget:flashRewardItem()
    local items = Arena.getSelfInfoList()
    items = items["exchange"]
    if nil == items or (#items < 6) then
    	return
    end
    
    
    local list = self._widget.list_item  --物品列表
    list:removeAllItems()

    local row = 3
    for i=1, row do
        list:pushBackDefaultItem()
    end 

    local pos = 0
    for i=1, row do
        local item_widget = list:getItem(i-1)
        widgetUtil.widgetReader(item_widget)

        for j=1, 2 do
            pos = pos +1 --  1 到 6
            local item = items[pos]
            local itemInfo = t_item[item.id]
            widgetUtil.setItemInfo(item_widget["panel_item_icon"..j], itemInfo["grade"], itemInfo["icon"], item.num, itemInfo["xlv"])
            item_widget["label_name"..j]:setString(itemInfo["name"]) --物品名称
            item_widget["label_point"..j]:setString(tostring(item.score)) --需要的积分
            
            item_widget["image_sold"..j]:loadTexture("res/common/arena_point_image1.png") --已兑换的提示图片
            if item.state == 0 then --未兑换
                item_widget["image_sold"..j]:setVisible(false)
            else
                item_widget["image_sold"..j]:setVisible(true)
            end

            --点击按钮
            item_widget["btn_item"..j]:setTag(pos)
            item_widget["btn_item"..j]:addTouchEventListener(function(sender, eventType) 
                if eventType == ccui.TouchEventType.ended then
                    local tag = sender:getTag()
                    eventUtil.dispatchCustom("ui_arenaPoint_on_item_click", {pos = tag})
                end
            end)
        end
    end
end

return ArenaPointWidget