local BaseWidget = require('widget.BaseWidget')

local t_item=require("config/t_item")

local MailWidget = class("MailWidget", function()
    return BaseWidget:new()
end)

function MailWidget:create(save, opt)
    return MailWidget.new(save, opt)
end

function MailWidget:getWidget()
    return self._widget
end

function MailWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = widgetUtil.registCsbPanel("UImail")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    --关闭按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_MailWidget_on_close_click")
        end
    end)

    --邮件列表
    local list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImail_item.csb")
    local list = self._widget.list_item
    list:setItemModel(list_item_widget)

    self:flashMailList()

end

function MailWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_MailWidget_on_close_click",function(event)MailWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_MailWidget_on_read_mail_click",function(event)MailWidget.onReadMail(self,event)end)
    eventUtil.addCustom(self._widget,"ui_MailWidget_flash_mail_list",function(event)MailWidget.flashMail(self,event)end)
    
    self:subscribe(Const.EVENT.MAIL, function (mailItem)
        self:newMailCallBack(mailItem)
    end)
    
    --GameGuide.dispatchEvent(Const.GAME_GUIDE_TYPE.NORMAL)
end

function MailWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function MailWidget:onClose(event)
    UIManager.popWidget()
end

--阅读邮件
function MailWidget:onReadMail(event)
    local id = event.param.mailID
    if event.param.reward then --有奖品
        UIManager.pushWidget("mailContentRewardWidget", id, true)
    else
        UIManager.pushWidget("mailContentNormalWidget", id, true)
    end
    
    Mail.setMailRead(id)
    self:notify("mail.mailHandler.mailRead", {mailID = id}, function(msg)
        end)
end

--由消息调用，刷新邮件列表
function MailWidget:flashMail(event)
    self:flashMailList()
end

--刷新邮件列表
function MailWidget:flashMailList()
    local list = self._widget.list_item
    local mailList = Mail.getMailList()
    list:removeAllItems()

    local index = 0
    for i, item in pairs(mailList) do
        list:pushBackDefaultItem()
        local item_widget = list:getItem(index)
        widgetUtil.widgetReader(item_widget)

        --邮件标识
        local mailReward = false--没有奖品
        local firstItem = item.items[1] --第一个奖励物品
        if nil ~= firstItem and nil ~= firstItem.itemID then
            local itemInfo = t_item[firstItem.itemID]
            if itemInfo then
                widgetUtil.createIconToWidget(itemInfo.icon, item_widget.image_icon)
                
                if itemInfo.item == Const.ITEM_TYPE.HERO then --英雄
                    widgetUtil.getHeroWeaponQuality(itemInfo.grade, item_widget.image_icon_bottom, item_widget.image_icon_grade)
                else
                    widgetUtil.getItemQuality(itemInfo.grade, item_widget.image_icon_bottom, item_widget.image_icon_grade)
                end
            end
            
            mailReward = true
        else
            widgetUtil.createIconToWidget(21, item_widget.image_icon)
            widgetUtil.getItemQuality(0, item_widget.image_icon_bottom, item_widget.image_icon_grade)
        end

        item_widget.label_mail_name:setString(item.title)
        item_widget.label_from:setString(item.sign)
        
        if item.read == 0 then --未读
            item_widget.image_check:setVisible(false)
            item_widget.image_unread:setVisible(true)
        else
            item_widget.image_check:setVisible(true)
            item_widget.image_unread:setVisible(false)
        end

        local mailTime = os.date("%Y-%m-%d", item.time)
        item_widget.label_mail_time:setString(mailTime)

        item_widget.btn_look.mailID = item.id --邮件ID
        item_widget.btn_look.reward = mailReward --邮件是否有奖品
        item_widget.btn_look:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                eventUtil.dispatchCustom("ui_MailWidget_on_read_mail_click", {mailID = sender.mailID, reward = sender.reward})
            end
        end)

        index = index +1
    end
end

--新邮件回调
function MailWidget:newMailCallBack(mailItem)
    self:flashMailList()
end

return MailWidget