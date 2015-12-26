--[[
*          商品、兑换界面
*
]]
local BaseWidget = require('widget.BaseWidget')
local t_parameter = require('config/t_parameter')
local t_item = require('config/t_item')

local ShopWidget = class("ShopWidget", function()
    return BaseWidget:new()
end)

function ShopWidget:create(save, opt)
    return ShopWidget.new(save, opt)
end

function ShopWidget:getWidget()
    return self._widget
end

function ShopWidget:onSave()
    local save = {}
    save["shopType"] = self._shopType
    return save
end

function ShopWidget:ctor(save, shopType)   --widgetType 积分，徽章，普通类型
    self:setScene(save._scene) 
    
    if save._save then
        self._shopType = save._save["shopType"]
    else
        self._shopType=shopType
    end   
     
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIshop.csb")
    widgetUtil.widgetReader(self._widget)

    local shopItem= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIshop_item.csb") 
    self._widget.list_item:setItemModel(shopItem)  
    self._widget.list_item:setBounceEnabled(true)
    
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
    
    --金币充值按钮
    self._widget.btn_gold_buy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.pushWidget('goldBuyWidget')
        end
    end)
    
    --砖石充值按钮
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.pushWidget('rechargeWidget')
        end
    end)
    
    --刷新按钮
    self._widget.btn_refresh:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onRefresh()
        end
    end)
    
    self._widget.label_free_time:setString("")
    
    self.isGetting = false  --是否在发送请求中
    self.freshRoad=""   --刷新按钮请求路径
    self.autoFreshRoad=""   --自动刷新请求路径
    self.shopRoad=""   --购买、兑换 请求路径
    self.sureShopLab=""  --确定购买或兑换弹窗提示文本
    
    self:pretreatment()
    
    self:updateNum()
    self:updateShopList()
end

--预处理
function ShopWidget:pretreatment()
    local widget=self._widget
    
    if Const.SHOP_TYPE.COMMON == self._shopType then
        widget.bg_num:setVisible(false)
        widget.img_point:setVisible(false)
        widget.img_emblem:setVisible(false)

        self.freshRoad="main.userHandler.refleshExchange"
        self.autoFreshRoad="main.userHandler.getExchange"
        self.shopRoad="main.userHandler.exchange"
        self.sureShopLab=Str.SHOP_COMMON
    elseif Const.SHOP_TYPE.SCORE == self._shopType then
        widget.bg_emblem:setVisible(false)
        widget.img_emblem:setVisible(false)
        widget.img_things:setVisible(false)

        self.freshRoad="arena.arenaHandler.refleshExchange"
        self.autoFreshRoad="arena.arenaHandler.getExchange"
        self.shopRoad="arena.arenaHandler.exchange"
        self.sureShopLab=Str.SHOP_SCORE
    elseif Const.SHOP_TYPE.BADGE == self._shopType then
        widget.bg_point:setVisible(false)
        widget.img_point:setVisible(false)
        widget.img_things:setVisible(false)

        self.freshRoad="main.cardHandler.refleshExchange"
        self.autoFreshRoad="main.cardHandler.getExchange"
        self.shopRoad="main.cardHandler.exchange"
        self.sureShopLab=Str.SHOP_BADGE
    end 
end

--更新数值
function ShopWidget:updateNum()
    local widget=self._widget

    if Const.SHOP_TYPE.SCORE == self._shopType then
        local score = Arena.getScore()
        widget.label_num:setString(tostring(score))
    elseif Const.SHOP_TYPE.BADGE == self._shopType then
        local badgeNum=Item.getNum(Const.ITEM.BADGE_ITEM_ID)
        widget.label_num:setString(tostring(badgeNum))
    end
    widget.label_gold:setString(tostring(Character.gold))
    widget.label_diamond:setString(tostring(Character.diamond))
end

--刷新按钮
function ShopWidget:onRefresh()
    local pay = t_parameter.shop_refresh_pay.var
    if Character.diamond < pay then
        widgetUtil.showConfirmBox(Str.DIAMOND_NOT_ENOUGH, 
            function(msg)
                --购买
                UIManager.pushWidget('rechargeWidget')
            end)
    else
        widgetUtil.showConfirmBox(string.format(Str.SHOP_REFRESH, pay), 
            function(msg)
                self:request(self.freshRoad, {}, function(msg)
                    if msg['code'] == 200 then
                        self:updateShopList()
                        self:updateNum()
                    end
                end)
            end)
    end
end

