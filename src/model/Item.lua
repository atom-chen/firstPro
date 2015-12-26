module("Item", package.seeall)

local t_item =require('src/config/t_item')

--物品表
local _items = {}

local _shops = {}       --商店物品列表
local _refleshTime=0     --上次商店物品刷新时间

--奖品表
local _itemReward

--获取物品数量
function getNum(itemID)
    local num = 0
    if _items[itemID] then
        num = _items[itemID]
    end
    return num
end

function clearItems()
    _items = {}
end

function parseItems(item)
    local sync = false
    if item["_sync_"] then
        sync = true
    end
    
    if not sync then
        clearItems()
    end
    
    local items = item["items"]
    for i=1, #items do
        local itemID = items[i]["id"]
        local num = items[i]["num"]
        _items[itemID] = num
    end
    
    Event.notify(Const.EVENT.ITEM, nil)
end

function parseShops(msg)
    if msg["refleshTime"] then --本次刷新时间
        _refleshTime = msg["refleshTime"]
    end    

    if msg["shop"] then 
        --[{id:1,diamond:1,state:0,num:1}]
        _shops = msg["shop"]
    end
end

function getShops()
    return _shops
end
function getLastFreshTime()
    return _refleshTime
end


--保存奖励物品
function parseRewardItems(msg)
    _itemReward = msg
end

--获得奖励物品
function getRewardItems()
    return _itemReward
end