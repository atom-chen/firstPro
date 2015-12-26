local tParameter = require('src/config/t_parameter')
local t_item =require('src/config/t_item')

local BaseWidget = require('widget.BaseWidget')

local CardRewardAnimationWidgert = class("CardRewardAnimationWidgert", function()
    return BaseWidget:new()
end)

function CardRewardAnimationWidgert:create(save, opt)
    return CardRewardAnimationWidgert.new(save, opt)
end

function CardRewardAnimationWidgert:getWidget()
    return self._widget
end

function CardRewardAnimationWidgert:ctor(save, opt)
    self:setScene(save._scene)
    self._curPlayID = 0 --当前播放的物品ID
    self._curPlayIndex = 0 --当前播放索引，播放10个物品时候用
    self._multiNum = 0 --抽奖多个物品时，当前实际获得的物品数量

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_reward_animation.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    self._item_tpl = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIitem_icon.csb")
    self._item_tpl:retain()

    widgetUtil.widgetReader(self._widget)

    --退出按钮
    self._widget.btn_yes:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            --eventUtil.dispatchCustom("ui_cardReward_on_reflashFreeTime") --刷新挖掘次数
            eventUtil.dispatchCustom("ui_reward_animation_on_close_click")
        end
    end)
    
    --再来一次按钮
    self._widget.btn_reward:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardRewardAnimation_on_lottery")
        end
    end)
    
    self:hideTenItems()
    
    local type = opt["type"]
    self._type = type
    if type == 1 then      --密宝挖掘1次
    	self._widget.panel_card_hero:setVisible(false)
        self._widget.bg_gold_num2:setVisible(false)
        self._payTip = self._widget.bg_gold
        self._pay = self._widget.bg_gold_num1
    elseif type == 2 then  --密宝挖掘10次
        self._widget.panel_card_hero:setVisible(false)
        self._widget.bg_gold_num1:setVisible(false)
        self._payTip = self._widget.bg_gold
        self._pay = self._widget.bg_gold_num2
    elseif type == 3 then  --英雄招募1次
        self._widget.panel_card_item:setVisible(false)
        self._widget.bg_diamond_num2:setVisible(false)
        self._payTip = self._widget.bg_diamond
        self._pay = self._widget.bg_diamond_num1
    elseif type == 4 then  --英雄招募10次
        self._widget.panel_card_item:setVisible(false)
        self._widget.bg_diamond_num1:setVisible(false)
        self._payTip = self._widget.bg_diamond
        self._pay = self._widget.bg_diamond_num2
    end
    
    self._title = self._widget.bg_title
    self._btnTry = self._widget.btn_reward
    self._btnYes = self._widget.btn_yes
    self:showCtrl(false)
    
    --播放奖品动画
    self:flashRewardItem(type)
end

