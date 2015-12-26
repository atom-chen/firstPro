local t_chapter = require('config.t_chapter')
local t_chapter_fuben = require('config/t_chapter_fuben')
local t_story = require('config/t_story')
local t_music=require("config/t_music")

local BaseWidget = require('widget.BaseWidget')

local ChapterWidget = class("ChapterWidget", function()
    return BaseWidget:new()
end)

function ChapterWidget:create(save, opt)
    return ChapterWidget.new(save, opt)
end

function ChapterWidget:getWidget()
    return self._widget
end

function ChapterWidget:onEnter()
    local sizeParent = self._widget:getContentSize()
    local sizeMap = self._widget.panel_map:getContentSize()

    local index = 0
    for i=1, #self._ChapterItemsCfg do
        if self._ChapterItemsCfg[i] == self._curChapter then
            index = i
            break
        end
    end
    if 0 == index then
        block = sizeMap.width
    else
        block = sizeMap.width / (#self._ChapterItemsCfg/3) * (index/3) + sizeParent.width
        if block > sizeMap.width then
            block = sizeMap.width
        end
        local min = sizeParent.width * 1.2
        if block < min then
            block = min
        end
    end
    
    local mapx, mapy = self._widget.panel_map:getPosition()
    self._widget.panel_map:setPosition(cc.p(-(sizeMap.width-block), mapy))

    self._widget.scroll_map:setInnerContainerSize(cc.size(block, 640))
    self._widget.scroll_map:scrollToPercentHorizontal(100, 0, false)

    local eventDispatcher = self._widget:getEventDispatcher()
    
    --监听用户体力
    self:subscribe(Const.EVENT.STRENGTH, function ()
        self:updateStrength()
    end)

    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_chapter_on_back_click",function(event) ChapterWidget.back(self, event) end), 1)
    eventUtil.addCustom(self._widget,"ui_chapter_widget_on_story_click",function(event)ChapterWidget.onStoryClick(self,event)end)
end

function ChapterWidget:onExit()
    --副本节点模版
    self._itemWidget:release()
    
    --副本连线模版
    self._line_dark:release()
    self._line_bright:release()

    self._widget:getEventDispatcher():removeCustomEventListeners("ui_chapter_on_back_click")
    eventUtil.removeCustom(self._widget)
end

function ChapterWidget:back()
    UIManager.popScene()
end

function ChapterWidget:onStoryClick()
    self:showTip(Str.FUNCTION_NOT_OPEN)
end

function ChapterWidget:init()
    --补两张背景图
    self._widget.image_map3:loadTexture("res/ui/chapter_img3.png")
    self._widget.image_map4:loadTexture("res/ui/chapter_img4.png")

    --建立剩余副本点
    self:setupChapterItem()

    --建立副本连线
    self:setupLines()
end

function ChapterWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchapter.csb")
    widgetUtil.widgetReader(self._widget)

    --更新体力
    self:updateStrength()

    --更新星级
    self:updateStars()
    
    --副本节点偏移
    self._OffsetX = 0
    self._OffsetY = 0

    --已创建副本节点
    self._ChapterItems = {}
    --副本节点连线
    self._ChapterLines = {}

    --（查表）副本有序节点
    self._ChapterItemsCfg = Copy.getChapterItems()
    --assert(#self._ChapterItemsCfg > 0)

    --找到第一个未通关副本
    --当该值为0时，全副本通关
    self._curChapter = 0
    self:updateCurChapter()

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    --关闭按钮
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if not self._cloudMoving then
                self:back()
            end
        end
    end)

    --剧情
    self._widget.btn_story:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if not self._cloudMoving then
                eventUtil.dispatchCustom("ui_chapter_widget_on_story_click")
            end
        end
    end)

    --副本点模版
    self._itemWidget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchapter_item.csb")
    self._itemWidget:retain()

    --连线灰图片
    self._dark_line_image = "res/ui/chapter_img5.png"
    self._bright_line_image = "res/ui/chapter_img6.png"

    --副本连线模版
    self._line_dark = ccui.ImageView:create(self._dark_line_image)
    self._line_dark:retain()
    self._line_bright = ccui.ImageView:create(self._bright_line_image)
    self._line_bright:retain()

    --要求一致宽度
    self._LineWidth = self._line_bright:getContentSize().width

    --建立副本点
    self:setupChapterItem({1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1014})

    --建立副本连线
    self:setupLines()

    local sizeParent = self._widget:getContentSize()

    --云层正在移动(正在进入副本)
    self._cloudMoving = false
    
    self._cloud = cc.Sprite:create("res/ui/chapter_img11.png")
    local sizeCloud = self._cloud:getContentSize()
    self._cloud:setPosition(cc.p(300-sizeCloud.width/2, sizeParent.height/2))
    self._widget:addChild(self._cloud, 100)

    performWithDelay(self._widget.scroll_map,function() 
        self._widget.scroll_map:runAction(cc.CallFunc:create(function() self:init() end, self))
    end,0)
