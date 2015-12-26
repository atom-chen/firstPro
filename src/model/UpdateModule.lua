
--游戏资源更新模块

module("UpdateModule",package.seeall)

--local ffi = require "ffi"

--ffi.cdef[[
--    void *curl_easy_init();
--    int curl_easy_setopt(void *curl, int option, ...);
--    int curl_easy_perform(void *curl);
--    void curl_easy_cleanup(void *curl);
--    char *curl_easy_strerror(int code);
--    int curl_easy_getinfo(void *curl, int info, ...);
--    
--    typedef unsigned int (*WRITEFUNC)(void *ptr, unsigned int size, unsigned int nmemb, void *userdata);
--    
--    void createUpdateModule(void* packageUrl, void* versionFileUrl, void* storagePath, int defaultVersion);
--]]

--local libcurl = ffi.load("libcurl")

local RES_URL="http://121.207.231.154:3001/"

local widget

local storagePath=cc.FileUtils:getInstance():getWritablePath()

local ON_ERROR= 1
local ON_PROGRESS= 2
local ON_SUCESS= 3
local ON_CURR_DOWNLOAD= 4

local canEnterGame=false


function createScene()
    local scene=cc.Scene:create()
    
    widget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIUpdate.csb")
    widgetUtil.widgetReader(widget)
    
    widget.label_notice:setString(Str.UPDATE_CHECKING)
    widget.label_version:setString(Game.getVersionStr())
    localVersion=cc.UserDefault:getInstance():getIntegerForKey("million-moegirl-version",1000)
    widget:addTouchEventListener(function(_,e)
        if e==ccui.TouchEventType.ended then
            
            if canEnterGame then
                
                canEnterGame=false
                performWithDelay(widget,function() CUpdateModule:releaseInstance() end,0)
                enterGame()
            end
            
        end
    end)
    
    scene:addChild(widget)
    
    performWithDelay(widget,function() beginUpdate() end,0)
    
    return scene
end

function onCallback(code,param1,param2)
    if code==ON_ERROR then
        if param1=="err_no_new_version" then
        
            canEnterGame=true
            widget.label_notice:setString(Str.UPDATE_ERR_NONEW)
        
        elseif param1=="err_network" then
        
            widgetUtil.showConfirmBox(Str.UPDATE_ERR_NETWORK,
                function()
                    cc.Director:getInstance():endToLua()
                end,
                function()
                    cc.Director:getInstance():endToLua()
                end)
        
        elseif param1=="err_create_file" then
        
            widgetUtil.showConfirmBox(Str.UPDATE_ERR_FILE,
                function()
                    cc.Director:getInstance():endToLua()
                end,
                function()
                    cc.Director:getInstance():endToLua()
                end)
            
        elseif param1=="err_uncompress" then
        
            widgetUtil.showConfirmBox(Str.UPDATE_ERR_UNCOMPRESS,
                function()
                    cc.Director:getInstance():endToLua()
                end,
                function()
                    cc.Director:getInstance():endToLua()
                end)
            
        end
    
    elseif code==ON_PROGRESS then
    
        widget.label_prog:setString(string.format("%d%%",param1))
        widget.prog:setPercent(param1)
        
    elseif code==ON_SUCESS then
        cc.UserDefault:getInstance():setIntegerForKey("million-moegirl-version",localVersion)
        cc.UserDefault:getInstance():flush()
        widget.label_version:setString(Game.getVersionStr())
        widget.label_notice:setString(Str.UPDATE_SUCESS)
        canEnterGame=true
        
    elseif code==ON_CURR_DOWNLOAD then
    
        widget.label_file:setString(string.format("%d/%d",param1,param2))
        
    end
end

