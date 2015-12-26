module("CardReward", package.seeall)

local tParameter = require('src/config/t_parameter')

local _draftFree = 0 --已使用的抽卡次数
local _draftTime=0  --上一次免费挖掘时间
local _recuitTime=0   --上一次免费招募时间

local _exchanges={}      --徽章兑换物品表  
local _refleshTime=0     --徽章兑换  物品上次刷新时间

--设置密保挖掘的冷却时间
function setDigTime(t)
    _draftTime = t
end

--查询密保挖掘冷却时间
function getDigTime()
    return _draftTime
end

--设置英雄招募的冷却时间
function setItemRewardTime(t)
    _recuitTime = t
end

--查询英雄招募冷却时间
function getItemRewardTime()
    return _recuitTime
end

--查询密宝挖掘已使用次数
function getItemRewardUseNum()
    return _draftFree
end


function getExchanges()
    return _exchanges
end
function getLastFreshTime()
    return _refleshTime
end

--抽卡信息
function parseCard(msg)
    if msg["draftFree"] then --已使用的抽卡次数
        _draftFree = msg["draftFree"]
    end
    
    if msg["draftTime"] then --上一次免费挖掘时间
        _draftTime = msg["draftTime"]
    end
    
    if msg["recuitTime"] then --上一次免费招募时间
        _recuitTime = msg["recuitTime"]
    end
    
    if msg["refleshTime"] then --本次刷新时间
        _refleshTime = msg["refleshTime"]
    end    
    
    if msg["exchange"] then --兑换列表
        --[{id:1,badge:1,state:0,num:1}]
        _exchanges = msg["exchange"]
    end
end