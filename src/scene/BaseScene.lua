-- module require

local BaseScene = class("BaseScene", function()
    return cc.Scene:create()
end)

function BaseScene:create()
    return BaseScene.new()
end

function BaseScene:ctor()
    self._ScheList = {}
end

function BaseScene:getWidget(name)
    for i=#self._ScheList, 1, -1 do
        if self._ScheList[i]._name == name then
            return self._ScheList[i]._instance
        end
    end
    return nil
end

function BaseScene:hasWidget(name)
    local res = false
    for i=#self._ScheList, 1, -1 do
        if self._ScheList[i]._name == name then
            res = true
            break
        end
    end
    return res
end

function BaseScene:_pushWidget(sche)
    table.insert(self._ScheList, sche)
end

function BaseScene:_popWidget()
    return table.remove(self._ScheList)
end

function BaseScene:_replaceWidget(sche)
    if #self._ScheList > 0 then
        table.remove(self._ScheList)
    end
    
    table.insert(self._ScheList, sche)
end

function BaseScene:showLoading(show)
    if show then
        widgetUtil.showWaitingNet()
    else
        widgetUtil.removeWaitingNet()
    end
end

function BaseScene:showMsgBox(msg, cb)
end

function BaseScene:showTip(tip)
    widgetUtil.showTip(tip)
end

function BaseScene:httpGet(url, cb)
    self:showLoading(true)

    NetWork.httpGet(url, function(res, msg)
        if((type(msg) == "string") and (string.len(msg) > 0))then
            if not pcall(function() msg=json.decode(msg) end) then
                msg = {}
                res = false
            end            
        else
            msg = {}
        end        
        cb(res, msg)

        self:showLoading(false)
    end)
end

function BaseScene:connect(ip, port, cb)
    NetWork.connect(ip, port, cb)
end

function BaseScene:request(route, msg, cb)
    self:showLoading(true)
    
    NetWork.request(route, msg, function(_msg)
        if _msg["code"] == 500  then
            self:showTip(_msg["msg"])
        end
        cb(_msg)

        self:showLoading(false)
    end)
end

function BaseScene:notify(route, msg, cb)
    NetWork.request(route, msg, function(_route, _msg)
        cb(_route, _msg)
    end)
end

function BaseScene:registerEvent(event)
    NetWork.registerEvent(event)
end

function BaseScene:removeEvent(event)
    NetWork.removeEvent(event)
end

function BaseScene:subscribe(event, cb)
    Event.subscribe(self, event, cb)
end

function BaseScene:unsubscribe(event)
    Event.unsubscribe(self, event)
end

function BaseScene:unsubscribeAll(event)
    Event.unsubscribeAll(self)
end

return BaseScene


