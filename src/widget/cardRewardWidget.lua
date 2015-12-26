local tParameter = require('src/config/t_parameter')

local BaseWidget = require('widget.BaseWidget')

local CardRewardWidget = class("CardRewardWidget", function()
    return BaseWidget:new()
end)

function CardRewardWidget:create(save, opt)
    return CardRewardWidget.new(save, opt)
end

function CardRewardWidget:getWidget()
    return self._widget
end

function CardRewardWidget:onResume(event)
    self:updateBadge()
end

function CardRewardWidget:ctor(save, opt)
    self:setScene(save._scene)
    self._pageViewUpdate = false

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_reward.csb")
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
            eventUtil.dispatchCustom("ui_cardReward_on_close_click")
        end
    end)
    
    --购买金币按钮
    self._widget.btn_gold_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_gold_buy_click")
        end
    end)
    
    --购买钻币按钮
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_diamond_buy_click")
        end
    end)
    
    --密宝挖掘
    self._widget.btn_item_reward:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_item_reward_click")
        end
    end)
    
    --英雄招募
    self._widget.btn_hero_reward:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_hero_reward_click")
        end
    end)
    
    --章辉兑换
    self._widget.btn_medal_for:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_medal_for_click")
        end
    end)
    
    --用户信息
    self:updateInfo()
    self:subscribe(Const.EVENT.USER, function ()
        self:updateInfo()
    end)

    --默认选择 英雄招募
    self:onBtnClick(2)
    
    --密保挖掘
    local item_reward_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_item.csb")
    self._widget.Panel_item:addChild(item_reward_widget)
    widgetUtil.widgetReader(item_reward_widget)
    self._widget.item_reward_widget = item_reward_widget
    --item_reward_widget.bg_gold_num1:setString(tParameter.item_reward_one_pay.var)
    --item_reward_widget.bg_gold_num2:setString(tParameter.item_reward_ten_pay.var)
    
    --密宝挖掘1次
    item_reward_widget.btn_reward1:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_btn_reward1_click")
        end
    end)
    
    --密宝挖掘10次
    item_reward_widget.btn_reward2:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_btn_reward2_click")
        end
    end)
    
    --英雄招募
    local hero_reward_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_hero.csb")
    self._widget.Panel_hero:addChild(hero_reward_widget)
    widgetUtil.widgetReader(hero_reward_widget)
    self._widget.hero_reward_widget = hero_reward_widget
    --hero_reward_widget.label_diamond:setString(tParameter.hero_reward_one_pay.var)
    --hero_reward_widget.label_diamond2:setString(tParameter.hero_reward_ten_pay.var)
    --招募1次
    hero_reward_widget.btn_reward1:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_btn_hero_reward1_click")
        end
    end)
    
    --招募10次
    hero_reward_widget.btn_reward2:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_cardReward_on_btn_hero_reward2_click")
        end
    end)
    
    --刷新英雄招募免费次数
    local tOld = CardReward.getItemRewardTime()
    if tOld == 0 then
        hero_reward_widget.label_time:setString("免费次数：1/1")
    end
    
    --刷新密保挖掘免费次数
    self:reflashFreeTime()
    
    --海报
    self:createPages()
    
    --徽章
    self:updateBadge()
end

