local t_chapter = require('config/t_chapter')
local t_parameter=require('config/t_parameter')

local BaseWidget = require('widget.BaseWidget')

local CopyActivityWidget = class("CopyActivityWidget", function()
    return BaseWidget:new()
end)

function CopyActivityWidget:create(save, opt)
    return CopyActivityWidget.new(save, opt)
end

function CopyActivityWidget:getWidget()
    return self._widget
end

function CopyActivityWidget:onResume()
    self:updateCurItem(self._index)
    commonUtil.playBakGroundMusic(1001)
end

function CopyActivityWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._ChapterItemsCfg = Copy.getSpecChapterItems()

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_activity.csb")
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
            eventUtil.dispatchCustom("ui_CopyActivityWidget_on_close_click")
        end
    end)
    
    --战斗按钮
    self._widget.btn_fight:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_CopyActivityWidget_on_fight_click")
        end
    end)
    
    --体力    
    self._widget.btn_tili_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_CopyActivityWidget_on_tili_click")
        end
    end)
    
    --钻石
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_CopyActivityWidget_on_diamond_click")
        end
    end)
    
    --金币
    self._widget.btn_gold_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_CopyActivityWidget_on_gold_click")
        end
    end)
    
    self:updateInfo()
    self:updateStrength()
    self:subscribe(Const.EVENT.USER, function ()--监听用户信息
        self:updateInfo()
    end)
    self:subscribe(Const.EVENT.STRENGTH, function ()--监听体力
        self:updateStrength()
    end)
    
    --列表
    local list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_activity_item.csb")
    local pageView = self._widget.PageView_boss
    pageView:removeAllPages()
    pageView:addEventListener(function(event,type)     
        if type==ccui.PageViewEventType.turning then
            self:pageViewScroll()             
        end
    end)
    
    local now = Game.time() --当前时间
     
    --先处理boss副本
    local index = 0
    for id, v in pairs(t_chapter) do
        if Const.CHAPTER_TYPE.BOSS == v["type"] then
            local timeInfo = Copy.getActivity(id)
            if timeInfo then
                local show = false --是否显示
                local state = -1 --2中状态，1：上架状态，3：满足条件
            
                local bill = timeInfo["bill"]
                local startTime = timeInfo["startTime"]
                local endTime = timeInfo["endTime"]
                if startTime > 0 and endTime > 0 then --确保数据有配
                    if bill > 0 then --有上架时间
                        if now >= bill and now <= endTime then --已到上架时间，并且未结束
                            show = true
                            if now < startTime then --未开始
                                state = 1
                            else --已开始
                                state = 3
                            end
                        end
                    else
                        if now >= startTime and now <= endTime then
                            show = true
                            state = 3
                        end
                    end
                end
                
                if show then
                    local item_widget = list_item_widget:clone()
                    widgetUtil.widgetReader(item_widget)
                    item_widget:setTag(id) --保存章节ID
                    item_widget._state = state

                    --显示BOSS相关面板
                    item_widget.Panel_activity:setVisible(false)
                    item_widget.Panel_boss:setVisible(true)

                    --副本图片
                    local path = string.format("res/chapter_bg/%d.png", v.bg)
                    if cc.FileUtils:getInstance():isFileExist(path) then
                        item_widget.image_fuben_boss:loadTexture(path)
                    end
                    
                    --提示图片
                    local pathTip = string.format("res/fuben_activity/%d.png", tonumber(v.tip_image))
                    if cc.FileUtils:getInstance():isFileExist(pathTip) then
                        item_widget.image_time:loadTexture(pathTip)
                    end

                    if state == 1 then
                        item_widget.image_boss_lock:setVisible(true)--"不在活动时间内！"
                    elseif state == 3 then
                        item_widget.image_boss_lock:setVisible(false)
                    end

                    --BOSS血量
                    local lostHp = Copy.getCharpterBossHP(id)
                    local totalHp, bossName = Copy.getCharpterBossTotalHP(id)
                    item_widget.label_hp_num:setString((totalHp - lostHp).."/"..totalHp)
                    local percent = (totalHp - lostHp)/totalHp * 100
                    item_widget.progress_hp:setPercent(percent)

                    pageView:addPage(item_widget)
                    self:scalePageView(index, true)
                    index = index +1
                end
            end
        end
    end
    
    --活动副本组
    local activityGroup = {}
    for id, v in pairs(t_chapter) do
        if Const.CHAPTER_TYPE.ACTIVITY == v["type"] then
            local type = tonumber(v["classify"])
            if type > 0 then --有配类型组
                local group = activityGroup[type]
                if not group then
                    group = {}
                    activityGroup[type] = group
                end
                table.insert(group, id)
            end
        end
    end
    
    --排序
    local groupSort = function(i1, i2) 
        return i1 < i2
    end
    for type, ids in pairs(activityGroup) do
        table.sort(ids, groupSort)
    end

    --处理活动副本
    local curLv = Character.level
    
    for type, ids in pairs(activityGroup) do
        local state = 2 --3中状态，1：上架状态，2：开始但等级未满足，3：开始且等级已满足
        local show = false --默认不显示
        local showID = 0 --显示的副本ID
        
        local idBuf = ids
        for i=1, #idBuf do
            local id = idBuf[i] --副本ID
            local timeInfo = Copy.getActivity(id)
            if timeInfo then
                local bill = timeInfo["bill"]
                local startTime = timeInfo["startTime"]
                local endTime = timeInfo["endTime"]
                
                if startTime > 0 and endTime > 0 then --确保数据有配
                    if bill > 0 then --有上架时间
                        if now >= bill and now <= endTime then --已到上架时间，并且未结束
                            show = true
                            showID = id
                            if now < startTime then --未开始
                                state = 1
                                break
                            else --已开始
                                local cfg = t_chapter[id]
                                local lv = cfg["open_level"]
                                if lv[1] > 0 and lv[2] > 0 then --有配置等级限制
                                    if curLv >= lv[1] and curLv <= lv[2] then
                                        state = 3
                                        showID = id
                                        break
                                    end
                                end
                            end
                        end
                    else
                        if now >= startTime and now <= endTime then --开始
                            show = true
                            showID = id
                            local cfg = t_chapter[id]
                            local lv = cfg["open_level"]
                            if lv[1] > 0 and lv[2] > 0 then --有配置等级限制
                                if curLv >= lv[1] and curLv <= lv[2] then
                                    state = 3
                                    showID = id
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if show then
            if state ~= 3 then --获取最接近玩家等级的
            	for i=1, #idBuf do
                    local cfg = t_chapter[idBuf[i]]
                    local lv = cfg["open_level"]
                    if lv[1] > curLv and lv[2] > curLv then
                        showID = idBuf[i]
                        break
                    end
            	end
            end
            
            local chapterCfg = t_chapter[showID]
            if chapterCfg then
                local item_widget = list_item_widget:clone()
                widgetUtil.widgetReader(item_widget)
                item_widget:setTag(showID) --保存章节ID
                item_widget.Panel_boss:setVisible(false)
                item_widget.Panel_activity:setVisible(true)
                item_widget._state = state
                if state == 1 then --上架状态
                    item_widget.image_activity_lock:setVisible(true)--锁定
                elseif state == 2 then
                    item_widget.image_activity_lock:setVisible(true)--锁定
                elseif state == 3 then
                    item_widget.image_activity_lock:setVisible(false)--解锁
                    --[[
                    local path = string.format("res/fuben_activity/%d.png", chapterCfg.tip_image)
                    if cc.FileUtils:getInstance():isFileExist(path) then
                        item_widget.image_lock_desc:loadTexture(path)
                    end
                    ]]
                end
                
                local pathTip = string.format("res/fuben_activity/%d.png", chapterCfg.tip_image)
                if cc.FileUtils:getInstance():isFileExist(pathTip) then
                    item_widget.image_lock_desc:loadTexture(pathTip)
                end

                --副本图片
                local path = string.format("res/chapter_bg/%d.png", chapterCfg.bg)
                if cc.FileUtils:getInstance():isFileExist(path) then
                    item_widget.image_fuben_activity:loadTexture(path)
                end

                pageView:addPage(item_widget)
                self:scalePageView(index, true)
                index = index +1
            end
        end
    end

    pageView:scrollToPage(1)
