--module require
local BaseWidget = require('widget.BaseWidget')

local ServeListWidget = class("ServeListWidget", function()
    return BaseWidget:new()
end)

function ServeListWidget:create(save, opt)
    return ServeListWidget.new(save, opt)
end

function ServeListWidget:getWidget()
    return self._widget
end

function ServeListWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIlogin_server_list.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    local server_last = Login.getLastLoginServer()
    local server_list = Login.getServerList()
    
    local label_server = ccui.Helper:seekWidgetByName(self._widget, "label_server")
    label_server:setString(server_last['_name'])
  
    local server_list_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIlogin_server_list_item.csb")
    
    local list_server = ccui.Helper:seekWidgetByName(self._widget, "list_server")
    list_server:removeAllItems()
    list_server:setItemModel(server_list_item_widget)
    
    local row = #server_list
    for i=1, row do
        list_server:pushBackDefaultItem()
    end
    for i=1, row do        
        local item_widget = list_server:getItem(i-1)
        
        local btn_server = ccui.Helper:seekWidgetByName(item_widget, "btn_server")
        local label_server = ccui.Helper:seekWidgetByName(item_widget, "label_server")
        local label_server_state = ccui.Helper:seekWidgetByName(item_widget, "label_server_state")
        
        local color = server_list[i]._color
        local c = cc.c3b(color[1],color[2],color[3])
        
        label_server:setString(server_list[i]._name)
        label_server:setColor(c)
        label_server_state:setString(server_list[i]._state)
        label_server_state:setColor(c)
        
        btn_server:setTag(i)
        btn_server:addTouchEventListener(function(sender, eventType) 
            if eventType == ccui.TouchEventType.ended then
                local tag = sender:getTag()
                self:selectedServer(tag)
            end
        end)
    end
end

function ServeListWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()
end

function ServeListWidget:onExit()
end

function ServeListWidget:selectedServer(index)
    --弹出当前窗体后，将"重建"上一个窗体
    UIManager.popWidget()
    
    local serverWidget = self:getScene():getWidget('serverWidget')
    serverWidget:setSelectedServer(index)
end

return ServeListWidget

