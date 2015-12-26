
module("commonUtil", package.seeall)

local t_music=require("config/t_music")
local curPlayMusicID = 0 --当前播放背景音乐的ID
require("mime")

function randomseed(n)
    __RANDOMSEED__=n
end

function random(m,n)
    if __RANDOMSEED__==nil then
        __RANDOMSEED__=1
    end
    local RAND_MAX=214748364
    local quotient,remainder,t
    quotient=__RANDOMSEED__/127773
    remainder=__RANDOMSEED__%127773
    t=16807*remainder-2836*quotient
    if t<0 then
        t=t+2147483647
    end
    __RANDOMSEED__=t
    local r=t%(RAND_MAX+1)

    if m and not n then
        return math.floor(r*m/(RAND_MAX+1)+1)
    end
    if m and n then
        return math.floor(r*(n-m+1)/(RAND_MAX+1)+m)
    end
    return r/(RAND_MAX+1)
end

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

--@param size 截取长度限制
--@param instead 超过长限制的是否用 "…" 代替
--@return 替换后的文本，是否超过长度
function clipString(str, size , instead)
    local count = 0
    local len = 0
    local seq = 0
    local flag = false

    for i = 1, #str do 
        if seq == 0 then 
            local c = string.byte(str, i) 

            seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or 
                c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or 
                error("invalid UTF-8 character sequence")              

            local n = 0
            if seq == 1 then
                n = 1
            else
                n = 2
            end            
            if len + n > size then
                flag = true
                break
            end
            len = len + n
            count = count + seq
        end 
        seq = seq - 1 
    end 

    local s = string.sub(str, 1, count)
    if flag then
        if instead then
            return s .. "…",flag
        end
    end
    return s,flag
end

--@param tbl 枚举表
--@param index 起始值
function createEnum(tbl, index)
    local enumtbl = {} 
    local enumindex = index or 0 
    for i, v in ipairs(tbl) do 
        enumtbl[v] = enumindex + i 
    end 
    return enumtbl 
end

local function pdf2cdf(pdf)
    local cdf = pdf

    for i=2,#pdf do
        cdf[i] = cdf[i]+cdf[i-1]
    end
    cdf[#pdf] = Const.DENOMINATOR

    return cdf
end


---------------------------
--指定概率是否能发生
--@param prob:概率值
function isProbHappen(prob)

    local total=Const.DENOMINATOR
    if prob<=0 then return false end
    if prob>=total then return true end
    
	local pdf={}
    table.insert(pdf,prob)
    table.insert(pdf,total-prob)
	
    local cdf=pdf2cdf(pdf)
	
    local r=math.random(1,total-1)
    for i=1,#cdf do
        if r<cdf[i] then
            return i==1
        end
    end
    return false
end

---------------------------
--给定位置的概率是否能在给定的概率组内发生,如：isProbWithArray(2,{1000,2000,3000,4000})
--20%的概率是否发生
--@param prob:概率值
--@param probs:概率数组
function isProbWithArray(pos,probs)

    local total=Const.DENOMINATOR

    local cdf=pdf2cdf(probs)

    local r=math.random(1,total-1)
    for i=1,#cdf do
        if r<cdf[i] then
            return i==pos
        end
    end
    return false
end

---------------------------
--返回概率数组的发生位,如：isProbWithArray({1000,2000,3000,4000})
--@param probs:概率数组
function isProbWithArrayEx(probs)

    local total=Const.DENOMINATOR

    local cdf=pdf2cdf(probs)

    local r=math.random(1,total-1)
    for i=1,#cdf do
        if r<cdf[i] then
            return i
        end
    end
    return 1
end

----------------------------------
--读取res/effect/animation的特效动画
--@param id 特效ID
--@return #type superAnimNode
function getAnim(id)
    local path=string.format("effect/animation/%d/%d.sam",id,id)
    local anim=sa.SuperAnimNode:create(path, 0, nil)
    anim:setSpeedFactor(22/24)
    return anim
end

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

function getFont()
    if kTargetIphone == targetPlatform or kTargetIpad == targetPlatform then
        return "FZZYJW"
    else
        return "fonts/FZZYJW.ttf"
    end
end


---------------------------
--@param
--@return
function preloadEffect(path)
    cc.SimpleAudioEngine:getInstance():preloadEffect(cc.FileUtils:getInstance():fullPathForFilename(path))
end

---------------------------
--@param
--@return
function unloadEffect(path)
    cc.SimpleAudioEngine:getInstance():unloadEffect(cc.FileUtils:getInstance():fullPathForFilename(path))
end

---------------------------
--@param
--@return
function playEffect(path,bLoop)
    cc.SimpleAudioEngine:getInstance():playEffect(cc.FileUtils:getInstance():fullPathForFilename(path),bLoop or false,0,0,0)
end

---------------------------
--@param
--@return
function playMusic(path,bLoop)
    cc.SimpleAudioEngine:getInstance():playMusic(cc.FileUtils:getInstance():fullPathForFilename(path),bLoop or true)
end

--播放背景音乐
function playBakGroundMusic(id)
    if t_music[id] and t_music[id].path then
        if curPlayMusicID ~= id then
            playMusic(t_music[id].path, true)
            curPlayMusicID = id
        end
    else
        cc.SimpleAudioEngine:getInstance():stopMusic()
        curPlayMusicID = 0
    end
end

--获取两点间旋转角
function getAngle(dir)
    local M_PI = 3.1415926

    local angle;
    
    local ix = dir.x;
    local iy = dir.y;
    
    if ix >= 0 and iy < 0 then
        if ix == 0 then
            angle = 270;
        else
            angle = 180 + math.atan(-iy / ix) * 180 / M_PI
        end
    elseif ix > 0 and iy >= 0 then
        if iy == 0 then
            angle = 180;
        else
            angle = 90 + math.atan(ix / iy) * 180 / M_PI
        end
    elseif ix <= 0 and iy > 0 then
        if ix == 0 then
            angle = 90;
        else
            angle = math.atan(iy / -ix) * 180 / M_PI
        end
    else
        if iy == 0 then
            angle = 0;
        else
            angle = 270 + math.atan(ix / iy) * 180 / M_PI
        end
    end
    
    return angle;
end

function ltrim(str)
    return string.gsub(str, "^[ \t\n\r]+", "")
end

function rtrim(str)
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function sizeString(strUTF32)
    local size = 0
	for i=1, #strUTF32 do
	   if strUTF32[i] > 128 then
	       size = size + 2
	   else
	       size = size + 1
	   end
	end
	return size
end

--字符串转换,转成utf8
function strToUtf8(str)
    return mime.unb64(str)
end