end

function ChapterWidget:updateCurChapter()
    --找到第一个未通关副本
    --当该值为0时，全副本通关
    local last = self._curChapter
    for i=1, #self._ChapterItemsCfg do
        if not Copy.isClearance(self._ChapterItemsCfg[i]) then
            self._curChapter = self._ChapterItemsCfg[i]
            break
        end
    end
    
    if last == 0 or last == self._curChapter then
        return
    end

    --有新的章节节点开放
    local index = 0
    for i=1, #self._ChapterItemsCfg do
        if self._ChapterItemsCfg[i] == last then
            index = i
            break
        end
    end

    if index < #self._ChapterItemsCfg then
        local chapter = self._ChapterItemsCfg[i]
        local from = t_chapter[chapter]['line']
        if from > 0 then
            self:updateChapterLine(from, chapter, true)
        end

        self:updateChapterItem(from)
        self:updateChapterItem(to)
    end
end

--从其它界面返回
function ChapterWidget:onResume()
    self:updateCurChapter()
    
    --更新体力
    self:updateStrength()

    --更新星级
    self:updateStars()
    
    commonUtil.playBakGroundMusic(1010)
end

--创建副本节点
function ChapterWidget:makeChapterLine(fromID, toID, bright)
    --assert(fromID<=40000, 'invalid chapter id, must less than 40000')
    --assert(toID<=40000, 'invalid chapter id, must less than 40000')
    if fromID > 40000 or toID > 40000 then
        assert(false, 'invalid chapter id, must less than 40000')
        return
    end

    if self._ChapterLines[fromID * toID] then
        return
    end
    
    local itemFrom = self._ChapterItems[fromID]
    local itemTo = self._ChapterItems[toID]
    
    if not itemFrom or not itemTo then
        return
    end
    
    local posFromX, posFromY = itemFrom:getPosition()
    local posToX, posToY = itemTo:getPosition()
    
    --较正位置
    posFromX = posFromX + self._OffsetX
    posFromY = posFromY + self._OffsetY
    
    posToX = posToX + self._OffsetX
    posToY = posToY + self._OffsetY
    
    local dir = cc.pSub(cc.p(posToX, posToY), cc.p(posFromX, posFromY))
    local len = cc.pGetLength(dir)
    --中点
    local midPoint = cc.pMidpoint(cc.p(posToX, posToY), cc.p(posFromX, posFromY))
    --缩放比例
    local scaleX = math.floor( len / self._LineWidth)
    --旋转
    local rotate = commonUtil.getAngle(dir)
    
    local line
    if bright then
        line = self._line_bright:clone()
    else
        line = self._line_dark:clone()
    end
    line:setScaleX(scaleX)
    line:setPosition(midPoint.x, midPoint.y)
    line:setRotation(rotate)
    
    --assert(not self._ChapterLines[fromID * toID], 'error occur')
    
    self._ChapterLines[fromID * toID] = line
    
    self._widget.panel_map:addChild(line, 1)
end

