-- module require

local BaseWidget = class("BaseWidget", {})

function BaseWidget:create()
    return BaseWidget.new()
end

function BaseWidget:ctor()
    self._scene = nil
end

function BaseWidget:setScene(scene)
    self._scene = scene
end

function BaseWidget:getScene()
    return self._scene
end

function BaseWidget:showLoading(show)
    if nil ~= self._scene then
        self._scene:showLoading(show)
    end
end

function BaseWidget:showMsgBox(msg, cb)
    if nil ~= self._scene then
        self._scene:showMsgBox(msg, cb)
    end
end

function BaseWidget:showTip(tip)
    if nil ~= self._scene then
        self._scene:showTip(tip)
    end
end

function BaseWidget:httpGet(url, cb)
    if nil ~= self._scene then
        self._scene:httpGet(url, cb)
    end
end

function BaseWidget:connect(ip, port, cb)
    if nil ~= self._scene then
        self._scene:connect(ip, port, cb)
    end
end

function BaseWidget:request(route, msg, cb)
    if nil ~= self._scene then
        self._scene:request(route, msg, cb)
    end
end

function BaseWidget:notify(route, msg, cb)
    if nil ~= self._scene then
        self._scene:notify(route, msg, cb)
    end
end

function BaseWidget:registerEvent(event)
    if nil ~= self._scene then
        self._scene:registerEvent(event)
    end
end

function BaseWidget:removeEvent(event)
    if nil ~= self._scene then
        self._scene:removeEvent(event)
    end
end

function BaseWidget:subscribe(event, cb)
    Event.subscribe(self, event, cb)
end

function BaseWidget:unsubscribe(event)
    Event.unsubscribe(self, event)
end

function BaseWidget:unsubscribeAll()
    Event.unsubscribeAll(self)
end

return BaseWidget
