local t_lv =require('config/t_lv')
local t_hero = require('config/t_hero')

local BaseWidget = require('widget.BaseWidget')

local HeroTrainSelectWidget = class("HeroTrainSelectWidget", function()
    return BaseWidget:new()
end)

function HeroTrainSelectWidget:create(save, opt)
    return HeroTrainSelectWidget.new(save, opt)
end

function HeroTrainSelectWidget:getWidget()
    return self._widget
end

function HeroTrainSelectWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    --已创建的英雄位置
    self._PosItems = {}

    self._widget = widgetUtil.registCsbPanel("UItrain_hero_select")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    self._widget.pos = opt["pos"]
    self._widget.heroID = opt["heroID"]

    --退出按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainSelectWidget_on_close_click")
        end
    end)
    
    self._widget.item = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UItrain_hero_select_item.csb")
    self._widget.item:retain()
    
    self:showHero()
end

function HeroTrainSelectWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_HeroTrainSelectWidget_on_close_click",function(event)HeroTrainSelectWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainSelectWidget_select_hero",function(event)HeroTrainSelectWidget.onSelectHero(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainSelectWidget_stop_train",function(event)HeroTrainSelectWidget.onStopTrain(self,event)end)
    
    --GameGuide.dispatchEvent(Const.GAME_GUIDE_TYPE.NORMAL)
end

function HeroTrainSelectWidget:onExit()
    self._widget.item:release()
    
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function HeroTrainSelectWidget:onClose(event)
    UIManager.popWidget()
end

--创建英雄列表
function HeroTrainSelectWidget:showHero()
    local heroList = Hero.getHeroList()
    local showNum = 0 --英雄展示的数量
    
    --计算要显示的英雄数量
    local numMax = 0
    for i=1, #heroList do
        if heroList[i]._pos == 0 then --未在训练的英雄
            numMax = numMax +1
        end
    end 
    
    if self._widget.heroID then --该英雄在训练
        numMax = numMax +1
        self:createHeroItem(self._widget.heroID, 1, numMax)
        showNum = 1
        
        --监听训练中的英雄经验
        self:subscribe(Const.EVENT.HERO_EXP, function ()
            self:updateExp()
        end)
    end
    
    for i=1, #heroList do
        if heroList[i]._pos == 0 then --未在训练的英雄
            showNum = showNum +1
            self:createHeroItem(heroList[i]._heroID, showNum, numMax)
        end
    end 
    
    local sizeItem = self._widget.item:getContentSize()
    local seizePanel = self._widget.scroll_map:getContentSize()
    local listHeight = math.ceil(showNum/2) * sizeItem.height
    if listHeight > seizePanel.height then 
        seizePanel.height = listHeight
        self._widget.scroll_map:setInnerContainerSize(cc.size(seizePanel.width, seizePanel.height ))
    end

end

--根据pos计算item摆放位置
function HeroTrainSelectWidget:recordItemPos(pos, numMax)
    local size = self._widget.item:getContentSize()
    local x = 0
    local y = 0
    if pos%2 >= 1 then --奇数
        x = 0
    else
        x = size.width
    end
    
    local totalLine = math.ceil(numMax/2)
    if totalLine == 1 then
        totalLine = totalLine + 1
    elseif totalLine ~= 2 then
        totalLine = totalLine - 1
    end
    local curNumT = math.floor((pos-1)/2)
    y = (totalLine - curNumT) * size.height
    return x, y
end

--创建英雄列表
function HeroTrainSelectWidget:createHeroItem(heroID, showNum, numMax)
    local item = self._widget.item:clone()
    widgetUtil.widgetReader(item)

    --选择按钮
    item.btn_item:setTag(heroID)
    item.btn_item:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            local tag = sender:getTag()
            eventUtil.dispatchCustom("ui_heroTrainSelectWidget_select_hero", {heroID = tag})
        end
    end)

    --中止训练按钮
    item.btn_stop:setTag(heroID)
    item.btn_stop:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            local tag = sender:getTag()
            eventUtil.dispatchCustom("ui_heroTrainSelectWidget_stop_train", {heroID = tag})
        end
    end)

    local x,y = self:recordItemPos(showNum, numMax)
    item:setPosition(cc.p(x, y))
    self._PosItems[heroID] = item
    self:updateItem(heroID)
    self._widget.scroll_map:addChild(item)
end

--更新item
function HeroTrainSelectWidget:updateItem(heroID)
    local item = self._PosItems[heroID] --格子节点
    local heroInfo = Hero.getHeroByHeroID(heroID)
    widgetUtil.getHeroWeaponQuality(heroInfo._armsLv, item.image_icon_bottom, item.image_icon_grade) --英雄品质框

    --英雄星级
    for i=1, 5 do
        item["image_star"..i]:setVisible(false)
    end
    item["image_star"..heroInfo._star]:setVisible(true)

    local image_attr = Hero.getAttrIcon(heroInfo._attr)
    item.image_attribute:loadTexture(image_attr)  --英雄属性
    item.label_lv:setString(tostring(heroInfo._lv))--英雄等级

    local max = t_lv[heroInfo._lv]["hero_up_exp"]
    local expLable=string.format("%d/%d", heroInfo._exp, max) --经验
    item.label_exp:setString(expLable)  
    local percent = heroInfo._exp / max * 100  --经验进度条
    if percent>100 then
        item.progress_exp:setPercent(100)
    else
        item.progress_exp:setPercent(percent) 
    end

    item.label_name:setString(t_hero[heroID]["name"])--英雄名字
    widgetUtil.createIconToWidget(t_hero[heroID]["icon"], item.image_icon)
    
    if heroInfo._pos > 0 then
        item.Panel_train:setVisible(true)
    else
        item.Panel_train:setVisible(false)
    end
end

--选择英雄上阵
function HeroTrainSelectWidget:onSelectHero(event)
    local heroID = event.param.heroID
    local posAdd = self._widget.pos
    self:request("main.heroHandler.train",{heroID = heroID, pos = posAdd},function(msg)
        if msg['code'] == 200 then
            eventUtil.dispatchCustom("ui_HeroTrainSelectWidget_on_close_click")
        end
    end)
end

--中止训练
function HeroTrainSelectWidget:onStopTrain(event)
    local heroID = event.param.heroID
    self:request("main.heroHandler.endTrain",{heroID = heroID},function(msg)
        if msg['code'] == 200 then
            self._widget.heroID = nil
            self:updateItem(heroID)
        end
    end)
end

--更新英雄exp
function HeroTrainSelectWidget:updateExp()
    if self._widget.heroID then
        local item = self._PosItems[self._widget.heroID] --格子节点
        local heroInfo = Hero.getHeroByHeroID(self._widget.heroID)
        local max = t_lv[heroInfo._lv]["hero_up_exp"]
        local expLable=string.format("%d/%d", heroInfo._exp, max) --经验
        item.label_exp:setString(expLable)  
        local percent = heroInfo._exp / max * 100  --经验进度条
        if percent>100 then
            item.progress_exp:setPercent(100)
        else
            item.progress_exp:setPercent(percent) 
        end
    end
end

return HeroTrainSelectWidget