function CardRewardWidget:onEnter()
    self._updateID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(CardRewardWidget.update,1,false)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_close_click",function(event)CardRewardWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_gold_buy_click",function(event)CardRewardWidget.onGoldBuy(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_diamond_buy_click",function(event)CardRewardWidget.onDiamondBuy(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_item_reward_click",function(event)CardRewardWidget.onItemReward(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_hero_reward_click",function(event)CardRewardWidget.onHeroReward(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_medal_for_click",function(event)CardRewardWidget.onMedalFor(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_btn_reward1_click",function(event)CardRewardWidget.onReward1(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_btn_reward2_click",function(event)CardRewardWidget.onReward2(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_reflesh_time",function(event)CardRewardWidget.refleshTime(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_btn_hero_reward1_click",function(event)CardRewardWidget.onHeroReward1(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_btn_hero_reward2_click",function(event)CardRewardWidget.onHeroReward2(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_on_reflashFreeTime",function(event)CardRewardWidget.reflashFreeTime(self,event)end)
    eventUtil.addCustom(self._widget,"ui_cardReward_auto_scroll_page_view",function(event)CardRewardWidget.onAutoScrollPageView(self,event)end)
end

function CardRewardWidget:onExit()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateID)
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function CardRewardWidget:onClose(event)
    UIManager.popWidget()
end

--金币购买按钮
function CardRewardWidget:onGoldBuy(event)
    UIManager.pushWidget('goldBuyWidget', nil, true)
end

--钻石购买按钮
function CardRewardWidget:onDiamondBuy(event)
    UIManager.pushWidget('rechargeWidget', nil, true)
end

--密宝挖掘
function CardRewardWidget:onItemReward(event)
    self:onBtnClick(1)
end

--英雄招募
function CardRewardWidget:onHeroReward(event)
    self:onBtnClick(2)
end

--章辉兑换
function CardRewardWidget:onMedalFor(event)
    UIManager.pushWidget('shopWidget',Const.SHOP_TYPE.BADGE)
end

--密宝挖掘1次
function CardRewardWidget:onReward1(event)
    local tOld = CardReward.getDigTime()
    if tOld ~= 0 then --冷却中
        if not self:enoughtGold(tParameter.item_reward_one_pay.var) then
            return
        end
    end

    self:request('main.cardHandler.draft', {}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget("cardRewardAnimationWidget", {type = 1}, true)
        end
    end)
end

--刷新免费次数
function CardRewardWidget:reflashFreeTime(event)
    local tOld = CardReward.getDigTime()
    local label = self._widget.item_reward_widget.label_number
    if tOld == 0 then --没有在倒计时
        local curNum = CardReward.getItemRewardUseNum()
        local totalNum = tParameter.item_reward_number_free.var
        if curNum >= totalNum then --次数使用完
            label:setVisible(false)
        else
            local numLess = totalNum - curNum
            label:setVisible(true)
            label:setString("免费次数："..numLess.."/"..totalNum)
        end
    elseif event then
        label:setVisible(true)
        label:setString(event.param.strTime)
    end
end

--密宝挖掘10次
function CardRewardWidget:onReward2(event)
    if not self:enoughtGold(tParameter.item_reward_ten_pay.var) then
        return
    end

    self:request('main.cardHandler.draft10', {}, function(msg)
        if msg['code'] == 200 then
            --刷新物品
            UIManager.pushWidget("cardRewardAnimationWidget", {type = 2}, true)
        end
    end)
end

--英雄招募1次
function CardRewardWidget:onHeroReward1(event)
    local tOld = CardReward.getItemRewardTime()
    if tOld ~= 0 then --冷却中
        if not self:enoughtDiamond(tParameter.hero_reward_one_pay.var) then --钻石不足
           return
        end
    end
        
    self:request('main.cardHandler.recuit', {}, function(msg)
        if msg['code'] == 200 then
           UIManager.pushWidget("cardRewardAnimationWidget", {type = 3}, true)
        end
    end)
end

--英雄招募10次
function CardRewardWidget:onHeroReward2(event)
    if not self:enoughtDiamond(tParameter.hero_reward_ten_pay.var) then
        return
    end

    self:request('main.cardHandler.recuit10', {}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget("cardRewardAnimationWidget", {type = 4}, true)
        end
    end)
end

--按钮响应
function CardRewardWidget:onBtnClick(type)
    self._widget.btn_hero_reward:setEnabled(true)
    self._widget.btn_hero_reward:setBright(true)
    self._widget.btn_item_reward:setEnabled(true)
    self._widget.btn_item_reward:setBright(true)

    self._widget.Panel_item:setVisible(false)
    self._widget.Panel_hero:setVisible(false)
    if type == 1 then
        self._widget.Panel_item:setVisible(true)
        self._widget.btn_item_reward:setEnabled(false)
        self._widget.btn_item_reward:setBright(false)
    elseif type == 2 then
        self._widget.btn_hero_reward:setEnabled(false)
        self._widget.btn_hero_reward:setBright(false)
        self._widget.Panel_hero:setVisible(true)
    elseif type == 3 then
    end
end

--刷新用户金钱
function CardRewardWidget:updateInfo()
    self._widget.label_diamond:setString(tostring(Character.diamond))    --当前钻币
    self._widget.label_gold:setString(tostring(Character.gold))          --当前金币
end

--英雄招募倒计时
function CardRewardWidget.update(dt)
    --英雄招募
    local tOld = CardReward.getItemRewardTime()
    if tOld ~= 0 then
        local tNow = Game.time()
        local t = tNow - tOld
        local rewardTime = tParameter.hero_reward_time_free.var
        if t < rewardTime then   --倒计时
            local lessTime = rewardTime - t --剩余时间
            local h = math.floor(lessTime / 3600) --小时
            local m = math.floor((lessTime - h * 3600)/60) --分钟
            local s = lessTime % 60 --秒
            eventUtil.dispatchCustom("ui_cardReward_on_reflesh_time", {strTime = string.format("%02d:%02d:%02d后免费", h, m, s), free = false})
        else
            CardReward.setItemRewardTime(0)
            eventUtil.dispatchCustom("ui_cardReward_on_reflesh_time", {strTime = "免费次数：1/1", free = true})
        end
    end

    --密宝挖掘
    local tDigOld = CardReward.getDigTime()
    if tDigOld ~= 0 then
        local tNow = Game.time()
        local t = tNow - tDigOld
        local rewardTime = tParameter.item_reward_time_free.var
        
        local curNum = CardReward.getItemRewardUseNum()
        local totalNum = tParameter.item_reward_number_free.var
        
        if t < rewardTime and curNum ~= totalNum then   --倒计时
            local lessTime = rewardTime - t --剩余时间
            local h = math.floor(lessTime / 3600) --小时
            local m = math.floor((lessTime - h * 3600)/60) --分钟
            local s = lessTime % 60 --秒
            eventUtil.dispatchCustom("ui_cardReward_on_reflashFreeTime", {strTime = string.format("%02d:%02d:%02d后免费", h, m, s)})
        else
            CardReward.setDigTime(0)
            eventUtil.dispatchCustom("ui_cardReward_on_reflashFreeTime")
        end
    end
    
    --自动滚动
    eventUtil.dispatchCustom("ui_cardReward_auto_scroll_page_view")
end

--刷新倒计时
function CardRewardWidget:refleshTime(event)
    self._widget.hero_reward_widget.label_time:setString(event.param.strTime)
end

--英雄招募时候钻石是否足够
function CardRewardWidget:enoughtDiamond(pay)
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
function CardRewardWidget:enoughtGold(pay)
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

--创建海报
function CardRewardWidget:createPages()
    local pageNum = tParameter.card_reward_activity_num.var --海报数量,策划的改法：表格填几个，UI上班的星星存在几个
    local pageView = self._widget.PageView_posters
    pageView:removeAllPages()

    pageView:addEventListener(function(event,type)     
        if type==ccui.PageViewEventType.turning then
            local index = pageView:getCurPageIndex()
            if index == 0 then
                self:pageToLeft()
                pageView:scrollToPage(1)  
            elseif index == 2 then
                self:pageToRight()
                pageView:scrollToPage(1)  
            end
        end
    end)
    
    pageView:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.began then
            self._pageViewUpdate = false
        elseif eventType == ccui.TouchEventType.ended then
            self._pageViewUpdate = true
            self._pageViewScrollTime = Game.time()
        elseif eventType == ccui.TouchEventType.canceled then
            self._pageViewUpdate = true
            self._pageViewScrollTime = Game.time()
        end
    end)

    for i=0, 2 do
        local num = 1
        if i == 0 then
        	num = pageNum
        elseif i == 1 then
            num = 1
        else
            local less = pageNum - i
            if less < 0 then
                num = 1
            else
                num = 2
            end
        end

        local picNum = 20000 + num
        local pic = string.format("res/activity/%d.png", picNum)
        local sp = cc.Sprite:create(pic)
        if sp then
            sp:setAnchorPoint(cc.p(0, 0))
            local lay = ccui.Layout:create()
            lay:addChild(sp)
            pageView:addPage(lay)
        end
    end
    
    self._curPageNum = 1
    pageView:scrollToPage(1)
    self:setPageViewSeclectTip(self._curPageNum)
    self._pageViewUpdate = true
    self._pageViewScrollTime = Game.time() --上次滚动时间
end

function CardRewardWidget:pageToLeft()
    local pageView = self._widget.PageView_posters
    pageView:removePageAtIndex(2)
    self._curPageNum = self._curPageNum - 1
    if self._curPageNum < 1 then
        self._curPageNum = tParameter.card_reward_activity_num.var
    end
    
    local picNum = 20000 + self._curPageNum - 1
    if self._curPageNum == 1 then
        picNum = 20000 + tParameter.card_reward_activity_num.var
    end
    
    local pic = string.format("res/activity/%d.png", picNum)
    local sp = cc.Sprite:create(pic)
    if sp then
        sp:setAnchorPoint(cc.p(0, 0))
        local lay = ccui.Layout:create()
        lay:addChild(sp)
        pageView:insertPage(lay, 0)
    end
    
    self:setPageViewSeclectTip(self._curPageNum)
end

function CardRewardWidget:pageToRight()
    local pageView = self._widget.PageView_posters
    pageView:removePageAtIndex(0)
    self._curPageNum = self._curPageNum + 1
    if self._curPageNum > tParameter.card_reward_activity_num.var then
        self._curPageNum = 1
    end
    
    local picNum = 20000 + 1
    if self._curPageNum < tParameter.card_reward_activity_num.var then
        picNum = 20000 + self._curPageNum + 1
    end

    local pic = string.format("res/activity/%d.png", picNum)
    local sp = cc.Sprite:create(pic)
    if sp then
        sp:setAnchorPoint(cc.p(0, 0))
        local lay = ccui.Layout:create()
        lay:addChild(sp)
        pageView:addPage(lay)
    end
    self:setPageViewSeclectTip(self._curPageNum)
end

function CardRewardWidget:setPageViewSeclectTip(index)
    local pageNum = tParameter.card_reward_activity_num.var
    for i=1, pageNum do
        self._widget["image_page"..i]:setVisible(false)
    end
    
    self._widget["image_page"..index]:setVisible(true)
end

function CardRewardWidget:onAutoScrollPageView()
    if self._pageViewUpdate then
        local time = tParameter.card_reward_activity_time.var
        local less = Game.time() - self._pageViewScrollTime
        if less >= time then
            self._pageViewScrollTime = Game.time()
            local pageView = self._widget.PageView_posters
            pageView:scrollToPage(2)
        end
    end
end

function CardRewardWidget:updateBadge()
    local badgeNum=Item.getNum(Const.ITEM.BADGE_ITEM_ID)
    self._widget.label_num:setString(tostring(badgeNum))
end

return CardRewardWidget