function ChapterWidget:updateChapterLine(from , to, bright)
    local line = self._ChapterLines[from * to]
    if bright then
        line:loadTexture(self._bright_line_image)        
    else
        line:loadTexture(self._dark_line_image)
    end
end

--创建单个副本节点
function ChapterWidget:makeChapterItem(id)
    local config = t_chapter[id]
    
    local x = config['position_x']
    local y = config['position_y']
    
    local item = self._itemWidget:clone()
    
    --较正item位置
    if self._OffsetX == 0 then
        local size = self._itemWidget:getContentSize()
        self._OffsetX = size.width / 2
        self._OffsetY = size.height / 2
    end
    
    --local label_name = ccui.Helper:seekWidgetByName(item, "label_name")
    --label_name:setString(config['name'])
    
    local star_full = ccui.Helper:seekWidgetByName(item, "image_star_full")
    star_full:setVisible(false)
    
    local panel_star = ccui.Helper:seekWidgetByName(item, "Panel_star") --星级   
    panel_star:setVisible(false)
    
    item:setPosition(x-self._OffsetX, y-self._OffsetY)
    
    --增加点击响应，跳转到副本节点界面
    local btn_item = ccui.Helper:seekWidgetByName(item, "btn_item")
    --以副本章节编号作为标识
    btn_item:setTag(id)
    btn_item:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if not self._cloudMoving then
                self:showCopyWidget(sender:getTag())
            end
        end
    end)
    
    --副本节点icon
    local image_icon = item:getChildByName("image_icon")
    local sizeIcon = image_icon:getContentSize()
    
    local icon = cc.Sprite:create("res/chapter_icon/" .. id .. ".png")
    icon:setPosition(sizeIcon.width/2, sizeIcon.height/2)
    icon:setAnchorPoint(0.5, 0.5)

    image_icon:addChild(icon, 0, 1)
    
    --保存副本节点
    self._ChapterItems[id] = item
    
    self._widget.panel_map:addChild(item, 2)
end

function ChapterWidget:updateChapterItem(chapter)
    local item = self._ChapterItems[chapter]
    if nil == item then
        return
    end
    
    --local image_item1 = ccui.Helper:seekWidgetByName(item, "image_item1") --S
    --local image_item2 = ccui.Helper:seekWidgetByName(item, "image_item2") --A
    --local image_item3 = ccui.Helper:seekWidgetByName(item, "image_item3") --B
    --local image_item4 = ccui.Helper:seekWidgetByName(item, "image_item4") --C
    
    --image_item1:setVisible(false)
    --image_item2:setVisible(false)
    --image_item3:setVisible(false)
    --image_item4:setVisible(false)

    local star_full = ccui.Helper:seekWidgetByName(item, "image_star_full")
    star_full:setVisible(false)
    
    local image_icon = ccui.Helper:seekWidgetByName(item, "image_icon")
    local icon = image_icon:getChildByTag(1)
    
    local image_item_new = ccui.Helper:seekWidgetByName(item, "image_item_new") --new  
    local panel_star = ccui.Helper:seekWidgetByName(item, "Panel_star") --星级   
    panel_star:setVisible(false)
    
    if self._curChapter == chapter then --新攻打
        widgetUtil.restoreGreySprite(icon)  
        image_item_new:setVisible(true)   
           
        panel_star:setVisible(true)
        local starsHad, starsTotal = Copy.getCharpterStar(chapter)
        local starLabel = ccui.Helper:seekWidgetByName(panel_star, "label_star_num")
        starLabel:setString(starsHad.."/"..starsTotal)
        if starsTotal > 0 and starsHad == starsTotal then
            star_full:setVisible(true)
        end
        
        return
    end    
    
    image_item_new:setVisible(false)

    local copy = Copy.getCopy(chapter)    
    if nil == copy then --未攻打
        widgetUtil.greySprite(icon)
        return
    end
    
    --计算已攻打的副本的星级
    panel_star:setVisible(true)
    local starsHad, starsTotal = Copy.getCharpterStar(chapter)
    local starLabel = ccui.Helper:seekWidgetByName(panel_star, "label_star_num")
    starLabel:setString(starsHad.."/"..starsTotal)
    if starsTotal > 0 and starsHad == starsTotal then
        star_full:setVisible(true)
    end
