module("Arena", package.seeall)

local tParameter = require('src/config/t_parameter')

local _fightFaildTime = 0 --挑战失败的时间,0表示挑战失败时间超时

local _selfInfo = {}      --玩家自己的信息
local _selfInfoItem = {
      reward = 0,         --奖励钻石数量
      score = 0,          --积分
      challenge = 0,      --已挑战次数
      challengeTotal = tParameter.arena_challenge_max.var,     --总挑战次数
      rank = 0 ,           --排名
      refleshTime=0,       --积分兑换 物品上次刷新时间
      exchange = {}         --积分兑换物品表  
}

local _ranking = {}       --排行榜
local _rankingItem = {
    id = 0,               --玩家ID
    lv = 0,               --玩家等级
    nick = "",            --玩家名字
    fashionID = 0,        --玩家头像ID
    power = 0,            --玩家战斗力
    rank = 0,             --玩家排名
    format = {},          --阵容  格式：[-1,-1,2001,1001]
    hero ={}              --[{"id":1001,"star":1,"lv":1,"elv"}]
}

local _users = {}         --挑战对象
local _usersItem = {
    id = 0,               --玩家ID
    lv = 0,               --玩家等级
    nick = "",            --玩家名字
    fashionID = 0,        --玩家头像ID
    power = 0,            --玩家战斗力
    rank = 0,             --玩家排名
    format = {},          --阵容  格式：[-1,-1,2001,1001]
    hero ={}              --[{"id":1001,"star":1,"lv":1}]
}

local _fightLog = {}       --战斗记录
local _fightLogItem = {
    atk = 0,               --攻方玩家ID
    def = 0,               --守方玩家ID
    time =0 ,                 --战斗时间
    rid = "",               --战斗编号
    lv = 0,                --玩家等级
    nick = "",             --玩家昵称
    fashionID = 0,         --头像ID
    power = 0,             --战斗力
    rank = 0               --排名升降
} 

local _report              --战报

--挑战失败时调用,倒计时用
function setFightFaildTime(t)
    _fightFaildTime = t
end

--查询挑战失败的时间
function getFightFaildTime()
    return _fightFaildTime
end

--可挑战用户列表
function getUsersList()
    return _users
end

--玩家自己的信息
function getSelfInfoList()
    return _selfInfo
end

--排行榜玩家信息
function getRankingList()
    return _ranking
end

--第一名玩家信息
function getFristRankPlayer()
    if #_ranking > 0 then
        return _ranking[1]
    end
end

--战斗记录列表
function getFightLogList()
    return _fightLog
end

--玩家自己的排行榜信息
function parseArena(msg)
    if msg["reward"] then --当前排名奖励钻石数量
        _selfInfo["reward"] = msg["reward"]
    end
    if msg["score"] then --积分
        _selfInfo["score"] = msg["score"]
    end
    if msg["challenge"] then --已挑战次数
        _selfInfo["challenge"] = msg["challenge"]
    end
    if msg["rank"] then --排名
        _selfInfo["rank"] = msg["rank"]
    end
    
    if msg["refleshTime"] then --兑换列表刷新时间
        _selfInfo["refleshTime"] = msg["refleshTime"]
    end    
    if msg["exchange"] then --可兑换的物品
        --[{id:1,score:1,state:0,num:1}]
        _selfInfo["exchange"] = msg["exchange"]
    end
    
    if msg["coolTime"] then
        _fightFaildTime = msg["coolTime"]
    end
end

function getExchanges()
    return _selfInfo["exchange"]
end
function getLastFreshTime()
    return _selfInfo["refleshTime"]
end
function getScore()
    return _selfInfo["score"]
end

--排行榜的排名信息
function parseArenaRank(msg)
    _ranking = {} --清空表
    local ranking = msg
    for i=1, #ranking do
        local rankTemp = ranking[i]
        local rankingItem = clone(_rankingItem)
        rankingItem.id = rankTemp["id"]
        rankingItem.lv = rankTemp["lv"]
        rankingItem.nick = commonUtil.strToUtf8(rankTemp["nick"])
        rankingItem.fashionID = rankTemp["fashionID"]
        rankingItem.power = rankTemp["power"]
        rankingItem.rank = rankTemp["rank"]
        rankingItem.format = rankTemp["format"]
        rankingItem.hero = rankTemp["hero"] --[{"id":1001,"star":1,"lv":1}]
        table.insert(_ranking, rankingItem)
    end
end

--可挑战对象
function parseChallenge(msg)
    _users = {} --清空表
    local users = msg
    for i=1, #users do
        local userTemp = users[i]
        local userItem = clone(_usersItem)
        userItem.id = userTemp["id"]
        userItem.lv = userTemp["lv"]
        userItem.nick = commonUtil.strToUtf8(userTemp["nick"])
        userItem.fashionID = userTemp["fashionID"]
        userItem.power = userTemp["power"]
        userItem.rank = userTemp["rank"]
        userItem.format = userTemp["format"]
        userItem.hero = userTemp["hero"] --[{"id":1001,"star":1,"lv":1}]
        table.insert(_users, userItem)
    end
end

--添加战斗记录
local function addRecord(msg)
    local fightTemp = msg
    local fightItem = clone(_fightLogItem)
    fightItem.atk = fightTemp["atk"]
    fightItem.def = fightTemp["def"]
    fightItem.time = fightTemp["time"]
    fightItem.rid = fightTemp["rid"]
    fightItem.lv = fightTemp["lv"]
    fightItem.nick = commonUtil.strToUtf8(fightTemp["nick"])
    fightItem.fashionID = fightTemp["fashionID"]
    fightItem.power = fightTemp["power"]
    fightItem.rank = fightTemp["rank"]
    table.insert(_fightLog, fightItem)
end

--战斗记录
function parseRecord(msg)
    _fightLog = {}

    local records = msg
    if records then
        for i=1, #records do
            addRecord(records[i])
        end
    end    
end

--单条战斗记录
function parseRecordNew(msg)
    addRecord(msg)
end

--解析战报
function parseReport(msg)
    _report = msg["report"]
end

--获得战报
function getReport()
    return _report
end
