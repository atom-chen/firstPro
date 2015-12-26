module("Event", package.seeall)

local _subscriber = {}

function subscribe(o, event, cb)
    if not _subscriber[event] then
        _subscriber[event] = {}
    end
    
    _subscriber[event][o] = cb
end

function unsubscribe(o, event)
    if _subscriber[event] then
        _subscriber[event][o] = nil
    end
end

function unsubscribeAll(o)
    for event, v in pairs(_subscriber) do
        if _subscriber[event][o] then
            _subscriber[event][o] = nil
        end
    end
end

function notify(event, opt)
    if _subscriber[event] then
        for o, cb in pairs(_subscriber[event]) do
            cb(opt)
        end
    end
end

