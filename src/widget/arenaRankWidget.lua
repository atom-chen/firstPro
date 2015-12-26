local t_hero=require("src/config/t_hero")

local BaseWidget = require('widget.BaseWidget')

local ArenaRankWidget = class("ArenaRankWidget", function()
    return BaseWidget:new()
end)

function ArenaRankWidget:create(save, opt)
    return ArenaRankWidget.new(save, opt)
end

function ArenaRankWidget:getWidget()
    return self._widget
end

function ArenaRankWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_rank.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    widgetUtil.widgetReader(self._widget)
    
    --窗口居中
--[[    local winSize = cc.Director:getInstance():getWinSize()
    local size= self._widget:getContentSize()
    self._widget:setPositionX(winSize.width/2 - size.width/2)
]]
    --退出排行榜按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arenaRank_on_close_click")
        end
    end)
    
    local list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena_rank_item.csb")
    local list = self._widget.list_item
    list:removeAllItems()
    list:setItemModel(list_item_widget)
    
    local rankingList = Arena.getRankingList()
    local row = #rankingList
    for i=1, row do
        list:pushBackDefaultItem()
    end
    
    for i=1, row do
        local item_widget = list:getItem(i-1)
        widgetUtil.widgetReader(item_widget)
        
        --名次
        item_widget.image_1st:setVisible(false)
        item_widget.image_2st:setVisible(false)
        item_widget.image_3st:setVisible(false)
        item_widget.bitmaplabel_rank:setVisible(false)
        local rankNum = rankingList[i].rank
        if rankNum == 1 then
            item_widget.image_1st:setVisible(true)
        elseif  rankNum == 2 then
            item_widget.image_2st:setVisible(true)
        elseif  rankNum == 3 then
            item_widget.image_3st:setVisible(true)
        else
            item_widget.bitmaplabel_rank:setVisible(true)
            item_widget.bitmaplabel_rank:setString(tostring(rankNum))
        end
        
        --布阵头像
        local format = rankingList[i].format
        local hero = rankingList[i].hero
        for j=1, 4 do
            local heroID = format[j]
            if heroID > 0 then --有英雄
                for k,v in pairs(hero) do
                    if v["id"] == heroID then
                        item_widget["label_lv"..j]:setString(tostring(v["lv"])) --等级
                        
                        widgetUtil.getHeroWeaponQuality(v["elv"], item_widget["image_icon_bottom"..j], item_widget["image_icon_grade"..j])
                        widgetUtil.createIconToWidget(t_hero[heroID]["icon"], item_widget["image_icon"..j]) --头像
                        
                        --星级
                        for l=1,5 do
                            if v["star"] ~= l then
                            	item_widget["image_star"..j..l]:setVisible(false)
                            end
                        end
                        
                    	break
                    end
            	end
            else
                item_widget["image_icon_bottom"..j]:setVisible(false)
            end
        end
        
        item_widget.label_name:setString(rankingList[i].nick)
        item_widget.label_lv:setString(tostring(rankingList[i].lv))
        
    end

end

function ArenaRankWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_arenaRank_on_close_click",function(event)ArenaRankWidget.onClose(self,event)end)
end

function ArenaRankWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function ArenaRankWidget:onClose(event)
    UIManager.popWidget()
end

return ArenaRankWidget