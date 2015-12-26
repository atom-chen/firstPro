module("Copy", package.seeall)

--module require
local t_chapter = require('src/config/t_chapter')
local t_chapter_fuben = require('src/config/t_chapter_fuben')
local team_config=require("config/t_team")              --副本怪物组表
local monster_config=require("config/t_team_monster")   --怪物表

--variable
ChapterProperty={
    story = 0,      --节点剧情
    num = 0,        --当日攻打次数
    stay = 0,       --停留点
    pass = 0,       --停留点是否通过
    clear = 0,      --该章节是否通关
    copys = {},      --副本节点信息
    stars = {}
}

CopyProperty={
    star = 0,      --通过星级
    story = 0,     --节点剧情
    hp = 0         --BOSS
}

local token ="" --攻打副本战斗标识

local _copy = nil --副本   

--计算所有类型为1的所有副本的星星数量
local _Stars = 0

local activityProperty={
    bill = 0,          --显示时间
    startTime = 0,     --开始时间
    endTime = 0        --结束时间

}
--服务器发来的活动信息
local _activity = {}


function isLoadded()
	return nil ~= _copy
end

function clearCopy()
    _copy = {}
end

--服务器保存的章节信息
function getChapter(chapter)
    return _copy[chapter]
end

--服务器保存的 章节对应的副本信息
function getCopy(chapter)
    if _copy[chapter] then
        return _copy[chapter]["copys"]
    end
    return nil
end

--章节是否要显示剧情
function isPlayChapterStory(chapterId)
    if nil ~= _copy[chapterId] then
        return _copy[chapterId]["story"] == 0
    else
        return true
    end     
end

--副本是否要播剧情
function isPlayFuStory(chapterId, id)
    if nil == _copy[chapterId] then
        return true
    end
    local copy = _copy[chapterId][id]
    if nil == copy then
        return true
    end
    return copy["story"] == 0
end
	

--章节剧情播完
function setChapterStoryAlready(chapterId)
    if nil == _copy[chapterId] then
        _copy[chapterId] = {}
        _copy[chapterId] = clone(ChapterProperty)
    end    
	_copy[chapterId]["story"] = 1
end

--副本剧情播完
function setFuStoryAlready(chapterId, fuId)
    if nil == _copy[chapterId] then
        _copy[chapterId] = {}
        _copy[chapterId] = clone(ChapterProperty)
    end
    local copys = _copy[chapterId]["copys"]
    if nil == copys[fuId] then
        copys[fuId] = clone(CopyProperty)
    end
    local copy = copys[fuId]
    copy["story"] = 1
end

--查询服务器保存的某章节的所有副本
function getCopys(chapter)
    if not _copy then return nil end
    
    local copys = nil
    if _copy[chapter] and _copy[chapter]["copys"] then
        copys = _copy[chapter]["copys"] 
    end
    return copys
end

--查表获取普通章节有序节点数组
function getChapterItems()
    local arr = {}
    
    for chapter, v in pairs(t_chapter) do
        if 0 == v["open_instance"] and Const.CHAPTER_TYPE.NORMAL == v["type"] then
            table.insert(arr, chapter)
            break
        end
    end
    
    if #arr ~= 1 then
        return arr
    end
    
    local cid = arr[1]
    while true do
        local found = false
        for chapter, v in pairs(t_chapter) do
            if cid == v["open_instance"] and Const.CHAPTER_TYPE.NORMAL == v["type"] then
                table.insert(arr, chapter)
                cid = chapter
                found = true
            end
        end
        
        if not found then
            break
        end
    end
    
    return arr
end

--获取非普通章节数组
function getSpecChapterItems()
    local arr = {}

    for chapter, v in pairs(t_chapter) do
        if Const.CHAPTER_TYPE.NORMAL ~= v["type"] then
            table.insert(arr, chapter)
        end
    end

    return arr
end

--(查表)获取章节下所有副本,第一个为起始节点
--chapterID章节ID
function getCopyItems(chapterID)
    return t_chapter_fuben[tonumber(chapterID)]
end

--判断某章节的副本是否通关
function isCopyItemPass(chapter, copyID)  
    if not copyID then
        return false
    end
    
    if copyID == 0 then
        return true
    end
    
    if nil == t_chapter_fuben[chapter] or nil == t_chapter_fuben[chapter][copyID] then
        return false
    end
    
    local type = t_chapter_fuben[chapter][copyID]["type"] --起始点是认为通关的
    if type == Const.COPY_TYPE.START then
        return true
    end
    if nil == _copy[chapter] then
        return false
    end
    
    return _copy[chapter]["pass"] > 0
end

--判断某章节的副本的星级
function copyItemStars(chapter, copyID)
    local stars = 0
    
    if copyID == 0 then
        return stars
    end

    if nil == t_chapter_fuben[chapter] or nil == t_chapter_fuben[chapter][copyID] then
        return stars
    end

    local type = t_chapter_fuben[chapter][copyID]["type"] --起始点是认为通关的
    if type == Const.COPY_TYPE.START then
        return stars
    end
    if nil == _copy[chapter] then
        return stars
    end

    if nil == _copy[chapter]["copys"][copyID] then
        return stars
    end

    local item = _copy[chapter]["copys"][copyID]

    stars = item.star

    return stars
end

--检查是否通关某章节
function isClearance(chapterID)
    if 0 == chapterID then
        return true
    end
    
    local charpter = getChapter(chapterID)
    if nil == charpter then
        return false
    end
    
    return charpter["clear"] > 0
end

