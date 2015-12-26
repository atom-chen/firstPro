local t_train = require('src/config/t_train')
local t_train_lv = require('src/config/t_train_lv')
local t_lv =require('config/t_lv')
local t_hero = require('config/t_hero')
local t_item = require('config/t_item')
local t_music=require("config/t_music")

local BaseWidget = require('widget.BaseWidget')

local HeroTrainWidget = class("HeroTrainWidget", function()
    return BaseWidget:new()
end)

function HeroTrainWidget:create(save, opt)
    return HeroTrainWidget.new(save, opt)
end

function HeroTrainWidget:getWidget()
    return self._widget
end

function HeroTrainWidget:onResume()
    print("HeroTrainWidget——onResume")
    if self._widget.posAdd then
        self:updateTrainItem(self._widget.posAdd)
        self._widget.posAdd = nil
    end

    if self._buyPos then
        self:updatePotionPos(self._buyPos)
       self._buyPos = nil
    end
end

function HeroTrainWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    --已创建的训练位置
    self._PosItems = {}
    
    --当前选中那个药水
    self._curPotion = nil
    
    --药水与格子对应
    self._Pos = {Const.EXP_POTION.LEV1, Const.EXP_POTION.LEV2, Const.EXP_POTION.LEV3, Const.EXP_POTION.LEV4}
    print("创建面板HeroTrainWidget")
    self._widget = widgetUtil.registCsbPanel("UItrain")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    --退出按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainWidget_on_close_click")
        end
    end)
    
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_heroTrainWidget_on_diamond_click")
        end
    end)

    --金币
    self._widget.btn_gold_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_heroTrainWidget_on_gold_click")
        end
    end)

    self._heroItem = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UItrain_item.csb")
    self._heroItem:retain()

    self:createTrainList()--创建训练位置
    self:initExpPotion()--初始化经验药水
    
    --监听训练中的英雄经验
    self:subscribe(Const.EVENT.HERO_EXP, function ()
        self:updateExp()
    end)
    
    --用户信息
    self:updateInfo()
    self:subscribe(Const.EVENT.USER, function ()
        self:updateInfo()
    end)
end

function HeroTrainWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_HeroTrainWidget_on_close_click",function(event)HeroTrainWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainWidget_unlock_item",function(event)HeroTrainWidget.unlockItem(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainWidget_add_hero",function(event)HeroTrainWidget.addHero(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainWidget_up_item",function(event)HeroTrainWidget.upItem(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainWidget_click_hero",function(event)HeroTrainWidget.clickHero(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainWidget_use_potion",function(event)HeroTrainWidget.usePotion(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainWidget_buy_potion",function(event)HeroTrainWidget.buyPotion(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainWidget_on_diamond_click",function(event)HeroTrainWidget.onDiamond(self,event)end)
    eventUtil.addCustom(self._widget,"ui_heroTrainWidget_on_gold_click",function(event)HeroTrainWidget.onGold(self,event)end)
    commonUtil.preloadEffect(t_music[1440].path)
    
    --GameGuide.dispatchEvent(Const.GAME_GUIDE_TYPE.NORMAL)
    print("HeroTrainWidget——onEnter")
end

function HeroTrainWidget:onExit()
    self._heroItem:release()

    eventUtil.removeCustom(self._widget)
    commonUtil.unloadEffect(t_music[1440].path)
end

--关闭按钮
function HeroTrainWidget:onClose(event)
    UIManager.popWidget()
end

--创建训练列表
function HeroTrainWidget:createTrainList()
    local height = 0
    local itemHeight = 0
    
    local posInfo = Hero.getHeroPos()
    for pos,lv in pairs(posInfo) do
        local item = self._heroItem:clone()
        local size= item:getContentSize()
        
        widgetUtil.widgetReader(item)

        --点击升级中的英雄
        item.btn_item3:setTag(pos)
        item.btn_item3:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_HeroTrainWidget_click_hero", {pos = tag})
            end
        end)
        
        --解锁格子
        item.btn_clear2:setTag(pos)
        item.btn_clear2:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_HeroTrainWidget_unlock_item", {pos = tag})
            end
        end)
        
        --加英雄训练
        item.btn_add1:setTag(pos)
        item.btn_add1:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_HeroTrainWidget_add_hero", {pos = tag})
            end
        end)
        
        --升级按钮
        item.btn_train1:setTag(pos)
        item.btn_train1:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_HeroTrainWidget_up_item", {pos = tag})
            end
        end)
        
        local x,y = self:recordItemPos(pos, size)
        item:setPosition(cc.p(x, y))
        self._PosItems[pos] = item
        self:updateTrainItem(pos)
        self._widget.scroll_map:addChild(item)
        
        if height == 0 and itemHeight == 0 then
            height = y
            itemHeight = size.height
        end
    end
    
    height = height + itemHeight
    local sizeCont = self._widget.scroll_map:getInnerContainerSize()
    if sizeCont.height < height then
        self._widget.scroll_map:setInnerContainerSize(cc.size(sizeCont.width, height))
    end
end

