local BaseWidget = require('widget.BaseWidget')

local ArenaFightLogWidget = class("ArenaFightLogWidget", function()
    return BaseWidget:new()
end)

function ArenaFightLogWidget:create(save, opt)
    return ArenaFightLogWidget.new(save, opt)
end

function ArenaFightLogWidget:getWidget()
    return self._widget
end

function ArenaFightLogWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_record.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    widgetUtil.widgetReader(self._widget)

    --local winSize = cc.Director:getInstance():getWinSize()
    --local size= self._widget:getContentSize()
    --self._widget:setPositionX(winSize.width/2-size.width/2)
    
    --退出按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arenaFightLogWidget_on_close_click")
        end
    end)

    --挑战列表
    local list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_record_item.csb")
    local list = self._widget.list_item
    list:removeAllItems()
    list:setItemModel(list_item_widget)

    local fightLogList = Arena.getFightLogList()
    local row = #fightLogList
    for i=1, row do
        list:pushBackDefaultItem()
    end

    for i=1, row do
        local item_widget = list:getItem(i-1)
        widgetUtil.widgetReader(item_widget)
        
        if Character.id == fightLogList[i].atk then --玩家打别人
            if fightLogList[i].rank == 0 then --失败，隐藏上下箭头
                item_widget.label_up_number:setString(tostring(""))--上升名次
                item_widget.label_down_number:setString(tostring(""))--下降名次
                item_widget.image_lose:setVisible(true)
                item_widget.image_win:setVisible(false)
                item_widget.image_down:setVisible(false)
                item_widget.image_up:setVisible(false)
            else --战胜，上升箭头
            item_widget.label_up_number:setString(tostring(fightLogList[i].rank))--上升名次
            item_widget.label_down_number:setString(tostring(""))--下降名次
                item_widget.image_lose:setVisible(false)
                item_widget.image_win:setVisible(true)
                item_widget.image_down:setVisible(false)
                item_widget.image_up:setVisible(true)
            end
        	
        else --被人打
            if fightLogList[i].rank == 0 then --胜利，隐藏上下箭头
                item_widget.label_up_number:setString(tostring(""))--上升名次
                item_widget.label_down_number:setString(tostring(""))--下降名次
                item_widget.image_lose:setVisible(false)
                item_widget.image_win:setVisible(true)
                item_widget.image_down:setVisible(false)
                item_widget.image_up:setVisible(false)
            else --失败，下降箭头
                item_widget.label_up_number:setString(tostring(""))--上升名次
            item_widget.label_down_number:setString(tostring(fightLogList[i].rank))--下降名次
                item_widget.image_lose:setVisible(true)
                item_widget.image_win:setVisible(false)
                item_widget.image_down:setVisible(true)
                item_widget.image_up:setVisible(false)
            end
        end

        --玩家头像
        widgetUtil.createIconToWidget(fightLogList[i].fashionID, item_widget.image_icon)
        widgetUtil.getHeroWeaponQuality(0, item_widget.image_icon_bottom, item_widget.image_icon_grade)
             
        item_widget.label_name:setString(fightLogList[i].nick) --名字
        local fightTime = os.date("%Y-%m-%d %H:%M", fightLogList[i].time)
        item_widget.label_time:setString(fightTime) --时间
        item_widget.label_lv:setString(fightLogList[i].lv) --等级
        
         
        item_widget.btn_play._rid = fightLogList[i].rid
        item_widget.btn_play:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                self:rePlayFight(sender._rid)
            end
        end)

    end

end

function ArenaFightLogWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_arenaFightLogWidget_on_close_click",function(event)ArenaFightLogWidget.onClose(self,event)end)
end

function ArenaFightLogWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function ArenaFightLogWidget:onClose(event)
    UIManager.popWidget()
end

--战斗重播
function ArenaFightLogWidget:rePlayFight(rid)
    print(rid) --战斗编号

    self:request("report.reportHandler.report", {rid = rid}, function(msg)
        if msg['code'] == 200 then
            local request = {}
            request["isReplay"]= true
            request["battlelog"] = Arena.getReport()
            UIManager.pushScene('BattleScene', request)
        end
    end)
end

return ArenaFightLogWidget