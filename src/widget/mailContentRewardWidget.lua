local BaseWidget = require('widget.BaseWidget')

local t_item=require("config/t_item")

local MailContentRewardWidget = class("MailContentRewardWidget", function()
    return BaseWidget:new()
end)

function MailContentRewardWidget:create(save, opt)
    return MailContentRewardWidget.new(save, opt)
end

function MailContentRewardWidget:getWidget()
    return self._widget
end

function MailContentRewardWidget:ctor(save, opt)
    self:setScene(save._scene)
    local mailID = opt

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImail_content_1.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)
    
    local mailInfo = Mail.getMailByMailID(mailID)

    self._widget.label_mail_name:setString(mailInfo.title)
    self._widget.label_content:setString(mailInfo.content)
    self._widget.label_sender:setString(mailInfo.sign)
    
    self._widget.btn_get.mailID = mailID
    self._widget.btn_get:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_MailContentRewardWidget_on_get_click", {mailID = sender.mailID})
            end
        end)
        
    for i=1, 4 do
        local itemID
        local itemNum
        local itemTemp = mailInfo["items"][i]
        if nil ~= itemTemp and nil ~= itemTemp.itemID then
            itemID = itemTemp.itemID
            itemNum = itemTemp.num
        end
        
        local node = self._widget["panel_item"..i.."_icon"]
        
        if nil ~= itemID then
            node:setVisible(true)
            widgetUtil.setItemInfo(node, t_item[itemID].grade, t_item[itemID].icon, itemNum, t_item[itemID].item, t_item[itemID].xlv)
        else
            node:setVisible(false)
        end
    end
end

function MailContentRewardWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_MailContentRewardWidget_on_close_click",function(event)MailContentRewardWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_MailContentRewardWidget_on_get_click",function(event)MailContentRewardWidget.onGet(self,event)end)
end

function MailContentRewardWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function MailContentRewardWidget:onClose(event)
    UIManager.popWidget()
end

--
function MailContentRewardWidget:onGet(event)
    local mailID = event.param.mailID
    self:request('mail.mailHandler.attachment', {mailID = mailID}, function(msg)
        if msg['code'] == 200 then
        --领取成功
        Mail.delMailByMailID(mailID)
        eventUtil.dispatchCustom("ui_MailWidget_flash_mail_list")
        UIManager.popWidget()
        end
    end)
end

return MailContentRewardWidget