end

function CopyActivityWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_CopyActivityWidget_on_close_click",function(event)CopyActivityWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_CopyActivityWidget_on_fight_click",function(event)CopyActivityWidget.onFight(self,event)end)
    eventUtil.addCustom(self._widget,"ui_CopyActivityWidget_on_tili_click",function(event)CopyActivityWidget.onTili(self,event)end)
    eventUtil.addCustom(self._widget,"ui_CopyActivityWidget_on_diamond_click",function(event)CopyActivityWidget.onDiamond(self,event)end)
    eventUtil.addCustom(self._widget,"ui_CopyActivityWidget_on_gold_click",function(event)CopyActivityWidget.onGold(self,event)end)
end

function CopyActivityWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function CopyActivityWidget:onClose(event)
    commonUtil.playBakGroundMusic(1001)
    UIManager.popWidget()
end

--开打
function CopyActivityWidget:onFight(event)
    local index = self._widget.PageView_boss:getCurPageIndex()
    local item = self._widget.PageView_boss:getPage(index)
    local curID = item:getTag()
    local state = item._state
    
    if state ~= 3 then
        self:showTip("副本未解锁！")
        return
    end
    
    self:request("copy.copyHandler.chapterEntry", {chapter = curID}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('copyWidget', {chapterID = curID, copyID = 0}, true)
            self._curChapterID = curID
        end
    end)
