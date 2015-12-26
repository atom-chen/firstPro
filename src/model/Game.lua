

module("Game",package.seeall)

--SERVER_URL  = 'http://192.168.16.88:1337/login'     --游戏登陆地址
SERVER_URL  = 'http://121.207.231.154:1337/login'     --游戏登陆地址

CHANNEL_ID   = 10000                                 --游戏渠道号

--游戏版本号
MajorVersion="v1.0.0"
--资源版本号
ResVersion=1000

--游戏版本字符串 vn.n.n.n
function getVersionStr()
    ResVersion=cc.UserDefault:getInstance():getIntegerForKey("million-moegirl-version",ResVersion)
    return MajorVersion.."."..tostring(ResVersion)
end

--字符串版本号转字符串
-- nnnn -> vn.n.n.n
function versionNum2str(ver)
    local str=tostring(ver)
    local res,_=string.gsub(str,"%d",".%1")

    return string.format("v%s",string.sub(res,2,string.len(res)))
end

--字符串版本号转数字
-- vn.n.n.n -> nnnn
function versionStr2Number(str)
    local temp=string.sub(str,2,string.len(str))
    local res,_=string.gsub(temp,"%.","")
    return tonumber(res)
end


--function checkUpdate()
--end

local _lag = 0 --时间延迟
local _zone = 0 --服务器时区

function setTimeLag(lag)
	_lag = lag
end

function setTimeZone(zone)
    _zone = zone
end

function time()
    return os.time() + _lag
end

function midnight()
    local now = time()
    local l = now + _zone * 3600
    return l - l % (24 * 3600) - _zone * 3600
end

function zone()
    return _zone
end

