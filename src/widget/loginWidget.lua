--module require
local BaseWidget = require('widget.BaseWidget')

local LoginWidget = class("LoginWidget", function()
    return BaseWidget:new()
end)

function LoginWidget:create(save, opt)
    return LoginWidget.new(save, opt)
end

function LoginWidget:getWidget()
    return self._widget
end

function LoginWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlogin.csb")
    
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    local login_btn = ccui.Helper:seekWidgetByName(self._widget, "btn_login")
    login_btn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:loginRequest()
        end
    end)

    local regist_btn = ccui.Helper:seekWidgetByName(self._widget, "btn_registered")
    regist_btn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
        end
    end)

    --手动创建输入框
    local edit_name_back = ccui.Helper:seekWidgetByName(self._widget, "edit_name")

    local sizeEditName = edit_name_back:getContentSize()
    self.edit_name = cc.EditBox:create(sizeEditName, cc.Scale9Sprite:create('res/ui/common_bg17.png'))
    self.edit_name:setPosition(cc.p(sizeEditName.width/2, sizeEditName.height/2))
    self.edit_name:setPlaceHolder(Str.LOGIN_USERNAME)
    
    edit_name_back:addChild(self.edit_name)

    local edit_pass_back = ccui.Helper:seekWidgetByName(self._widget, "edit_password")
    local sizeEditPass = edit_pass_back:getContentSize()
    self.edit_pass = cc.EditBox:create(sizeEditPass, cc.Scale9Sprite:create('res/ui/common_bg17.png'))
    self.edit_pass:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    self.edit_pass:setPosition(cc.p(sizeEditPass.width/2, sizeEditPass.height/2))
    --self.edit_pass:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE )
    self.edit_pass:setPlaceHolder(Str.LOGIN_PASS)
    edit_pass_back:addChild(self.edit_pass)
    
    local name_store = cc.UserDefault:getInstance():getStringForKey("name")
    local pass_store = cc.UserDefault:getInstance():getStringForKey("pass")
    
    if string.len(name_store) > 0 then
        self.edit_name:setText(name_store)
        self.edit_pass:setText(pass_store)
    end
    
    local label_version = ccui.Helper:seekWidgetByName(self._widget, "label_version")
end

function LoginWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()
    
end

function LoginWidget:onExit()
end

function LoginWidget:loginRequest()
    --TODO:: 
    --程序版本号，资源版本号
    local chn = 10000
    
    local name_s = self.edit_name:getText()
    local pass_s = self.edit_pass:getText()
    
    local name_s = commonUtil.trim(name_s)
    local pass_s = commonUtil.trim(pass_s)

    local url = Game.SERVER_URL..'?name='..name_s..'&pass='..pass_s..'&chn='..tostring(chn)..'&gid='..tostring(Game.CHANNEL_ID)

    self:httpGet(url, function(res, msg)
        if res then
            local code = msg['code']
            if code == 200 then
                Login.parseLogin(msg['result'])
                
                cc.UserDefault:getInstance():setStringForKey("name", name_s)
                cc.UserDefault:getInstance():setStringForKey("pass", pass_s)
                cc.UserDefault:getInstance():flush()

                self:showServerWidget()
            else
                self:showTip(msg['msg'])
            end
        else
            self:showTip(Str.INVALID_SERVER)
        end
    end)
end

function LoginWidget:showServerWidget()
    UIManager.pushWidget('serverWidget')
end

return LoginWidget

