module("NetWork", package.seeall)

require "json"

NETWORK_EVENT = {
    onKick     = "onKick",
    timeout    = "timeout",
    disconnect = "disconnect",
    reconnect  = "reconnect",
    
    connected     = "connected",
    connectFailed   = "connectFailed",
    notifyFailed    = "notifyFailed",
    requestFailed   = "requestFailed"
}

NETWORK_STATE = {
    STATE_NONE  = 0,
    STATE_INIT  = 1,
    STATE_CONNECTED     =2,
    STATE_DISCONNECTED  =3
}

local _eventMap_Once = {}

local _eventMap = {}

local _listenMap_Once = {}

local _listener = nil

local _state = NETWORK_STATE.STATE_NONE

function init()
    function onMessage(event, msg)
        if event == NETWORK_EVENT.disconnect or event == NETWORK_EVENT.connectFailed then
            _state = NETWORK_STATE.STATE_DISCONNECTED
        elseif event == NETWORK_EVENT.reconnect or event == NETWORK_EVENT.connected then
            _state = NETWORK_STATE.STATE_CONNECTED
        end
        
        if _eventMap_Once[event] then
            if NETWORK_EVENT.connected == event or NETWORK_EVENT.connectFailed == event then
                _eventMap_Once[event](_state)
                _eventMap_Once[NETWORK_EVENT.connectFailed] = nil
                _eventMap_Once[NETWORK_EVENT.connected] = nil
            else
                _eventMap_Once[event](_state)
                _eventMap_Once[event] = nil
            end
        elseif _eventMap[event] then
            _listener.onEvent(event, msg)
        else
            if msg["code"] == 200 then
                if nil ~= _listener then
                    _listener.parse(msg["result"])
                end
            end
            
            if _listenMap_Once[event] then
                _listenMap_Once[event](msg)
                _listenMap_Once[event] = nil
            end
        end
    end
    
    NetPomelo:getInstance():registerOnMsgLuaCallBack(onMessage)
    
    _state = NETWORK_STATE.STATE_INIT
end

function setListener(listener)
   _listener = listener
end

function connect(ip, port, cb)
    _eventMap_Once[NETWORK_EVENT.connected] = cb
    _eventMap_Once[NETWORK_EVENT.connectFailed] = cb
    NetPomelo:getInstance():connect(tostring(ip), tonumber(port))
end

function nortify(route, msg, cb)
    _listenMap_Once[route] = cb
    NetPomelo:getInstance():pomeloNotify(route, json.encode(msg))
end

function request(route, msg, cb)
    _listenMap_Once[route] = cb
    NetPomelo:getInstance():pomeloRequest(route, json.encode(msg), 0)
end

function httpGet(url, callback)
    NetPomelo:getInstance():httpRequest(url, callback);
end

function registerEvent(event)
    _eventMap[event] = 1
    NetPomelo:getInstance():addListener(event)
end

function removeEvent(event)
    NetPomelo:getInstance():removeListener(event)
end

