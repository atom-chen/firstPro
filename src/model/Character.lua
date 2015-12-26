module("Character", package.seeall)

require("mime")

local t_hero=require("src/config/t_hero")
local t_lv=require("src/config/t_lv")
local t_parameter=require("src/config/t_parameter")
local t_vip_privilege = require('config/t_vip_privilege')

id=0                --玩家ID
name="萌娘玩家"      --玩家名字
level=1             --玩家等级
exp=0               --玩家当前经验
diamond=0           --玩家钻石
gold=0              --玩家金币
vipLevel=0          --玩家VIP等级
vipExp=0            --玩家VIP当前经验

strength = 0        --玩家体力
strthTime = 0       --上次体力更新时间

power = 0           --战斗力
greetings=""        --玩家主角问候语
fashionID=0         --玩家主角时装ID

--每日限制数量
daily = {
    gold = 0,
    strength = 0
}

--获取当前等级的最大经验值
function getMaxExp()
    return t_lv[level].lead_up_exp
end

function getMaxVip()
    return table.maxn(t_vip_privilege)
end

function parseUser(user)
    if user["id"] then
        id = user["id"]
    end
    if user["nick"] then
        name = mime.unb64(user["nick"])
    end
    if user["gold"] then
        gold = user["gold"]
    end
    if user["diamond"] then
        diamond = user["diamond"]
    end
    if user["vip"] then
        vipLevel = user["vip"]
    end
    if user["vipExp"] then
        vipExp = user["vipExp"]
    end
    if user["lv"] then
        level = user["lv"]
    end
    if user["exp"] then
        exp = user["exp"]
    end
    if user["greeting"] then
        greetings = user["greeting"]
        if #greetings > 0 then
            greetings = mime.unb64(greetings)
        end
    end
    if user["fashionID"] then
        fashionID = user["fashionID"]
    end
    if user["power"] then
        power = user["power"]
    end
    
    Event.notify(Const.EVENT.USER, nil)
end

function parseCharge(msg)
    --用户充值钻石数量
    local d = msg["diamond"]
    
    --钻石数量增加
    diamond = diamond + d
    
    vipLevel = msg["vip"]
    vipExp = msg["vipExp"]
    
    Event.notify(Const.EVENT.USER, nil)
    Event.notify(Const.EVENT.CHARGE, d)
end

function parseDaily(msg)
	if msg["gold"] then
        daily["gold"] = msg["gold"]
	end
    if msg["strength"] then
        daily["strength"] = msg["strength"]
    end
end