--获取前置章节编号
function getPreCharterID(chapterID)
    if t_chapter[chapterID] then
        return t_chapter[chapterID]["open_instance"]
    else
        return -1
    end
end

--获取某章节的副本的stay
function getChapterStay(chapterID)
    local chapter = _copy[tonumber(chapterID)]
    if not chapter then
        return
    end
    
    return _copy[chapterID]["stay"]
end

--查询活动 chapterID   nil:所有活动，        >0 :章节ID
function getActivity(chapterID)
   if chapterID then
        return _activity[chapterID]
   end
   
   return _activity
end

--解析活动/boss章节
function parseActivity(msg)
   local activity = msg
   for i=1, #activity do
       local id = tonumber(activity[i]["id"])
       local bill = activity[i]["bill"]
       local startTime = activity[i]["start"]
       local endTime = activity[i]["end"]
       
       _activity[id] = clone(activityProperty)
       _activity[id]["bill"] = bill
       _activity[id]["startTime"] = startTime
       _activity[id]["endTime"] = endTime
   end
end

--解析副本数据
function parseCopyVal(val)
    if val["strength"] then
        Character.strength = val["strength"]
        Event.notify(Const.EVENT.STRENGTH)
    end
    if val["strthTime"] then
        Character.strthTime = val["strthTime"]
        Timer.startStrengthTime()
    end
    
    if val["token"] then
        token = val["token"]
    end
end

function parseCopy(copy)
    local sync = false
    if copy["_sync_"] then
        sync = true
    end
    
    if not sync then
        _copy = {}
    end
    
    if copy["stars"] then
        _Stars = copy["stars"]
    end
    
    copys = copy["copys"]
    if nil == copys then
        return
    end

    for i=1, #copys do
        local cInfo = copys[i]        
        local chapter = tonumber(cInfo["id"]) --章节ID
        
        local c = _copy[chapter]
        if nil == c then
            _copy[chapter] = clone(ChapterProperty)
            c = _copy[chapter]
        end
        
        if cInfo["story"] then
            c["story"] = cInfo["story"]
        end
        if cInfo["stay"] then
            c["stay"] = cInfo["stay"]
        end
        if cInfo["num"] then
            c["num"] = cInfo["num"]
        end
        if cInfo["pass"] then
            c["pass"] = cInfo["pass"]
        end 
        if cInfo["clear"] then
            c["clear"] = cInfo["clear"]
        end           
        
        local items = cInfo["copys"]
        if items then
            if #items == 0 then
                c["copys"] = {}
            else
                for j=1, #items do
                    local id = tonumber(items[j]["id"]) --副本ID
                    local item = c["copys"][id]
                    if nil == item then
                        c["copys"][id] = clone(CopyProperty)
                        item = c["copys"][id]
                    end
                    if items[j]["star"] then
                        item.star = items[j]["star"]
                    end
                    if items[j]["story"] then
                        item.story = items[j]["story"]
                    end
                    if items[j]["hp"] then
                        item.hp = items[j]["hp"]
                    end
                end
            end
        end
        
        local stars = cInfo["stars"]
        if stars then
            if #stars == 0 then
                c["stars"] = {}
            else
                for k=1, #stars do
                    local id = tonumber(stars[k]["id"])
                    c["stars"][id] = stars[k]["star"]
                end
            end
        end
    end
end

--获取token
function getToken()
    return token
end

--查询所有类型为1的所有副本的星星数量
function getStars()
    return _Stars
end

--查询某章节的剩余挑战次数
function getCharpterFightNum(chapterId)
    if nil ~= _copy[chapterId] then
        return _copy[chapterId]["num"]
    end    
    return 0
end

--查询章节类型为2的boss的丢失血量
function getCharpterBossHP(chapterId)
    local hp = 0
    if nil ~= _copy[chapterId] then
        local copys = _copy[chapterId]["copys"]
        for copyID,v in pairs(copys) do
            hp = hp + v["hp"]
        end
    end 
    
    return hp
end

--查询章节类型为2的boss的总血量,boss名称
function getCharpterBossTotalHP(chapterId)
    local bossName = ""
    local hp = 0
    local copys = getCopyItems(chapterId)
    for copyID, v in pairs(copys) do
        if v["type"] == Const.COPY_TYPE.HP_BOSS then
            local teamCfg = team_config[v["battle_team"]]
            if teamCfg["monster"][1] then
                local monsterCfg = monster_config[teamCfg["monster"][1]]
                hp = hp + monsterCfg["hp"]
                bossName = monsterCfg["name"] --目前一个章节里面只有一个BOSS
            end
        end
    end

    return hp, bossName
end

--某章节获得的星级和总星级
function getCharpterStar(chapterId)
    local starsHad = 0
    local starsTotal = 0

    if chapterId == 0 then
        return starsHad, starsTotal
    end

    local copys = t_chapter_fuben[chapterId]
    if nil == copys then
        return starsHad, starsTotal
    end
    
    for k,v in pairs(copys) do
        if v["type"] == Const.COPY_TYPE.BIG_FIGHT then --仅计算大战斗点的星级
            starsTotal = starsTotal + 3
            
            if nil ~= _copy[chapterId] and nil ~= _copy[chapterId]["copys"] and
               nil ~= _copy[chapterId]["copys"][k] then
                local copy = _copy[chapterId]["copys"][k]
                starsHad = starsHad + copy.star
            end 
        end
    end

    return starsHad, starsTotal
end

--获取某章节的下一章ID，没有返回0
function getNextChapterID(curID)
    for chapter, v in pairs(t_chapter) do
        if curID == v["open_instance"] then
            return chapter
        end
    end
    
    return 0
end