--根据pos计算item摆放位置
function HeroTrainWidget:recordItemPos(pos, size)
    local x = 0
    local y = 0
    if pos%2 >= 1 then --奇数
        x = 0
    else
        x = size.width - 10
    end
    
    y = math.floor((8-pos)/2) * size.height
    return x, y
end

--解锁格子
function HeroTrainWidget:unlockItem(event)
    local posLock = event.param.pos
    local vip, pay = self:getPayByPos(posLock)
    if vip > Character.vipLevel then
        self:showTip("VIP等级不足，无法开启！")
        return
    end
    
    if pay > Character.diamond then
        self:showTip("钻石不足，无法开启！")
        return
    end
    
    self:request("main.heroHandler.openPos", {pos = posLock}, function(msg)
        if msg['code'] == 200 then
            --开启成功
            self:updateTrainItem(posLock)
            self:showTip("成功开启！")
        end
    end)
end

--加英雄训练
function HeroTrainWidget:addHero(event)
    local posAdd = event.param.pos
    self._widget.posAdd = posAdd
    UIManager.pushWidget('heroTrainSelectWidget', {pos = posAdd}, true)
end

--更新训练格子
function HeroTrainWidget:updateTrainItem(pos)
    local item = self._PosItems[pos] --格子节点
    local posInfo = Hero.getHeroPos()
    local lv = posInfo[pos] --格子等级
    
    item.Panel_1:setVisible(false)
    item.Panel_2:setVisible(false)
    item.Panel_3:setVisible(false)

    local heroID = Hero.isHeroInPos(pos)
    if heroID then --位置已经被占用
        item.Panel_3:setVisible(true)
        local heroInfo = Hero.getHeroByHeroID(heroID)
        widgetUtil.getHeroWeaponQuality(heroInfo._armsLv, item.image_icon_bottom3, item.image_icon_grade3) --英雄品质框

        --英雄星级
        for i=1, 5 do
            item["image_star"..i]:setVisible(false)
        end
        item["image_star"..heroInfo._star]:setVisible(true)

        local image_attr = Hero.getAttrIcon(heroInfo._attr)
        item.image_attribute3:loadTexture(image_attr)  --英雄属性
        item.label_lv3:setString(tostring(heroInfo._lv))--英雄等级

        local max = t_lv[heroInfo._lv]["hero_up_exp"]
        local expLable=string.format("%d/%d", heroInfo._exp, max) --经验
        item.label_exp3:setString(expLable)  
        local percent = heroInfo._exp / max * 100  --经验进度条
        if percent>100 then
            item.progress_exp3:setPercent(100)
        else
            item.progress_exp3:setPercent(percent) 
        end

        item.label_name3:setString(t_hero[heroID]["name"])--英雄名字
        widgetUtil.createIconToWidget(t_hero[heroID]["icon"], item.image_icon3)--英雄头像
    else --未被占用
        if lv == 0 then                               --格子未解锁
            item.Panel_2:setVisible(true)
            local vip, pay = self:getPayByPos(pos)
            item.label_gold2:setString(tostring(pay))  --解锁格子的花费
            
            local lastLv = posInfo[pos-1]
            if lastLv then
            	if lastLv == 0 then --上一个未解锁
                    item.btn_clear2:setEnabled(false)
                    item.btn_clear2:setBright(false)
            	else
                    item.btn_clear2:setEnabled(true)
                    item.btn_clear2:setBright(true)
            	end
            end
            
        else --格子已解锁，未被占用
            item.Panel_1:setVisible(true)
            item.label_name1:setString(t_train_lv[lv]["name"]) --训练位名字
            item.label_gold1:setString(tostring(t_train_lv[lv]["diamond"])) --升级花费
            
            local nextLv = posInfo[pos+1]
            local nextItem = self._PosItems[pos+1] --下一个格子节点
            if nextLv and nextItem then
               if nextLv == 0 then --开启下一个解锁
                    nextItem.btn_clear2:setBright(true)
                    nextItem.btn_clear2:setEnabled(true)
               end
            end
        end
    end
end

--升级格子
function HeroTrainWidget:upItem(event)
    local pos = event.param.pos
    local posInfo = Hero.getHeroPos()
    local lv = posInfo[pos] --格子等级
    if lv >= 5 then --格子满级
        self:showTip("格子已经满级，无需升级！")
    end
    
    local upInfo = t_train_lv[lv]
    local curUpExp = upInfo["exp"] * 60
    local nextUpExp = t_train_lv[lv+1]["exp"] * 60
    local str = "升级 "..upInfo["name"].." 需要花费"..upInfo["diamond"].."钻石,每小时获取经验"..tostring(curUpExp).."->"..tostring(nextUpExp)
    widgetUtil.showConfirmBox(str, 
        function()
            self:request("main.heroHandler.upgradePos", {pos = pos}, function(msg)
                if msg['code'] == 200 then
                    self:updateTrainItem(pos)
                    self:showTip("升级成功！")
                end
            end)
        end)
end

