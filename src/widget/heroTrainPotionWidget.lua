local t_item = require('config/t_item')

local BaseWidget = require('widget.BaseWidget')

local HeroTrainPotionWidget = class("HeroTrainPotionWidget", function()
    return BaseWidget:new()
end)

function HeroTrainPotionWidget:create(save, opt)
    return HeroTrainPotionWidget.new(save, opt)
end

function HeroTrainPotionWidget:getWidget()
    return self._widget
end

function HeroTrainPotionWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    self._itemID = opt["id"]
    self._maxNum = 50 --max按钮最大数量

    self._widget = widgetUtil.registCsbPanel("UItrain_exp_liquid")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    --退出按钮
    self._widget:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if not self._click then
            	self._click = true
                eventUtil.dispatchCustom("ui_HeroTrainPotionWidget_on_close_click")
            end
        end
    end)
    
    
    --最大按钮
    self._widget.btn_max:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainPotionWidget_on_max_click")
        end
    end)
    
    --确定按钮
    self._widget.btn_yes:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainPotionWidget_on_yes_click")
        end
    end)
    
    --数量减按钮
    self._widget.btn_down:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainPotionWidget_on_down_click")
        end
    end)
    
    --数量加按钮
    self._widget.btn_up:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_HeroTrainPotionWidget_on_up_click")
        end
    end)
    
    local itemInfo = t_item[self._itemID] --物品信息
    self._itemInfo = itemInfo
    widgetUtil.getItemQuality(itemInfo.grade, self._widget["image_icon_bottom"], 
        self._widget["image_icon_grade"]) --品质图
    widgetUtil.createIconToWidget(itemInfo.icon, self._widget["image_icon"]) --物品图片
    self._widget["label_name"]:setString(itemInfo.name)--药水名称
    local des = string.format("增加英雄经验%d点", tonumber(itemInfo.reward_hero_exp))--药水描述
    self._widget["label_desc"]:setString(des)
    
    self._widget["label_num"]:setString(tostring(itemInfo.shop_num))--购买数量
    self._buyNum = itemInfo.shop_num
    
    self._widget["label_diamond_num"]:setString(tostring(itemInfo.shop_diamond))--价格
    self._buyDiamond = itemInfo.shop_diamond

end

function HeroTrainPotionWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_HeroTrainPotionWidget_on_close_click",function(event)HeroTrainPotionWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainPotionWidget_on_max_click",function(event)HeroTrainPotionWidget.onMax(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainPotionWidget_on_yes_click",function(event)HeroTrainPotionWidget.onYes(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainPotionWidget_on_down_click",function(event)HeroTrainPotionWidget.onDown(self,event)end)
    eventUtil.addCustom(self._widget,"ui_HeroTrainPotionWidget_on_up_click",function(event)HeroTrainPotionWidget.onUp(self,event)end)
end

function HeroTrainPotionWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function HeroTrainPotionWidget:onClose(event)
    UIManager.popWidget()
end

function HeroTrainPotionWidget:onMax()
    self._buyNum = self._maxNum
    self:updateLabel()
end

function HeroTrainPotionWidget:onYes()
    local itemID = tonumber(self._itemID)
    self:request("main.userHandler.buy", {itemID = itemID, num = self._buyNum}, function(msg)
        if msg['code'] == 200 then
            UIManager.popWidget()
        end
    end)
end

function HeroTrainPotionWidget:onDown()
    local buy = self._buyNum - self._itemInfo.shop_num
    if buy <= self._itemInfo.shop_num then
        buy = self._itemInfo.shop_num
    end
    self._buyNum = buy
    self:updateLabel()
end

function HeroTrainPotionWidget:onUp()
    local buy = self._itemInfo.shop_num + self._buyNum
    if buy >= self._maxNum then
    	buy = self._maxNum
    end
    self._buyNum = buy
    self:updateLabel()
end

--更新数量和钱
function HeroTrainPotionWidget:updateLabel()
    self._buyDiamond = self._buyNum / self._itemInfo.shop_num * self._itemInfo.shop_diamond
    self._widget["label_diamond_num"]:setString(tostring(self._buyDiamond))--价格
    self._widget["label_num"]:setString(tostring(self._buyNum))--购买数量
end

return HeroTrainPotionWidget