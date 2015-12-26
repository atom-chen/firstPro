--[[
*           英雄选择界面list
*
]]
--module require
local BaseWidget = require('widget.BaseWidget')
local t_item=require('config/t_item')
local t_chapter=require('config/t_chapter')
local t_chapter_fuben=require('config/t_chapter_fuben')
local t_hero_grade=require('config/t_hero_grade')

local HeroSelectWidget = class("HeroSelectWidget", function()
    return BaseWidget:new()
end)

function HeroSelectWidget:create(save, opt)
    return HeroSelectWidget.new(save, opt)
end

function HeroSelectWidget:getWidget()
    return self._widget
end

function HeroSelectWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_select.csb")
    widgetUtil.widgetReader(self._widget)

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:back()
        end
    end)


    --全部
    self._widget.btn_all:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curAttr = Const.HERO_ATTR_TYPE.NONE
            self:checkBtnState()
        end
    end)
    --水属性
    self._widget.btn_water:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curAttr = Const.HERO_ATTR_TYPE.SHUI
            self:checkBtnState()
        end
    end)
    --火属性
    self._widget.btn_fire:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curAttr = Const.HERO_ATTR_TYPE.HUO
            self:checkBtnState()
        end
    end)
    --木属性
    self._widget.btn_wood:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curAttr = Const.HERO_ATTR_TYPE.MU
            self:checkBtnState()
        end
    end)

    self._widget_select_item = nil 
    self._widget_select_item_soul = nil 
    self._widget_select_img=nil 
    self._widget.coverLayer:setVisible(false)

    self.curAttr = Const.HERO_ATTR_TYPE.NONE
    self:checkBtnState()
end

--更新按键状态
function HeroSelectWidget:checkBtnState()

    local isWater=self.curAttr == Const.HERO_ATTR_TYPE.SHUI
    local isFire=self.curAttr == Const.HERO_ATTR_TYPE.HUO
    local isWood=self.curAttr == Const.HERO_ATTR_TYPE.MU
    local isAll=not (isWater or isFire or isWood)

    self._widget.btn_wood:setEnabled(not isWood)
    self._widget.btn_wood:setBright(not isWood)
    self._widget.btn_fire:setEnabled(not isFire)
    self._widget.btn_fire:setBright(not isFire)        
    self._widget.btn_water:setEnabled(not isWater)
    self._widget.btn_water:setBright(not isWater)
    self._widget.btn_all:setEnabled(not isAll)
    self._widget.btn_all:setBright(not isAll)
    
    self:updateHeroList()
end

