--Module require
local t_item = require('config/t_item')
local t_chapter = require('config/t_chapter')
local t_chapter_fuben = require('config/t_chapter_fuben') 
local t_story = require('config/t_story')
local t_music=require("config/t_music")

local BaseWidget = require('widget.BaseWidget')

local CopyWidget = class("CopyWidget", function()
    return BaseWidget:new()
end)

function CopyWidget:create(save, opt)
    return CopyWidget.new(save, opt)
end

function CopyWidget:getWidget()
    return self._widget
end

function CopyWidget:onSave()
    local save = {}
    save["chapter"] = self._ChapterID
    save["starTip"] = self._starTip
    save["nextOpen"] = self._nextOpen
    save["copy"] = self._CopyID
    return save
end

function CopyWidget:onResume(event)
    local stay = Copy.getChapterStay(self._ChapterID)
    self:updateCopyItem(stay)--更新节点信息

    local pass = Copy.isCopyItemPass(self._ChapterID, stay) --判断本副本是否通关
    if pass then
        --eventUtil.dispatchCustom("ui_copy_event")
        self:onEvent()
        
        if self._starTip then
            self._starTip = false
            local starsHad, starsTotal = Copy.getCharpterStar(self._ChapterID)
            if starsHad == starsTotal then
                UIManager.pushWidget('fubenChapterReward2', {chapter = self._ChapterID}, true)
            end
        end
    end
    
    local musicID = t_chapter[self._ChapterID]["music"]
    commonUtil.playBakGroundMusic(musicID)
end


function CopyWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    --已创建副本节点
    self._CopyCreateItems = {}

    local showCloud = false
    
    if save._save then
        --副本节点ID
        self._ChapterID = save._save["chapter"]
        self._CopyID = save._save["copy"]
        self._starTip = save._save["starTip"]
        self._nextOpen = save._save["nextOpen"]
    else
        --副本节点ID
        self._ChapterID = opt["chapterID"]
        self._CopyID = opt["copyID"]
        self._starTip = false
        self._nextOpen = false

        if opt["cloud"] then
            showCloud = true
        end
    end
    
    --所有副本节点
    self._copyItems = Copy.getCopyItems(self._ChapterID)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben.csb")
    widgetUtil.widgetReader(self._widget)

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    --退出副本界面
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copy_on_back_click")
        end
    end)
    
    --重置按钮
    self._widget.btn_reset:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copy_on_reset_click")
        end
    end)
    
    --前进按钮
    self._widget.btn_go:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copy_on_go_click")
        end
    end)
    
    self._item = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_item.csb")
    self._item:retain()
    
    self._widget.label_chaper:setString(t_chapter[self._ChapterID]["name3"])
    
    --创建副本节点
    self:makeCopyItem()

    --体力值
    self:updateStrength()
    --星级总和
    self:updateStars()
    
    --初始化玩家图标
    self:initPlayerPos()
    
    self:showItemTips()
    
    local musicID = t_chapter[self._ChapterID]["music"]
    commonUtil.playBakGroundMusic(musicID)
    
    self._widget.image_go:runAction(cc.RepeatForever:create(cc.RotateBy:create(10,360)))

    --云层
    local sizeParent = self._widget:getContentSize()

    if showCloud then
        self._cloud = cc.Sprite:create("res/ui/chapter_img11.png")
        self._cloud:setPosition(cc.p(sizeParent.width/2, sizeParent.height/2))
        self._widget:addChild(self._cloud, 100)

        local  sizeCloud = self._cloud:getContentSize()

        local inCopy = function()
        end
        local move = cc.MoveBy:create(1, cc.p(sizeParent.width/2+sizeCloud.width/2, 0))
        local toCopy = cc.Sequence:create(cc.EaseSineInOut:create(move), cc.CallFunc:create(inCopy), cc.RemoveSelf:create())
        self._cloud:runAction(toCopy)
    end    
end

function CopyWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_copy_on_back_click",function(event)CopyWidget.back(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copy_on_reset_click",function(event)CopyWidget.onReset(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copy_on_go_click",function(event)CopyWidget.onGo(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copy_event",function(event)CopyWidget.onEvent(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copy_quick_fight",function(event)CopyWidget.onQuickFight(self,event)end)
    
    --监听用户体力
    self:subscribe(Const.EVENT.STRENGTH, function ()
        self:updateStrength()
    end)
end

function CopyWidget:onExit()
    self._item:release()
    self._player:release()
    eventUtil.removeCustom(self._widget)
end

--退出当前界面
function CopyWidget:back(event)
    UIManager.popWidget()
end

--重置按钮
function CopyWidget:onReset(event)
    self:request("copy.copyHandler.reset", {chapter = self._ChapterID}, function(msg)
        if msg['code'] == 200 then
           local item = self._CopyCreateItems[self._start]
           if item then
                local x, y = item:getPosition()
                local size = item:getContentSize()
                local offx = size.width/2
                local offy = size.height/2
                self._player:setPosition(cc.p(x+offx, y+offy))
                self._showTip = nil
           end
        end
    end)
end

--前进按钮
function CopyWidget:onGo(event)
    if Character.strength == 0 then
        widgetReader.showTip("体力不足!")
        return
    end
    
    local stay = Copy.getChapterStay(self._ChapterID)
    if not Copy.isCopyItemPass(self._ChapterID, stay) then
       local starsHad, starsTotal = Copy.getCharpterStar(self._ChapterID)
       if starsHad < starsTotal then
           self._starTip = true
       end
       
       --查询下一章节是否开启
        local nextID = Copy.getNextChapterID(self._ChapterID)
        if t_chapter[nextID] then
            self._nextOpen = Copy.isClearance(t_chapter[nextID]["open_instance"])--章节是否开启
        else
            self._nextOpen = true
        end
       
       UIManager.pushWidget('copyFightWidget', {chapterID = self._ChapterID, copyID = stay}, true)
       return
    end

    self:request("copy.copyHandler.forward", {chapter = self._ChapterID}, function(msg)
        if msg['code'] == 200 then
            local stay = Copy.getChapterStay(self._ChapterID)
            self:updatePlayerPos(stay)
        end
    end)
end

--更新体力值
function CopyWidget:updateStrength()
    self._widget.label_tili:setString(tostring(Character.strength)..string.format("/%d", Const.MAX_STRENGTH))
end

--更新星级总和
function CopyWidget:updateStars()
    local star = 0 --当前副本星级
    local copys = Copy.getCopys(self._ChapterID)
    if copys then
        for copyID, cf in pairs(copys) do
            local cfg = self._copyItems[copyID]
            if (cfg and cfg["type"] == Const.COPY_TYPE.BIG_FIGHT) then
                star = star + cf["star"]
            end
        end
    end

    local num = 0 --副本总星级
    local copyList = self._copyItems
    for copyID, cfg in pairs(copyList) do
        if cfg["type"] == Const.COPY_TYPE.BIG_FIGHT then
    		num = num +1
    	end
    end
    
    self._widget.label_star:setString(star.."/"..num*3)
end

--创建副本节点
function CopyWidget:makeCopyItem()
    local maxX = 0 --最大副本节点的X坐标,滚动限制用
    local copyList = self._copyItems
    assert(copyList, "no copy item info")
    for copyID, cfg in pairs(copyList) do
        local item = self._item:clone()
        widgetUtil.widgetReader(item)
        --保存副本节点
        self._CopyCreateItems[copyID] = item
        
        local path = "res/fuben/"..cfg["floor_id"]..".png"
        item.image_floor:loadTexture(path)
        item.Panel_star:setVisible(false)
        
        if cfg["type"] == Const.COPY_TYPE.START then
            self._start = copyID --默认起始点编号
        elseif cfg["type"] == Const.COPY_TYPE.BOX then
            local box = cc.Sprite:create("fuben/fuben_bg6.png")
            if box then
                item:addChild(box)
            end
        elseif cfg["type"] == Const.COPY_TYPE.BIG_FIGHT then
            item.Panel_star:setVisible(true)
            
            self:updateCopyItem(copyID)--更新节点信息
        end
        
        --点击战斗
        if cfg["type"] == Const.COPY_TYPE.SMALL_FIGHT or cfg["type"] == Const.COPY_TYPE.BIG_FIGHT
            or cfg["type"] == Const.COPY_TYPE.HP_BOSS then
            item.Button_Fight:setTag(copyID) --战斗
            item.Button_Fight:addTouchEventListener(function(sender, eventType) 
                if eventType == ccui.TouchEventType.ended then
                    local tag = sender:getTag()
                    eventUtil.dispatchCustom("ui_copy_quick_fight", {copyID = tag})
                end
            end)
        end
        
        --较正item位置
        local size = item:getContentSize()
        local offsetX = size.width / 2
        local offsetY = size.height / 2
        
        local x = cfg['position_x']
        local y = cfg['position_y']
        item:setPosition(x-offsetX, y-offsetY)

        self._widget.panel_map:addChild(item, self:getZOrder(y))
        
        if x > maxX then
            maxX = x
        end
    end
    
    local seizePanel = self._widget.scroll_map:getContentSize()
    if maxX > seizePanel.width then 
        seizePanel.width = maxX + 50
    end
    
    self._widget.scroll_map:setInnerContainerSize(cc.size(seizePanel.width, seizePanel.height ))
end

function CopyWidget:getZOrder(y)
    return math.abs(0xFFFF-y)
end

--更新节点信息
function CopyWidget:updateCopyItem(copyID)
    local cfg = self._copyItems[copyID]
    if not cfg then
        return
    end
    
    local item = self._CopyCreateItems[copyID]
    if nil == item then
        return
    end

    item.image_star1:setVisible(false)
    item.image_star2:setVisible(false)
    item.image_star3:setVisible(false)

    --设置星级
    local star = Copy.copyItemStars(self._ChapterID, copyID)
    if star == 1 then
        item.image_star1:setVisible(true)
    elseif star == 2 then
        item.image_star1:setVisible(true)
        item.image_star2:setVisible(true)
    elseif star == 3 then
        item.image_star1:setVisible(true)
        item.image_star2:setVisible(true)
        item.image_star3:setVisible(true)
    end
end

--初始化玩家坐标
function CopyWidget:initPlayerPos()
    self._player = cc.Sprite:create("res/common/common_player.png")
    self._player:retain()
    self._player:setAnchorPoint(cc.p(0.7, 0.1))
    self._widget.panel_map:addChild(self._player, 0xFFFF)

    local stayID = 0
    local chapterInfo = Copy.getChapter(self._ChapterID)
    if chapterInfo then
        stayID = chapterInfo["stay"]
    end

    if stayID == 0 then
        stayID = self._start
    end

    local item = self._CopyCreateItems[stayID]
    if item then
        local x, y = item:getPosition()
        local size = item:getContentSize()
        local offx = size.width/2
        local offy = size.height/2
        self._player:setPosition(cc.p(x+offx, y+offy))
    end
end

--更新玩家的坐标
function CopyWidget:updatePlayerPos(copyID)
    local item = self._CopyCreateItems[copyID]
    if item then
        local x, y = item:getPosition()
        local size = item:getContentSize()
        local offx = size.width/2
        local offy = size.height/2
        self._player:runAction(cc.Sequence:create(cc.JumpTo:create(0.5, cc.p(x+offx, y+offy), 20, 1), cc.CallFunc:create(function() self:playerJumpOver() end, self)))
    end
end

function CopyWidget:playerJumpOver()
    local stay = Copy.getChapterStay(self._ChapterID)
    local cfg = self._copyItems[stay]
    if not cfg then
        return
    end

    local storyId=t_chapter_fuben[self._ChapterID][stay].story
    if storyId~="" then
        if  Copy.isPlayFuStory(self._ChapterID,stay) then
            self:createStory(storyId,1,stay,cfg)
            local req = {}
            req["chapter"] = self._ChapterID
            req["id"] = stay
            self:notify("copy.copyHandler.story", req, function(msg)
                end)
            Copy.setFuStoryAlready(self._ChapterID,stay)
        else
            self:outStory(stay,cfg)
        end 
    else
        self:outStory(stay,cfg)
    end     
end

--剧情播完后
function CopyWidget:outStory(stay,cfg)
    if cfg["type"] == Const.COPY_TYPE.SMALL_FIGHT or cfg["type"] == Const.COPY_TYPE.BIG_FIGHT or cfg["type"] == Const.COPY_TYPE.HP_BOSS then
        local starsHad, starsTotal = Copy.getCharpterStar(self._ChapterID)
        if starsHad < starsTotal then
            self._starTip = true
        end

        --查询下一章节是否开启
        local nextID = Copy.getNextChapterID(self._ChapterID)
        
        if t_chapter[nextID] then
            self._nextOpen = Copy.isClearance(t_chapter[nextID]["open_instance"])--章节是否开启
        else
            self._nextOpen = true
        end

        UIManager.pushWidget('copyFightWidget', {chapterID = self._ChapterID, copyID = stay}, true)
    else
        local items = Item.getRewardItems()
        if not items or (#items == 0) then
            widgetUtil.showTip("很遗憾，没有获得奖品哦！")
            --eventUtil.dispatchCustom("ui_copy_event")
            self:onEvent()
        else
            UIManager.pushWidget('getItemWidget', nil, true)
        end
    end
end

--创建剧情
function CopyWidget:createStory(storyId,nextId,stay,cfg) 
    if t_story[storyId] then
        if self._widgetStory == nil then
            self._widgetStory= ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIstory.csb")
            widgetUtil.widgetReader(self._widgetStory)

            self._widget:addChild(self._widgetStory, 10)        
        end
        local widget=self._widgetStory

        local story=t_story[storyId][nextId]

        widget:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then             
                self:createStory(storyId,story.next_id,stay,cfg)
            end
        end)

        if story then
            local icon=string.format("res/story_icon/%d.png",story.hero_icon)
            if cc.FileUtils:getInstance():isFileExist(icon) then
                widget.image_icon:loadTexture(icon)  
            end

            local bg=string.format("res/img/%d.png",story.hero_bg)
            if story.hero_bg~=0 then
                if cc.FileUtils:getInstance():isFileExist(bg) then
                    widget.image_hero:loadTexture(bg)
                end
            end    

            widget.label_name1:setString(story.name)   --当前英雄名字
            widget.label_name2:setString(story.name)   --当前英雄名字
            widget.label_desc:setString(story.desc)   --当前英雄说的话

            widget.btn_next:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then             
                    self._widgetStory:runAction(cc.RemoveSelf:create())
                    self._widgetStory=nil
                    self:outStory(stay,cfg)
                end
            end)
        else
            if self._widgetStory then
                self._widgetStory:runAction(cc.RemoveSelf:create())
                self._widgetStory=nil
            end
            self:outStory(stay,cfg)
        end
    else
        self:outStory(stay,cfg)
    end 
end

function CopyWidget:onEvent(event)
    local copyID = Copy.getChapterStay(self._ChapterID)
    local cfg = self._copyItems[copyID]
    if not cfg then
        return
    end
    
    if cfg["line"] then
        --local pass = Copy.isCopyItemPass(self._ChapterID, copyID) --判断本副本是否通关
        if cfg["line"][1] == 1 then --已经通关！
            if self._nextOpen then --下一章已通关
                if not self._showTip then
                    self._showTip = true
                    UIManager.pushWidget('fubenChapterReward3', nil, true)
                end
            else
                local nextID = Copy.getNextChapterID(self._ChapterID)
                if t_chapter[nextID] then
                local open = Copy.isClearance(t_chapter[nextID]["open_instance"])--章节是否开启
                    if open then --下一关开启
                        if not self._showTip then
                            self._showTip = true
                            UIManager.pushWidget('fubenChapterReward1', {charpterID = self._ChapterID}, true)
                        end
                    end
                end
            end
        elseif cfg["type"] ~= Const.COPY_TYPE.EMPTY and cfg["line"][1] == 0 then
            if ( not self._showTip ) then
                self._showTip = true
                UIManager.pushWidget('fubenChapterReward3', nil, true)
            end
        end
    end
end

--快速战斗
function CopyWidget:onQuickFight(event)
    local copyID = event.param.copyID
    local stay = Copy.getChapterStay(self._ChapterID) --当前停留点
    local star = Copy.copyItemStars(self._ChapterID, copyID)
    
    local cfg = self._copyItems[copyID]
    if not cfg then
        return
    end
    
    if cfg["type"] == Const.COPY_TYPE.BIG_FIGHT then
        if copyID ~= stay and star == 0 then
            self:showTip("通关该副本后才可以进行快速战斗哦！")
            return
        end
        
        UIManager.pushWidget('copyFightWidget', {chapterID = self._ChapterID, copyID = copyID}, true)
    else
        --self:showTip("只有星级副本才可以进行快速战斗哦！")
        return
    end
end

function CopyWidget:showItemTips()
    if self._CopyID > 0 then
        local copy = self._copyItems[self._CopyID]
        if copy then
            local show = copy["fuben_item"]
            if show and show[1] then
                --弹出显示
                local sp = cc.Sprite:create("res/common/down.png")
                local item = self._CopyCreateItems[self._CopyID]
                if sp and item then
                    sp:setAnchorPoint(cc.p(0.5, 0))
                    local x, y = item:getPosition()
                    local size = item:getContentSize()
                    local offx = size.width/2
                    local offy = size.height/2
                    self._widget.panel_map:addChild(sp, 0xFFFF)
                    sp:setPosition(cc.p(x+offx, y+offy))
                    sp:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(0.5,cc.p(0,-20)), cc.MoveBy:create(0.5,cc.p(0,20)))))
                end
            end
        end
    end
end

return CopyWidget

