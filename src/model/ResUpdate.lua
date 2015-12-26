
--游戏资源更新模块

module("ResUpdate",package.seeall)

local ffi = require "ffi"

local CURLINFO_CONTENT_LENGTH_DOWNLOAD=3145743
local CURLOPT_URL = 10002
local CURLOPT_SSL_VERIFYPEER = 64
local CURLOPT_WRITEFUNCTION=20011
local CURLOPT_WRITEDATA=10001
local CURLOPT_NOSIGNAL=99
local CURLOPT_LOW_SPEED_LIMIT=19
local CURLOPT_LOW_SPEED_TIME=20
local CURLOPT_NOPROGRESS=43
local CURLOPT_NOBODY=44

local RES_URL="http://bajackie.gotoip3.com/"

local widget

local localVersion      --本地版本号
local remoteVersion     --远程服务器版本号

ffi.cdef[[
    void *curl_easy_init();
    int curl_easy_setopt(void *curl, int option, ...);
    int curl_easy_perform(void *curl);
    void curl_easy_cleanup(void *curl);
    char *curl_easy_strerror(int code);
    int curl_easy_getinfo(void *curl, int info, ...);
    
    typedef unsigned int (*WRITEFUNC)(void *ptr, unsigned int size, unsigned int nmemb, void *userdata);
]]

local libcurl = ffi.load("libcurl")


function createScene()
    local scene=cc.Scene:create()
    
    widget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIUpdate.csb")
    widgetUtil.widgetReader(widget)
    
    widget.label_notice:setString("正在检查更新...")
    widget.label_version:setString(Game.getVersionStr())
    
    scene:addChild(widget)
    
    performWithDelay(widget,function() checkUpdate() end,0)
    
    return scene
end

function checkUpdate()

    localVersion=tonumber(cc.UserDefault:getInstance():getStringForKey("current-version-code", tostring(Game.ResVersion)))
    local curl = libcurl.curl_easy_init()
    if curl then
        
        local version=""
        local getVersionCode = ffi.cast("WRITEFUNC", function(ptr,size,nmemb,userdata)
            version=version..ffi.string(ptr)
            return size*nmemb
        end)
        
        libcurl.curl_easy_setopt(curl, CURLOPT_URL, RES_URL.."version.txt")
        libcurl.curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
        libcurl.curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, getVersionCode)
        libcurl.curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1)
        libcurl.curl_easy_setopt(curl, CURLOPT_LOW_SPEED_LIMIT, 1)
        libcurl.curl_easy_setopt(curl, CURLOPT_LOW_SPEED_TIME, 5)
        
        local res = libcurl.curl_easy_perform(curl)
        if res ~= 0 then
            print(ffi.string(libcurl.curl_easy_strerror(res)))
        end
        libcurl.curl_easy_cleanup(curl)
        getVersionCode:free()
        
        remoteVersion=tonumber(version)
    end
    
    if localVersion<remoteVersion then
        local totalSize=getAllVersionSize()/1024/1024
        widgetUtil.showConfirmBox(string.format(Str.NEED_UPDATE_SIZE,totalSize))
        
    end
end

--获取所有更新文件版本的大小
function getAllVersionSize()

    local curl = libcurl.curl_easy_init()
    if curl then
        local totalSize=0
        local size=ffi.new("double[1]")
        
        for i=localVersion+1,remoteVersion do

            libcurl.curl_easy_setopt(curl, CURLOPT_URL, string.format("%s%d.zip",RES_URL,i))
            libcurl.curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1)
            libcurl.curl_easy_setopt(curl, CURLOPT_NOBODY, 1)
    
            local res = libcurl.curl_easy_perform(curl)
            if res ~= 0 then
                print(ffi.string(libcurl.curl_easy_strerror(res)))
            end
            
            libcurl.curl_easy_getinfo(curl,CURLINFO_CONTENT_LENGTH_DOWNLOAD,size)
            
            
            totalSize=totalSize+size[0]
            
        end
        
        libcurl.curl_easy_cleanup(curl)
        
        return totalSize
    end
    return 0
    
end