--更新列表
function HeroSelectWidget:updateHeroList()
    if nil ~= self._listAction then
        self._widget.list_item:stopAction(self._listAction)
        self._listAction = nil
    end
    self._widget.list_item:setBounceEnabled(true)
    self._widget.list_item:removeAllItems()
    self._widget.list_item:jumpToTop()

    local heroList = Hero.getHeroByAttr(self.curAttr) 
    local row1 = math.ceil(#heroList / 2)
         
    local unheroList=Hero.getUnHeroByAttr(self.curAttr)
    local row2 = math.ceil(#unheroList / 2)
    
    local function listItemMag(row)
        local widget=nil
        if row<=row1 then
            if nil == self._widget_select_item then
                self._widget_select_item = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_select_item.csb")
                self._widget_select_item:retain()
            end
            widget =self._widget_select_item:clone()
            local index = (row-1) * 2
            self:updateHeroInList(widget:getChildByName('bg_item1'), heroList[index+1])
            self:updateHeroInList(widget:getChildByName('bg_item2'), heroList[index+2])
        elseif row==row1+1 then
            if nil == self._widget_select_img then
                self._widget_select_img = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_select_item_img.csb")
                self._widget_select_img:retain()
            end
            widget= self._widget_select_img:clone()
        else
            if nil == self._widget_select_item_soul then
                self._widget_select_item_soul = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_select_item_soul.csb")
                self._widget_select_item_soul:retain()
            end
            widget = self._widget_select_item_soul:clone()
            local index = (row-row1-2) * 2
            self:updateHeroUnInList(widget:getChildByName('bg_item1'),unheroList[index+1])
            self:updateHeroUnInList(widget:getChildByName('bg_item2'),unheroList[index+2])
        end
        self._widget.list_item:pushBackCustomItem(widget)
    end
   
    for i=1, 4 do
        listItemMag(i)
    end
    
    self._listAction = schedule(self._widget.list_item,function ()
        for j=5, row1+row2+1 do
            listItemMag(j)
        end
        
        if nil ~= self._listAction then
            self._widget.list_item:stopAction(self._listAction)
            self._listAction = nil
        end
    end,0)      
end

function HeroSelectWidget:updateHeroInList(item, hero)
    if nil == hero then
        item:setVisible(false)
    else   
        widgetUtil.widgetReader(item)
        local heroInt_hero=Hero.getTHeroByKey(hero._heroID)     
        --按钮
        item.btn_item:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                UIManager.pushWidget('heroWidget',hero._heroID)
            end
        end)
        --头像
        if t_hero_grade[hero._armsLv] then
            local bottom=t_hero_grade[hero._armsLv].bottom
            local grade=t_hero_grade[hero._armsLv].grade

            widgetUtil.createIconToWidget(heroInt_hero.icon,item.image_icon)  --图标 
            widgetUtil.createIconToWidget(bottom,item.image_icon_bottom)  -- 底框
            widgetUtil.createIconToWidget(grade,item.image_icon_grade)  -- 品质框
        end
        
        --等级
        item.label_lv:setString(tostring(hero._lv))
        --姓名       
        item.label_name:setString(tostring(heroInt_hero.name)) 

        --属性
        if hero._attr == Const.HERO_ATTR_TYPE.SHUI then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_SHUI)
        elseif hero._attr == Const.HERO_ATTR_TYPE.HUO then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_HUO)
        elseif hero._attr == Const.HERO_ATTR_TYPE.MU then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_MU)
        end
        --星级
        for i=1, Const.MAX_STAR do
            if i==hero._star then
                item["image_star"..i]:setVisible(true)
            else
                item["image_star"..i]:setVisible(false)
            end
        end

        --当前装备情况
        local curEquip=hero._curEquip   --当前装备栏上的装备情况  
        local needEquip=heroInt_hero["equip"..hero._armsLv]
        item.image_equip_hint:setVisible(false)
        for i=1, 4 do               
            item["image_hint"..i]:setVisible(false)
            if curEquip[i]~=0 then
                widgetUtil.createIconToWidget(t_item[curEquip[i]].icon,item["image_equip"..i])  --图标 
            else
                local equipNum=Item.getNum(needEquip[i])
                if equipNum~=0 then
                    item["image_hint"..i]:setVisible(true)
                    item.image_equip_hint:setVisible(true)
                end
            end
        end
    end
end

function HeroSelectWidget:updateHeroUnInList(item, heroID)
    local hero=Hero.getTHeroByKey(heroID)
    if nil == hero then
        item:setVisible(false)
    else  
        widgetUtil.widgetReader(item)            
        --头像
        widgetUtil.createIconToWidget(hero.icon,item.image_icon)  --图标 
        local icon = item.image_icon:getChildByTag(0x100)
        widgetUtil.greySprite(icon)
        widgetUtil.createIconToWidget(9,item.bg_icon_bottom)  -- 底框
        widgetUtil.createIconToWidget(19,item.bg_icon_grade)  -- 品质框
        --姓名
        item.label_name:setString(tostring(hero.name))     
        --属性
        if hero.type == Const.HERO_ATTR_TYPE.SHUI then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_SHUI)
        elseif hero.type == Const.HERO_ATTR_TYPE.HUO then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_HUO)
        elseif hero.type == Const.HERO_ATTR_TYPE.MU then
            item.image_attribute:loadTexture(Const.HERO_ATTR_BALL_MU)
        end
        --魂石
        local max =hero.soul0
        local soulId=Hero.getHeroSoulStoneItemID(heroID)
        local soulStoneNum=Item.getNum(soulId)     
        local num=string.format("%d/%d",soulStoneNum,max)
        item.label_number:setString(num)

        local percent = soulStoneNum / max * 100
        if percent>100 then
            item.progress_piece:setPercent(100)
        else
            item.progress_piece:setPercent(percent) 
        end
        --按钮
        item.btn_item:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                if soulStoneNum>=max then
                    self:recruitRequest(heroID) 
                else
                    self:createGetSoulWidget(heroID)
                end
            end
        end)

    end
