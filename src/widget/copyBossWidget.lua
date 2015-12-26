local t_chapter = require('config/t_chapter')

local BaseWidget = require('widget.BaseWidget')

local CopyBossWidget = class("CopyBossWidget", function()
    return BaseWidget:new()
end)

function CopyBossWidget:create(save, opt)
    return CopyBossWidget.new(save, opt)
end

function CopyBossWidget:getWidget()
    return self._widget
end

function CopyBossWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    self._ChapterItemsCfg = Copy.getBossChapterItems()
    
    self._stars = Copy.getStars() --总星星

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_boss.csb")
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
            eventUtil.dispatchCustom("ui_CopyBossWidget_on_close_click")
        end
    end)

    --BOSS章节列表
    local pageView_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_boss_item.csb")
    local pageView = self._widget.PageView_boss
    pageView:removeAllPages()
    
    pageView:addEventListener(function(event,type)     
        if type==ccui.PageViewEventType.turning then
            self:pageViewScroll()             
        end
    end)

    for i=1, #self._ChapterItemsCfg do
        local item_widget = pageView_item_widget:clone()
        widgetUtil.widgetReader(item_widget)

        local chapterID = self._ChapterItemsCfg[i]
        local chapterCfg = t_chapter[chapterID]
        
        --保存章节ID
        item_widget:setTag(chapterID)
        
        --怪物头像
        item_widget.image_monster:loadTexture("res/img/"..chapterCfg.img..".png")

        --是否解锁
        local lock = false --已解锁
        if self._stars < chapterCfg.open_star then  --锁
            item_widget.label_star_num:setString(tostring(chapterCfg.open_star))
            lock = true
            item_widget.btn_fuben_boss:setEnabled(false)
            item_widget.btn_fuben_boss:setBright(false)
        else
            local useNum = Copy.getCharpterFightNum(chapterID)
            local showNum = chapterCfg.day_count - useNum
            if showNum < 0 then
            	showNum = 0
            end
            item_widget.label_day_count:setString(tostring(showNum))
            item_widget.btn_fuben_boss:setEnabled(true)
            item_widget.btn_fuben_boss:setBright(true)
        end
        item_widget.label_star_num:setVisible(lock) --可以解锁的数量
        item_widget.label_desc:setVisible(lock)
        item_widget.label_day_count:setVisible(not lock) --剩余挑战次数
        item_widget.label_day_count_text:setVisible(not lock)
        
        --BOSS血量
        local lostHp = Copy.getCharpterBossHP(chapterID)
        local totalHp, bossName = Copy.getCharpterBossTotalHP(chapterID)
        item_widget.label_hp_num:setString((totalHp - lostHp).."/"..totalHp)
        local percent = (totalHp - lostHp)/totalHp * 100
        item_widget.progress_hp:setPercent(percent)

        --boss名字
        item_widget.label_name1:setString(bossName)

        --副本按钮
        item_widget.btn_fuben_boss:setTag(chapterID)
        item_widget.btn_fuben_boss:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_CopyBossWidget_on_copy_click", {chapterID = tag})
            end
        end)
        
        pageView:addPage(item_widget)
        
        self:visiblePageView(i-1, false)
    end
    
    self:updatePageView(0)--默认选中第一个
end

function CopyBossWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_CopyBossWidget_on_close_click",function(event)CopyBossWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_CopyBossWidget_on_copy_click",function(event)CopyBossWidget.onCopy(self,event)end)
end

function CopyBossWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

function CopyBossWidget:onResume()
   self:updateCurPageView()
end

--关闭按钮
function CopyBossWidget:onClose(event)
    UIManager.popWidget()
end

--点击章节
function CopyBossWidget:onCopy(event)
    self:request("copy.copyHandler.chapterEntry", {chapter = event.param.chapterID}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('copyWidget', {chapterID = event.param.chapterID, copyID = 0}, true)
        end
    end)
end

--列表滚动
function CopyBossWidget:pageViewScroll()
    local index = self._widget.PageView_boss:getCurPageIndex()
    self:updatePageView(index)
end

--更新选中
function CopyBossWidget:updatePageView(newIndex)
    if self._index == newIndex then
        return 
    end
    
    if self._index then
        self:visiblePageView(self._index, false)
    end
    
    self:visiblePageView(newIndex, true)
    
    self._index = newIndex
end

--隐藏或显示某列表信息
function CopyBossWidget:visiblePageView(index, show)
    local item = self._widget.PageView_boss:getPage(index)
    item["bg_chapter_name"]:setVisible(show)
    item["bg_progress_hp"]:setVisible(show)
    item["btn_fuben_boss"]:setVisible(show)
    item["bg_desc"]:setVisible(show)
end

--更新当前的pageView
function CopyBossWidget:updateCurPageView()
    local index = self._widget.PageView_boss:getCurPageIndex()
    local item = self._widget.PageView_boss:getPage(index)
    if not item then
        return
    end

    --BOSS血量
    local chapterID = item:getTag()
    local lostHp = Copy.getCharpterBossHP(chapterID)
    local totalHp, bossName = Copy.getCharpterBossTotalHP(chapterID)
    item["label_hp_num"]:setString((totalHp - lostHp).."/"..totalHp)
    local percent = (totalHp - lostHp)/totalHp * 100
    item["progress_hp"]:setPercent(percent)
    
    --剩余次数
    local chapterCfg = t_chapter[chapterID]
    local useNum = Copy.getCharpterFightNum(chapterID)
    local showNum = chapterCfg.day_count - useNum
    if showNum < 0 then
        showNum = 0
    end
    item["label_day_count"]:setString(tostring(showNum))
end

return CopyBossWidget