function beginUpdate()
    local needUpdate,fileCount,totalSize=CUpdateModule:checkUpdate(RES_URL,RES_URL.."version.txt",storagePath,1000,onCallback)
    if needUpdate then
        local size=totalSize/1024/1024
        if size<0.09999 then size=0.09 end
        widgetUtil.showConfirmBox(string.format(Str.NEED_UPDATE_SIZE,fileCount,size),function()
            localVersion=localVersion+fileCount
            CUpdateModule:beginUpdate()
            widget.label_notice:setString(Str.UPDATE_DOWNLOADING)
            
        end,
        function()
            cc.Director:getInstance():endToLua()
        end)
    end 
end

function enterGame()

--重新加载
    package.loaded["src/util/Str"]=nil
    package.loaded["src/model/Game"]=nil
    package.loaded["src/util/widgetUtil"]=nil
    package.loaded["src/model/UpdateModule"]=nil

    require "src/util/Str"
    require "src/model/Game"
    require "src/util/widgetUtil"
    require "src/model/UpdateModule"
    
    require "src/Event"
    require "src/NetWork"
    require "src/UIManager"
    require "src/util/commonUtil"
    require "src/const/Const"
    require "src/util/eventUtil"
    require "src/model/Model"
    
    NetWork.init()
    NetWork.setListener(Model)
    
    if cc.Director:getInstance():getRunningScene() ~= nil then
        UIManager.replaceScene('LoginScene')
    else
        UIManager.pushScene('LoginScene')
    end
    UIManager.pushWidget('loginWidget')
    
end

--function checkUpdate()
--
--    
--
--    localVersion=tonumber(cc.UserDefault:getInstance():getStringForKey("million_moegirl_version", tostring(Game.ResVersion)))
--    local curl = libcurl.curl_easy_init()
--    if curl then
--        
--        local version=""
--        local getVersionCode = ffi.cast("WRITEFUNC", function(ptr,size,nmemb,userdata)
--            version=version..ffi.string(ptr)
--            return size*nmemb
--        end)
--        
--        libcurl.curl_easy_setopt(curl, CURLOPT_URL, RES_URL.."version.txt")
--        libcurl.curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
--        libcurl.curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, getVersionCode)
--        libcurl.curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1)
--        libcurl.curl_easy_setopt(curl, CURLOPT_LOW_SPEED_LIMIT, 1)
--        libcurl.curl_easy_setopt(curl, CURLOPT_LOW_SPEED_TIME, 5)
--        
--        local res = libcurl.curl_easy_perform(curl)
--        if res ~= 0 then
--            print(ffi.string(libcurl.curl_easy_strerror(res)))
--        end
--        libcurl.curl_easy_cleanup(curl)
--        getVersionCode:free()
--        
--        remoteVersion=tonumber(version)
--    end
--    
--    if localVersion<remoteVersion then
--        local totalSize=getAllVersionSize()/1024/1024
--        widgetUtil.showConfirmBox(string.format(Str.NEED_UPDATE_SIZE,totalSize),
--        function()
--            downloadAndUncompress()
--        end,
--        function()
--            cc.Director:getInstance():endToLua()
--        end)
--        
--    end
--end

--获取所有更新文件版本的大小
--function getAllVersionSize()
--
--    local curl = libcurl.curl_easy_init()
--    if curl then
--        local totalSize=0
--        local size=ffi.new("double[1]")
--        
--        for i=localVersion+1,remoteVersion do
--
--            libcurl.curl_easy_setopt(curl, CURLOPT_URL, string.format("%s%d.zip",RES_URL,i))
--            libcurl.curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1)
--            libcurl.curl_easy_setopt(curl, CURLOPT_NOBODY, 1)
--    
--            local res = libcurl.curl_easy_perform(curl)
--            if res ~= 0 then
--                print(ffi.string(libcurl.curl_easy_strerror(res)))
--            end
--            
--            libcurl.curl_easy_getinfo(curl,CURLINFO_CONTENT_LENGTH_DOWNLOAD,size)
--            
--            
--            totalSize=totalSize+size[0]
--            
--        end
--        
--        libcurl.curl_easy_cleanup(curl)
--        
--        return totalSize
--    end
--    return 0
--    
--end