end

--购买体力
function CopyActivityWidget:onTili(event)
    UIManager.pushWidget('tiliBuyWidget', {}, true)
end

--购买钻石
function CopyActivityWidget:onDiamond(event)
    UIManager.pushWidget('rechargeWidget', {}, true)
end

--购买金币
function CopyActivityWidget:onGold(event)
    UIManager.pushWidget('goldBuyWidget', {}, true)
end

--刷新面板次数
function CopyActivityWidget:updateCurItem(index)
    local item = self._widget.PageView_boss:getPage(index)
    if not item then
    	return
    end
    
    local chapterID = item:getTag()
    local state = item._state

    --剩余次数
    local chapterCfg = t_chapter[chapterID]
    local useNum = Copy.getCharpterFightNum(chapterID)
    local showNum = chapterCfg.day_count - useNum
    if showNum < 0 then
        showNum = 0
    end
    self._widget.label_day_count:setString(showNum.."/"..chapterCfg.day_count)

    --消耗的体力
    self._widget.label_copy_tili:setString(tostring(chapterCfg.cost_tili))
    
    --[[local timeInfo = Copy.getActivity(chapterID)
    local bill = timeInfo["bill"]
    local startTime = timeInfo["startTime"]
    local endTime = timeInfo["endTime"]
]]
    if chapterCfg.type == Const.CHAPTER_TYPE.BOSS then --boss
        if state == 3 then
            --BOSS血量
            local lostHp = Copy.getCharpterBossHP(chapterID)
            local totalHp, bossName = Copy.getCharpterBossTotalHP(chapterID)
            item.label_hp_num:setString((totalHp - lostHp).."/"..totalHp)
            local percent = (totalHp - lostHp)/totalHp * 100
            item.progress_hp:setPercent(percent)
        end
    elseif chapterCfg.type == Const.CHAPTER_TYPE.ACTIVITY then --活动

    end
end

--更新体力
function CopyActivityWidget:updateStrength()
    --体力
    local max = t_parameter.strength_max.var
    local tili = string.format("%d/%d",Character.strength, max)
    self._widget.label_tili:setString(tili)  
end

--更新信息
function CopyActivityWidget:updateInfo()
    local widget=self._widget  
    --金币
    widget.label_gold:setString(tostring(Character.gold))
    --钻石
    widget.label_diamond:setString(tostring(Character.diamond))
end

--缩放某列表项
function CopyActivityWidget:scalePageView(index, scale)
    local item = self._widget.PageView_boss:getPage(index)
    if item then
        local obj
        if item.Panel_activity:isVisible() then
            obj = item.Panel_activity
        else
            obj = item.Panel_boss
        end
        
        obj:setAnchorPoint(0.5, 0)
        if scale then
            obj:setScale(0.8)
        else
            obj:setScale(1.0)
        end
    end
end

--列表滚动
function CopyActivityWidget:pageViewScroll()
    local index = self._widget.PageView_boss:getCurPageIndex()
    self:updatePageView(index)
end

--更新选中
function CopyActivityWidget:updatePageView(newIndex)
    if self._index == newIndex then
        return 
    end

    if self._index then
        self:scalePageView(self._index, true)
    end

    self:scalePageView(newIndex, false)

    self._index = newIndex
    
    self:updateCurItem(newIndex)
end

return CopyActivityWidget