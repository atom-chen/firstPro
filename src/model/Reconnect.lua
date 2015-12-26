module("Reconnect", package.seeall)

--是按钮
local function yesBtnClick()
    widgetUtil.showWaitingNet()
    local server = Login.getLastLoginServer()
    NetWork.connect(server._ip, server._port, function(state)
        if NetWork.NETWORK_STATE.STATE_CONNECTED == state then
            local login = Login.getLoginInfo()

            local request = {}
            request['gid'] = Game.CHANNEL_ID
            request['sid'] = server['_id']
            request['uid'] = login._uid
            request['token'] = login._token
            request['localTime'] = os.time()

            NetWork.request('connector.entryHandler.entry', request, function(msg)
                if msg['code'] == 200 then
                    NetWork.removeEvent("onChat")
                    NetWork.registerEvent("onChat")
                    
                    NetWork.removeEvent("onMail")
                    NetWork.registerEvent("onMail")
                    
                    NetWork.removeEvent("onCharge")
                    NetWork.registerEvent("onCharge")
                    
                    NetWork.removeEvent(NetWork.NETWORK_EVENT.onKick)
                    NetWork.registerEvent(NetWork.NETWORK_EVENT.onKick)
                    
                    NetWork.removeEvent(NetWork.NETWORK_EVENT.disconnect)
                    NetWork.registerEvent(NetWork.NETWORK_EVENT.disconnect)
                    
                    NetWork.removeEvent(NetWork.NETWORK_EVENT.reconnect)
                    NetWork.registerEvent(NetWork.NETWORK_EVENT.reconnect)
                    
                    widgetUtil.removeWaitingNet()
                    --TODO::
                    --UIManager.clearAllWidget()
                    --UIManager.pushScene('MainScene')
                else
                    disconnectEvent()
                end
            end)
        else
            disconnectEvent()
        end
    end)
end

--否按钮
local function noBtnClick()
   cc.Director:getInstance():endToLua()
end

--断线回调
function disconnectEvent()
    widgetUtil.showConfirmBox("网络已断开，是否重连？", 
    function(msg)
        yesBtnClick()
    end,
    function(msg)
        noBtnClick()
    end)
end