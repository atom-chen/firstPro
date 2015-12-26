module("Login", package.seeall)

local ServerProperty = {
    _id     = 0,    --游戏服编号
    _name   = '',   --游戏服名称
    _ip     = '',   --游戏服ip
    _port   = 80,   --游戏服端口
    _color  = '',   --显示颜色
    _state  = "",    --游戏服状态
}

local LoginProperty = {
    _uid = 0,            --用户编号
    _token = '',         --登录令牌
    _lastLoginID = 0,    --上次登录游戏服编号
}

local _login = {}

local _ServerList = {}    --游戏服列表

function split(str, split)
    local list = {}
    local pos = 1
    if string.find("", split, 1) then -- this would result in endless loops
        error("split matches empty string!")
    end
    while 1 do
        local first, last = string.find(str, split, pos)
        if first then -- found?
            table.insert(list, string.sub(str, pos, first-1))
            pos = last+1
        else
            table.insert(list, string.sub(str, pos))
            break
        end
    end
    return list
end

local addServer = function(msg)
    local server = clone(ServerProperty)
    server._id = msg['id']
    server._name = msg['name']
    server._ip = msg['ip']
    server._port = msg['port']
    server._color = split(msg['color'], ",")
    server._state = msg['state']
    
    table.insert(_ServerList, server)
end

local clearServerList = function()
    _ServerList = {}
end

function setLastServerID(id)
     _login._lastLoginID = id
end

function getServerByID(id)
    for i=1, #_ServerList do
        if _ServerList[i]._id ==  id then
            return _ServerList[i]
        end
    end
    return nil
end

function getServerList()
    return _ServerList
end

function getLoginInfo()
    return _login
end

function getLastLoginServer()
    for i=1, #_ServerList do
        if _ServerList[i]._id ==  _login._lastLoginID then
            return _ServerList[i]
        end
    end
    --默认返回最新
    return _ServerList[#_ServerList]
end

function parseLogin(msg)
    clearServerList()
    
    _login = clone(LoginProperty)
    _login._uid = msg['uid']
    _login._token = msg['token']
    _login._lastLoginID = msg['last']
    
    local list = msg['list']
    for i=1, #list do
        addServer( list[i] )
    end
    
    return true
end

