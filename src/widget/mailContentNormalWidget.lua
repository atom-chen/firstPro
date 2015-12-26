local BaseWidget = require('widget.BaseWidget')

local MailContentNormalWidget = class("MailContentNormalWidget", function()
    return BaseWidget:new()
end)

function MailContentNormalWidget:create(save, opt)
    return MailContentNormalWidget.new(save, opt)
end

function MailContentNormalWidget:getWidget()
    return self._widget
end

function MailContentNormalWidget:ctor(save, opt)
    self:setScene(save._scene)
    local mailID = opt

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImail_content_2.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)
    
    local mailInfo = Mail.getMailByMailID(mailID)

    self._widget.label_mail_name:setString(mailInfo.title) --名字
    self._widget.label_content:setString(mailInfo.content) --内容
    self._widget.label_sender:setString(mailInfo.sign) --发送者
    
    self._widget.btn_yes:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_MailContentNormalWidget_on_yes_click")
        end
    end)

end

function MailContentNormalWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_MailContentNormalWidget_on_close_click",function(event)MailContentNormalWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_MailContentNormalWidget_on_yes_click",function(event)MailContentNormalWidget.onYes(self,event)end)
end

function MailContentNormalWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function MailContentNormalWidget:onClose(event)
    eventUtil.dispatchCustom("ui_MailWidget_flash_mail_list")
    UIManager.popWidget()
end

--
function MailContentNormalWidget:onYes(index)
    eventUtil.dispatchCustom("ui_MailContentNormalWidget_on_close_click")
end

return MailContentNormalWidget