function CardRewardAnimationWidgert:onEnter()
    eventUtil.addCustom(self._widget,"ui_reward_animation_on_close_click",function(event)CardRewardAnimationWidgert.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardRewardAnimation_on_lottery",function(event)CardRewardAnimationWidgert.onLottery(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardRewardAnimation_play_hero_anim",function(event)CardRewardAnimationWidgert.playHeroAnim(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardRewardAnimation_item_scale_over",function(event)CardRewardAnimationWidgert.itemScaleOver(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardRewardAnimation_continue_play_item_get",function(event)CardRewardAnimationWidgert.continuePlayItemGet(self,event)end)
end

function CardRewardAnimationWidgert:onExit()
    self._item_tpl:release()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function CardRewardAnimationWidgert:onClose(event)
    UIManager.popWidget()
end

--抽奖品
function CardRewardAnimationWidgert:onLottery(event)
    if self._showState then
        return
    end
    
    local type = self._type
    if type == 1 then      --密宝挖掘1次
        local tOld = CardReward.getDigTime()
            if tOld ~= 0 then --冷却中
            if not self:enoughtGold(tParameter.item_reward_one_pay.var) then
                return
            end
        end
        
        self:clearItemInfo(self._widget.panel_item11_icon, self._widget.label_name11)
        
        self:request('main.cardHandler.draft', {}, function(msg)
            if msg['code'] == 200 then
                --刷新物品
                self:flashRewardItem(1)
                --eventUtil.dispatchCustom("ui_cardReward_on_reflashFreeTime")
            end
        end)
    elseif type == 2 then  --密宝挖掘10次
        if not self:enoughtGold(tParameter.item_reward_ten_pay.var) then
            return
        end
        
        self:clearTenItemInfo()
        
        self:request('main.cardHandler.draft10', {}, function(msg)
            if msg['code'] == 200 then
                --刷新物品
                self:flashRewardItem(2)
            end
        end)
    elseif type == 3 then  --英雄招募1次
        local tOld = CardReward.getItemRewardTime()
        if tOld ~= 0 then --冷却中
            if not self:enoughtDiamond(tParameter.hero_reward_one_pay.var) then
                return
            end
        end
        
        self:clearItemInfo(self._widget.panel_item11_icon, self._widget.label_name11)
        
        self:request('main.cardHandler.recuit', {}, function(msg)
            if msg['code'] == 200 then
                --刷新物品
                self:flashRewardItem(3)
            end
        end)
    elseif type == 4 then  --英雄招募10次
        if not self:enoughtDiamond(tParameter.hero_reward_ten_pay.var) then
            return
        end
        
        self:clearTenItemInfo()
    
        self:request('main.cardHandler.recuit10', {}, function(msg)
            if msg['code'] == 200 then
            self:flashRewardItem(4)
            end
        end)
    end
end

--英雄招募时候钻石是否足够
function CardRewardAnimationWidgert:enoughtDiamond(pay)
    if Character.diamond < pay then
        widgetUtil.showConfirmBox("钻石数量不足，是否进行充值？", 
        function(msg)
            --购买
            UIManager.pushWidget('rechargeWidget', {}, true)
        end)
        
        return false
    end
   
   return true
end

--密宝挖掘时候金币是否足够
function CardRewardAnimationWidgert:enoughtGold(pay)
    if Character.gold < pay then
        widgetUtil.showConfirmBox("金币不足，是否进行充值？", 
            function(msg)
                --购买
                UIManager.pushWidget('goldBuyWidget', {}, true)
            end)

        return false
    end

    return true
end

--隐藏10个物品
function CardRewardAnimationWidgert:hideTenItems()
    for i=1, 11 do
        self._widget["panel_item"..i.."_icon"]:setVisible(false)
        self._widget["label_name"..i]:setVisible(false)
    end
end

--刷新奖品列表
function CardRewardAnimationWidgert:flashRewardItem(type)
    local self = self
    self._showState = true
    local items = Item.getRewardItems()
    
    local animBegin = commonUtil.getAnim(9001)
    animBegin:setPosition(self:getCenterPos())
    self._widget:addChild(animBegin)
    animBegin:registerTimeEvent("s1",1,function()
        self:showCtrl(true)
        local type = self._type
        if type == 1 or type == 3 then -- 一个物品
            local node = self._widget.panel_item11_icon
            local nameLabel = self._widget.label_name11
            
            local itemID = items[1].itemID
            self._curPlayID = itemID
            local item = t_item[itemID]
            if item then
                self:showItem(node, nameLabel, itemID, items[1].num)
                node:setScale(0.2)
                node:setAnchorPoint(cc.p(0.5, 0.5))

                local act = cc.Spawn:create(cc.ScaleTo:create(0.3,1),cc.RotateBy:create(0.3,720))
                node:runAction(cc.Sequence:create(act, cc.CallFunc:create(CardRewardAnimationWidgert.scaleOver, self)))
            end
        else
            self._multiNum = #items
            if self._multiNum > 0 then
                self._curPlayIndex = 1
                self:showItemById(1)
            end
        end
    end)
    animBegin:PlaySection("s1", false)
end

--一个物品时，物品的旋转动画播放完毕
function CardRewardAnimationWidgert:scaleOver()
    local size = self:getContentSize()
    local animBegin = commonUtil.getAnim(9002)
    animBegin:setAnchorPoint(cc.p(0.5, 0.5))
    animBegin:setPosition(cc.p(size.width/2, size.height/2))
    self:addChild(animBegin, -1, 0x2999)
    animBegin:PlaySection("s1", true)
    
    eventUtil.dispatchCustom("ui_cardRewardAnimation_play_hero_anim")
end

--屏幕中心位置
function CardRewardAnimationWidgert:getCenterPos()
    local winSize = cc.Director:getInstance():getWinSize()
    local size= self._widget:getContentSize()
    return cc.p(winSize.width/2, size.height/2)
end

--隐藏显示界面上的控件
function CardRewardAnimationWidgert:showCtrl(show)
    self._title:setVisible(show)
    self._payTip:setVisible(show)
    self._pay:setVisible(show)
    self._btnTry:setVisible(show)
    self._btnYes:setVisible(show)
end

--显示物品
function CardRewardAnimationWidgert:showItem(node, nameLabel, itemID, num)
    local item = t_item[itemID]
    if item then
        node:setVisible(true)
        nameLabel:setVisible(true)
        nameLabel:setString(item.name)
        widgetUtil.setItemInfo(node, item.grade, item.icon, num, item.item, item.xlv, self._item_tpl)
    end
end

--播放英雄动画
function CardRewardAnimationWidgert:playHeroAnim()
    local item = t_item[self._curPlayID]
    if item then
        if item.item == Const.ITEM_TYPE.HERO then
        	--显示面板
            UIManager.pushWidget('cardRewardHeroAnimation1Widget', {itemID = self._curPlayID}, true)
        else
            local type = self._type
            if type == 1 or type == 3 then -- 一个物品
                self._showState = false
            else
                self:continuePlayItemGet()
            end
        end
    end
end

--清除物品信息
function CardRewardAnimationWidgert:clearItemInfo(node, label)
    local itemShow = node:getChildByTag(0x100)
    if itemShow then
        itemShow:removeFromParent(true)
    end
    
    local animClear = node:getChildByTag(0x2999)
    if animClear then
        animClear:removeFromParent(true)
    end
    
    label:setString(" ")
end

--物品缩放完毕的回调
function CardRewardAnimationWidgert:scaleTenOver()
    eventUtil.dispatchCustom("ui_cardRewardAnimation_item_scale_over")
end

--顺序播放10个物品
function CardRewardAnimationWidgert:showItemById(id)
    if id > self._multiNum or id < 1 then
        return
    end
    
    local items = Item.getRewardItems()
    local node = self._widget["panel_item"..id.."_icon"]
    local nameLabel = self._widget["label_name"..id]
    self:showItem(node, nameLabel, items[id].itemID, items[id].num)
    self._curPlayID = items[id].itemID
    node:runAction(cc.Sequence:create(cc.ScaleTo:create(0.05, 1.5), cc.ScaleTo:create(0.2, 1), 
        cc.CallFunc:create(CardRewardAnimationWidgert.scaleTenOver, self)))
end

--物品缩放动画播放完毕
function CardRewardAnimationWidgert:itemScaleOver()
    local item = t_item[self._curPlayID]
    if item then
        if item.grade >= 3 then
            local node = self._widget["panel_item"..self._curPlayIndex.."_icon"]
            local size = node:getContentSize()
            local animBegin = commonUtil.getAnim(9002)
            animBegin:setAnchorPoint(cc.p(0.5, 0.5))
            animBegin:setPosition(cc.p(size.width/2, size.height/2))
            node:addChild(animBegin, -1, 0x2999)
            animBegin:PlaySection("s1", true)
        end
    end

    eventUtil.dispatchCustom("ui_cardRewardAnimation_play_hero_anim")
end

--是否继续播放10个物品的动画
function CardRewardAnimationWidgert:continuePlayItemGet()
    local type = self._type
    if type == 2 or type == 4 then -- 10个物品
        if self._curPlayIndex < self._multiNum then
            self._curPlayIndex = self._curPlayIndex + 1
            self:showItemById(self._curPlayIndex)
        else
            self._showState = false
        end
    else
        self._showState = false
    end
end

--清理10个物品的动画
function CardRewardAnimationWidgert:clearTenItemInfo()
    for i=1, 10 do
        local node = self._widget["panel_item"..i.."_icon"]
        local nameLabel = self._widget["label_name"..i]
        self:clearItemInfo(node, nameLabel)
    end
end

return CardRewardAnimationWidgert