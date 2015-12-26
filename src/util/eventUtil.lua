module("eventUtil", package.seeall)

--添加自定义事件
function addCustom(node,eventName,callback)

    local eventDispatcher=node:getEventDispatcher()
    
    local event=cc.EventListenerCustom:create(eventName,callback)
    
    eventDispatcher:addEventListenerWithSceneGraphPriority(event,node)
end

function removeCustom(node)
    local eventDispatcher=node:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(node,false)
    
end

function dispatchCustom(eventName,param)
    local event=cc.EventCustom:new(eventName)
    if param then
        event.param=param
    end
    local eventDispatcher=cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:dispatchEvent(event)
end