--点击升级中的英雄
function HeroTrainWidget:clickHero(event)
    local posUpdate = event.param.pos
    self._widget.posAdd = posUpdate
    local heroID = Hero.isHeroInPos(posUpdate)
    if self._curPotion then --使用药水状态
        local itemID = self._Pos[self._curPotion]
        self:request("main.heroHandler.useExpPotion", {itemID = itemID, heroID = heroID}, function(msg)
            if msg['code'] == 200 then
                self:showTip("为英雄加速成功！")
                self:updatePotionPos(self._curPotion)
                self:updateTrainItem(posUpdate)
                commonUtil.playEffect(t_music[1440].path)
            end
        end)
    else
        UIManager.pushWidget('heroTrainSelectWidget', {pos = posUpdate, heroID = heroID}, true)
    end
end

--查询开启某位置需要的vip等级，费用
function HeroTrainWidget:getPayByPos(pos)
    local vip = t_train[pos]["vip"]
    local pay = t_train[pos]["diamond"]
    return vip, pay
end

--初始化经验药水
function HeroTrainWidget:initExpPotion()
    local pos = self._Pos
    for i=1, 4 do
        self:updatePotionPos(i)
        
        self._widget["image_icon"..i.."_click"]:setVisible(false) --隐藏选中
        --购买按钮
        self._widget["btn_hint"..i]:setTag(i)
        self._widget["btn_hint"..i]:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_heroTrainWidget_buy_potion", {pos = tag})
            end
        end)
        
        --使用按钮
        self._widget["btn_use"..i]:setTag(i)
        self._widget["btn_use"..i]:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                eventUtil.dispatchCustom("ui_heroTrainWidget_use_potion", {pos = tag})
            end
        end)
    end
end

--选中药水
function HeroTrainWidget:usePotion(event)
    local pos = event.param.pos
    
    if self._curPotion then
        self._widget["image_icon"..self._curPotion.."_click"]:setVisible(false)   

        if self._curPotion ~= pos then
            self._curPotion = pos
            self._widget["image_icon"..pos.."_click"]:setVisible(true)
        else
            self._curPotion = nil
        end 
    else
        self._curPotion = pos
        self._widget["image_icon"..pos.."_click"]:setVisible(true)
    end
end

--购买药水
function HeroTrainWidget:buyPotion(event)
    local pos = event.param.pos
    local itemID = self._Pos[pos]
    self._buyPos = pos
    UIManager.pushWidget('heroTrainPotionWidget', {id = itemID}, true)
end

--更新某格子的药水情况
--pos:位子1-4
function HeroTrainWidget:updatePotionPos(pos)
    local itemID = self._Pos[pos]--物品ID
    local itemInfo = t_item[itemID] --物品信息
    local itemNum = Item.getNum(itemID) --拥有的数量

    widgetUtil.getItemQuality(itemInfo.grade, self._widget["image_icon"..pos.."_bottom"], 
        self._widget["image_icon"..pos.."_grade"]) --品质图
    widgetUtil.createIconToWidget(itemInfo.icon, self._widget["image_icon"..pos]) --物品图片
    if itemNum == 0 then --没有该药水
        self._widget["bg_num"..pos]:setVisible(false)
        self._widget["btn_hint"..pos]:setVisible(true)
        self._widget["btn_use"..pos]:setVisible(false)
        widgetUtil.greySprite(self._widget["image_icon"..pos]:getChildByTag(0x100))
        if self._curPotion == pos then
            self._curPotion = nil
            self._widget["image_icon"..pos.."_click"]:setVisible(false) --隐藏选中
        end
    else
        self._widget["bg_num"..pos]:setVisible(true)
        self._widget["label_num"..pos]:setString(tostring(itemNum))
        self._widget["btn_hint"..pos]:setVisible(false)
        self._widget["btn_use"..pos]:setVisible(true)
        widgetUtil.restoreGreySprite(self._widget["image_icon"..pos]:getChildByTag(0x100))
    end
end

--更新英雄exp
function HeroTrainWidget:updateExp()
    local posInfo = Hero.getHeroPos()
    for pos,lv in pairs(posInfo) do
        local heroID = Hero.isHeroInPos(pos)
        if heroID then --位置已经被占用
            local item = self._PosItems[pos] --格子节点
            local heroInfo = Hero.getHeroByHeroID(heroID)
            local max = t_lv[heroInfo._lv]["hero_up_exp"]
            local expLable=string.format("%d/%d", heroInfo._exp, max) --经验
            item.label_exp3:setString(expLable)  
            item.label_lv3:setString(heroInfo._lv)  
            local percent = heroInfo._exp / max * 100  --经验进度条
            if percent>100 then
                item.progress_exp3:setPercent(100)
            else
                item.progress_exp3:setPercent(percent) 
            end
        end
    end
end

--刷新用户金钱
function HeroTrainWidget:updateInfo()
    self._widget.label_diamond:setString(tostring(Character.diamond))    --当前钻币
    self._widget.label_gold:setString(tostring(Character.gold))          --当前金币
end

--购买钻石
function HeroTrainWidget:onDiamond(event)
    UIManager.pushWidget('rechargeWidget', {}, true)
end

--购买金币
function HeroTrainWidget:onGold(event)
    UIManager.pushWidget('goldBuyWidget', {}, true)
end
return HeroTrainWidget