end

--建立副本点
function ChapterWidget:setupChapterItem(chapters)
    for i=1, #self._ChapterItemsCfg do
        local chapter = self._ChapterItemsCfg[i]
        if not self._ChapterItems[chapter] then
            local draw = false
            if chapters then
                for j=1, #chapters do
                    if chapters[j] == chapter then
                        draw = true
                        break
                    end
                end
            else
                draw = true
            end

            if draw then
                self:makeChapterItem(chapter)
                self:updateChapterItem(chapter)
            end
        end        
    end
end

--建立副本连线
function ChapterWidget:setupLines()
    for i=1, #self._ChapterItemsCfg do
        local chapter = self._ChapterItemsCfg[i]
        local from = t_chapter[chapter]['line']
        if from > 0 and not self._ChapterLines[from * chapter] then
            local bright = false
            local copy = Copy.getCopy(chapter)
            if nil ~= copy or self._curChapter == chapter then
                bright = true                
            end

            self:makeChapterLine(from, chapter, bright)
        end        
    end
end

--创建剧情
function ChapterWidget:createStory(storyId,nextId) 
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
                self:createStory(storyId,story.next_id)
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
                    self:openCopy(self.curCharpterId)
                end
            end)
        else
            if self._widgetStory then
                self._widgetStory:runAction(cc.RemoveSelf:create())
                self._widgetStory=nil
            end
            self:openCopy(self.curCharpterId)    
        end
    else
        self:openCopy(self.curCharpterId)
    end 
end


--打开副本节点
function ChapterWidget:showCopyWidget(charpter)
    if t_chapter_fuben[charpter] then
        local preCharpterID = Copy.getPreCharterID(charpter)
        local clearance = Copy.isClearance(preCharpterID)
        if not clearance then
            return
        end
        
        if Copy.isPlayChapterStory(charpter) then
            self.curCharpterId=charpter
            local storyId=t_chapter[charpter].story
            self:createStory(storyId,1)
            local req = {}
            req["chapter"] = charpter
            self:notify("copy.copyHandler.story", req, function(msg)
            end)
            Copy.setChapterStoryAlready(charpter)
        else
            self:openCopy(charpter)    
        end
    end
end

--打开副本
function ChapterWidget:openCopy(charpterID) 
    self:request("copy.copyHandler.chapterEntry", {chapter = charpterID}, function(msg)
        if msg['code'] == 200 then
            self._cloudMoving = true
            local toCopyWidget = function()
                self._cloudMoving = false
                UIManager.pushWidget('copyWidget', {chapterID=charpterID,copyID=0,cloud=1})
            end
            local sizeParent = self._widget:getContentSize()
            local move = cc.MoveTo:create(0.8, cc.p(sizeParent.width/2, sizeParent.height/2))
            local toCopy = cc.Sequence:create(cc.EaseSineInOut:create(move), cc.CallFunc:create(toCopyWidget))
            self._cloud:runAction(toCopy)              
        end
    end)
end

--更新体力值
function ChapterWidget:updateStrength()
    self._widget.label_tili:setString(tostring(Character.strength)..string.format("/%d", Const.MAX_STRENGTH))
end

--更新普通章节星级总和
function ChapterWidget:updateStars()
    local num = 0 --副本总星级
    for chapter, v in pairs(t_chapter) do
        if v['type'] == Const.CHAPTER_TYPE.NORMAL then --普通副本
            local copys = t_chapter_fuben[tonumber(chapter)]
            if copys then
                for copyID, cfg in pairs(copys) do
                    if cfg["type"] == Const.COPY_TYPE.BIG_FIGHT then --大战斗
                        num = num +1
                    end
                end
            end
        end
    end

    self._widget.label_star:setString(Copy.getStars().."/"..num*3)
end

return ChapterWidget