end

--创建获取魂石弹窗界面
function HeroSelectWidget:createGetSoulWidget(heroId)
    local widget=self._widget
    local getSoulWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIitem_reward.csb")
    local size=widget.coverLayer:getContentSize()
    getSoulWidget:setAnchorPoint(cc.p(0.5,0.5))
    getSoulWidget:setPosition(size.width/2,size.height/2)
    widget.coverLayer:setVisible(true)
    widget.coverLayer:addChild(getSoulWidget)
    widgetUtil.widgetReader(getSoulWidget)
    
    getSoulWidget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            getSoulWidget:runAction(cc.RemoveSelf:create())
            getSoulWidget=nil
            widget.coverLayer:setVisible(false)
        end
    end)

    local tHero = Hero.getTHeroByKey(heroId)  --获得配置里的英雄

    getSoulWidget.label_item_name:setString(tostring(tHero.name))   
    --魂石图标    label_chapter_num
    local soulId=Hero.getHeroSoulStoneItemID(heroId)
    if t_item[soulId] then
        widgetUtil.createIconToWidget(t_item[soulId].grade,getSoulWidget.image_item_bottom)   --底框
        widgetUtil.createIconToWidget(t_item[soulId].icon,getSoulWidget.image_item_icon)       
        widgetUtil.createIconToWidget(t_item[soulId].grade+10,getSoulWidget.image_item_grade)   --品质框
    end

    local max =tHero["soul0"] 
    local soulStoneNum=Item.getNum(soulId)
    local numLab=string.format("(%d/%d)",soulStoneNum,max)
    getSoulWidget.label_item_num:setString(numLab)    --魂石数量情况

    for i=1, 3 do   
        local root=tHero["soul_fuben"..i]
        local chapterId=root[1]
        local fuId=root[2]
        
        getSoulWidget["btn_reward"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:openCopyRequest(chapterId,fuId)
            end
        end)
        
        if t_chapter[chapterId] then
            local bg="chapter_icon/"..(t_chapter[chapterId].bg)..".png"
            if cc.FileUtils:getInstance():isFileExist(bg) then
                getSoulWidget["image_chapter_icon"..i]:loadTexture(bg)  
            end
            getSoulWidget["label_chapter_num"..i]:setString(tostring(t_chapter[chapterId].name3))   --章节名
        end
        if t_chapter_fuben[chapterId][fuId] then
            getSoulWidget["label_chapter"..i]:setString(tostring(t_chapter_fuben[chapterId][fuId].name))   --副本名
        end
        
        local lastChapterId=Copy.getPreCharterID(chapterId)
        local charpter = Copy.isClearance(lastChapterId)
        if charpter then
            getSoulWidget["label_lock"..i]:setVisible(false)
        end
    end
end

--转到副本
function HeroSelectWidget:openCopyRequest(charpterId,fuId) 
    self:request("copy.copyHandler.chapterEntry", {chapter = charpterId}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('copyWidget', {chapterID = charpterId, copyID = fuId}, true)  
        end
    end)
end

--请求招募
function HeroSelectWidget:recruitRequest(heroID)
    --发送请求
    local request = {} 
    request["heroID"] = heroID
    self:request("main.heroHandler.recruit", request, function(msg)
        if msg['code'] == 200 then
            self:updateHeroList()
        end
    end)

end

function HeroSelectWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()

    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_hero_select_on_back_click",function(event) HeroSelectWidget.back(self, event) end), 1)
end

function HeroSelectWidget:onExit()
    if self._widget_select_item then
        self._widget_select_item:release()
    end
    if self._widget_select_item_soul then
        self._widget_select_item_soul:release()
    end  
    if self._widget_select_img then
        self._widget_select_img:release()
    end    

    self._widget:getEventDispatcher():removeCustomEventListeners("ui_hero_select_on_back_click")
end

--退出当前界面
function HeroSelectWidget:back()
    UIManager.popWidget()
end

return HeroSelectWidget