--刷新物品列表
function ShopWidget:updateShopList()
    local widget=self._widget   
    widget.list_item:removeAllItems()
    
    local shops={}
    if Const.SHOP_TYPE.COMMON == self._shopType then
        shops=Item.getShops()   --普通商店物品
    elseif Const.SHOP_TYPE.SCORE == self._shopType then
        shops=Arena.getExchanges()  --积分兑换物品
    elseif Const.SHOP_TYPE.BADGE == self._shopType then
        shops=CardReward.getExchanges()  --徽章兑换物品
    end
    
    local row=math.ceil(#shops / 4)
    
    for i=1, row do
        widget.list_item:pushBackDefaultItem()
        local items=widget.list_item:getItem(i-1)
        for j=1, 4 do
            local n=j+4*i-4
            local item=items:getChildByName("bg_item"..j)
            widgetUtil.widgetReader(item)
            
            if shops[n] then
                if self.itemIcon==nil then
                    self.itemIcon=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIitem_icon.csb")  --物品
                    self.itemIcon:retain()
                end
                local itemIcon=self.itemIcon:clone()
                local size=item["panel_item_icon"..j]:getContentSize()
                itemIcon:ignoreAnchorPointForPosition(true)
                itemIcon:setPosition(size.width/2,size.height/2)
                item["panel_item_icon"..j]:addChild(itemIcon)
                
                widgetUtil.widgetReader(itemIcon)
                
                local cost=0
                if Const.SHOP_TYPE.COMMON == self._shopType then
                    item["bg_point"..j]:setVisible(false)
                    item["bg_emblem"..j]:setVisible(false)
                    item["bg_glod"..j]:setVisible(false)
                    cost=shops[n].diamond       
                elseif Const.SHOP_TYPE.SCORE == self._shopType then
                    item["bg_emblem"..j]:setVisible(false)
                    item["bg_glod"..j]:setVisible(false)
                    item["bg_diamond"..j]:setVisible(false)
                    cost=shops[n].score      
                elseif Const.SHOP_TYPE.BADGE == self._shopType then
                    item["bg_point"..j]:setVisible(false)
                    item["bg_glod"..j]:setVisible(false)
                    item["bg_diamond"..j]:setVisible(false)
                    cost=shops[n].badge
                end
                item["label_num"..j]:setString(tostring(cost))  --消耗砖石，积分，徽章数量

                local itemCfg=t_item[shops[n].id]
                if itemCfg then
                    item["label_name"..j]:setString(itemCfg.name)    --物品名称

                    widgetUtil.createIconToWidget(itemCfg.grade,itemIcon.image_item_bottom)  --底框
                    widgetUtil.createIconToWidget(itemCfg.icon,itemIcon.image_item)  --图标
                    widgetUtil.createIconToWidget(itemCfg.grade+10,itemIcon.image_item_grade)  --品质

                    itemIcon.label_item_num:setString(tostring(shops[n].num))  --换多少该物品

                    local xLv=tonumber(itemCfg.xlv) or 0
                    for k=1, Const.MAX_STAR do
                        if xLv == k then
                            itemIcon["image_star"..k]:setVisible(true)
                        else
                            itemIcon["image_star"..k]:setVisible(false)
                        end
                    end
                end

                if shops[n].state == 1 then           --已售图标
                    item["image_sold"..j]:setVisible(true)
                elseif shops[n].state ==0 then
                    item["image_sold"..j]:setVisible(false)
                end 

                item["btn_item"..j]:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        if shops[n].state==0 then                          
                            self:onItemClick(cost,shops[n].id)
                        end
                    end
                end)
            else
                item:setVisible(false)
                break
            end 
        end
    end
end

--点击物品
function ShopWidget:onItemClick(num,id)
    local lab=""
    lab=string.format(self.sureShopLab,num)

    widgetUtil.showConfirmBox(lab, 
        function(msg)        
            self:request(self.shopRoad, {itemID =id}, function(msg)
                if msg['code'] == 200 then
                    self:updateNum()
                    self:updateShopList()
                end
            end)
        end)
end


function ShopWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_shop_on_autoflesh_time",function(event)ShopWidget.onAutofresh(self,event)end)
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(dt) self:update(dt) end, 0, false)
end

--倒计时
function ShopWidget:update(dt)
    local now = Game.time() --当前时间
    local midnight = Game.midnight()
    
    local t1 = t_parameter.shop_reflesh_time_1.var
    local t2 = t_parameter.shop_reflesh_time_2.var
    if t1 > t2 then
        local tmp = t1
        t1 = t2
        t2 = tmp
    end

    local time1 = midnight + t1
    local time2 = midnight + t2
    
    local recordTime = function(lessTime,timeLable)
        eventUtil.dispatchCustom("ui_shop_on_autoflesh_time", {lessTime = lessTime , timeLable=timeLable})
    end

    local lastTime=0
    if Const.SHOP_TYPE.COMMON == self._shopType then
        lastTime=Item.getLastFreshTime()   --普通商店物品
    elseif Const.SHOP_TYPE.SCORE == self._shopType then
        lastTime=Arena.getLastFreshTime()  --积分兑换物品
    elseif Const.SHOP_TYPE.BADGE == self._shopType then
        lastTime=CardReward.getLastFreshTime()  --徽章兑换物品
    end
    
    if now >= time1 then
        if now >= time2 then
            if lastTime ~= time2 then
                recordTime(0)        
            else
                recordTime(time1+24*3600 - now, t1)
            end                
        else
            if lastTime ~= time1 then
                recordTime(0)
            else
                recordTime(time2 - now, t2)
            end                
        end
    else
        recordTime(time1 - now, t1)
    end
end

--刷新倒计时计算器
function ShopWidget:onAutofresh(event)
    if event.param.lessTime == 0 and not self.isGetting then --倒计时结束
        self.isGetting = true
        self:request(self.autoFreshRoad, {}, function(msg)
            self.isGetting = false
            if msg['code'] == 200 then
                self:updateShopList()
            end
        end)
    else
        local t=event.param.timeLable
        local h=math.floor(t/3600)
        local m=math.floor((t-h*3600)/60)
        local lab=string.format("%02d:%02d",h,m)
        self._widget.label_free_time:setString(lab)
    end
end

function ShopWidget:onExit()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
    if self.itemIcon then
        self.itemIcon:release()
    end    
end

--退出当前界面
function ShopWidget:back()
    UIManager.popWidget()
end
return ShopWidget