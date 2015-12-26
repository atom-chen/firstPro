--module require
local BaseWidget = require('widget.BaseWidget')

local ServeWidget = class("ServeWidget", function()
    return BaseWidget:new()
end)

function ServeWidget:create(save, opt)
    return ServeWidget.new(save, opt)
end

function ServeWidget:getWidget()
    return self._widget
end

function ServeWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIlogin_server.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    --用户默认选中服务器编号
    local server_last = Login.getLastLoginServer()
    self._nServerID = server_last['_id']
    
    local color = server_last._color
    local c = cc.c3b(color[1],color[2],color[3])

    self._lableLastLogin = ccui.Helper:seekWidgetByName(self._widget, "label_server")
    self._lableLastLogin:setString(server_last['_name'])
    self._lableLastLogin:setColor(c)

    local btn_server = ccui.Helper:seekWidgetByName(self._widget, "btn_server")
    btn_server:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:showServerListWidget()
        end
    end)

    local btn_confirm = ccui.Helper:seekWidgetByName(self._widget, "btn_confirm")
    btn_confirm:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:enterGameRequest()
        end
    end)
end

function ServeWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()
end

function ServeWidget:onExit()
    
end

function ServeWidget:enterGameRequest()
    local server = Login.getServerByID(self._nServerID)
    self:connect(server._ip, server._port, function(state)
        if NetWork.NETWORK_STATE.STATE_CONNECTED == state then
            local login = Login.getLoginInfo()

            local request = {}
            request['gid'] = Game.CHANNEL_ID
            request['sid'] = self._nServerID
            request['uid'] = login._uid
            request['token'] = login._token
            request["localTime"] = os.time()
            
            self:request('connector.entryHandler.entry', request, function(msg)
                if msg['code'] == 200 then
                    
                    self:removeEvent("onChat")
                    self:registerEvent("onChat")
                    
                    self:removeEvent("onMail")
                    self:registerEvent("onMail")
                    
                    self:removeEvent("onCharge")
                    self:registerEvent("onCharge")
                    
                    self:removeEvent(NetWork.NETWORK_EVENT.onKick)
                    self:registerEvent(NetWork.NETWORK_EVENT.onKick)
                    
                    self:removeEvent(NetWork.NETWORK_EVENT.disconnect)
                    self:registerEvent(NetWork.NETWORK_EVENT.disconnect)
                    
                    self:removeEvent(NetWork.NETWORK_EVENT.reconnect)
                    self:registerEvent(NetWork.NETWORK_EVENT.reconnect)
                    
                    self:showMainScene()
                end
            end)
        else
            self:showTip(Str.INVALID_SERVER)
        end
    end)
end

function ServeWidget:showMainScene()
    UIManager.replaceScene('MainScene')
end

function ServeWidget:showServerListWidget()
    UIManager.pushWidget('serverListWidget')
end

function ServeWidget:setSelectedServer(index)
    local server_list = Login.getServerList()

    self._nServerID = server_list[index]._id
    
    local server = server_list[index]
    
    local color = server._color
    local c = cc.c3b(color[1],color[2],color[3])
    
    self._lableLastLogin:setString(server._name)
    self._lableLastLogin:setColor(c)
end

return ServeWidget

