
require "Cocos2d"

require "src/util/Str"
require "src/model/Game"
require "src/util/widgetUtil"
require "src/util/particleUtil"
require "src/model/UpdateModule"

require "bitExtend"
function xor(a,b)
    local bit_a=bit._d2b(a)
    local bit_b=bit._d2b(b)
    local bit_r={}
    for i=1,32 do
        if bit_a[i]~=bit_b[i] then
            bit_r[i]=1
        else
            bit_r[i]=0
        end
    end
    return bit._b2d(bit_r)
end

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    local seed=tonumber(tostring(os.time()):reverse():sub(1, 6))
    math.randomseed(seed)

    Str.init()
    
    cc.FileUtils:getInstance():addSearchPath("src")
    cc.FileUtils:getInstance():addSearchPath("res")
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(960, 640, 3)
    
    
    if cc.Application:getInstance():getTargetPlatform()==kTargetWindows then
        UpdateModule.enterGame()
    else
        CUpdateModule:setSearchPath(cc.FileUtils:getInstance():getWritablePath())
        cc.Director:getInstance():pushScene(UpdateModule.createScene())
    end
    
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
