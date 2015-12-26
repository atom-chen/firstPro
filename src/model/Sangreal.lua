module("Sangreal", package.seeall)

local t_sangreal=require('src/config/t_sangreal')
local t_sangreal_up=require('src/config/t_sangreal_up')

local _card = 0 --保护卡
local _robTimes = 0 --今日抢夺次数
local _inspire = 0 --祝福

local _curSangreal = 0 --当前圣杯id
local _sangreal = {} --存放圣杯等级

local _enemy = {}   --宿敌
local _fragpvp={}   --普通玩家列表 

local PlayerProperty = {
    _playerId  =0,    --目标Id
    _lv     = 0,    --等级
    _nick    = 0,    --昵称
    _fashionID=0,    --时装
    _num   = 0,    --碎片个数
    _hate = 0,    --是否为仇敌
    _time = 0,    --上次抢夺时间
    _power,       --战斗力
    _format,      --英雄
    _hero         --英雄信息 [{"id":1001,"star":1,"lv":1}]
}


local _robbedTimes = 0 --今日被夺次数

local _fragment = {} --碎片信息

local _msg={}    --碎片抢夺消息记录

local msgProperty = {
    _type  =0,    --消息类型
    _time   = 0,    --时间
    _msg   = 0,    --消息
}

function getRobTimes()
    return _robTimes
end
function getRobbedTimes()
    return _robbedTimes
end

function getMsg()
    return _msg
end

function getEnemy()
    return _enemy
end
--先按是否仇敌排序，再按抢夺时间排序宿敌
function sortEnemyByTime(enemy1, enemy2)
    if enemy1._hate == enemy2._hate then   
        return enemy1._time > enemy2._time  
    else
        return enemy1._hate > enemy2._hate
    end 
end

function getFragpvp()
    return _fragpvp
end

--获得碎片几的个数
function getFragmentNum(fragmentId)
    return _fragment[fragmentId]
end

--判断圣杯强化所需的碎片是否足够
function isFragmentEnough(lv)
    lv=lv+1
    if lv>99 then
    	lv=99
    end
    local piece_cost=t_sangreal_up[lv]["piece_cost"]   --圣杯强化到下级需要的碎片数量
    for i=6001, 6006 do
        if _fragment[i]<piece_cost then
    		return false
    	end
    end
    return true
end

--获得圣杯等级
function getSangrealLv(sangrealId)
    return _sangreal[sangrealId]
end

function getProtectCard()
    return _card
end
function getCurSangrealId()
    return _curSangreal
end

--获得圣杯全队属性加成值
function getSangrealAttAddition(sangrealId)
    local values={}
    local sangreal=t_sangreal[sangrealId]
    local lv=getSangrealLv(sangrealId)
    lv=lv+1
    if lv>99 then
    	lv=99
    end
    if sangreal then
        if sangreal.all_atk~=0 then
            local atkUp=sangreal.all_atk*t_sangreal_up[lv]["atk_up"]/Const.DENOMINATOR
            atkUp=math.ceil(atkUp)
            table.insert(values,atkUp)
        end
        if sangreal.all_hp~=0 then
            local hpUp=sangreal.all_hp*t_sangreal_up[lv]["hp_up"]/Const.DENOMINATOR
            hpUp=math.ceil(hpUp)
            table.insert(values,hpUp)
        end
        if sangreal.all_water~=0 then
            local waterUp=sangreal.all_water*t_sangreal_up[lv]["water_up"]/Const.DENOMINATOR
            waterUp=math.ceil(waterUp)
            table.insert(values,waterUp)
        end
        if sangreal.all_fire~=0 then
            local fireUp=sangreal.all_fire*t_sangreal_up[lv]["fire_up"]/Const.DENOMINATOR
            fireUp=math.ceil(fireUp)
            table.insert(values,fireUp)
        end
        if sangreal.all_wood~=0 then
            local woodUp=sangreal.all_wood*t_sangreal_up[lv]["wood_up"]/Const.DENOMINATOR
            woodUp=math.ceil(woodUp)
            table.insert(values,woodUp)
        end    
    end
    return values
end

function parseSangreal(sangreal)
    if sangreal["card"] then
        _card=sangreal["card"]
    end
    if sangreal["rob"] then
        _robTimes=sangreal["rob"]
    end
    if sangreal["inspire"] then
        _inspire=sangreal["inspire"]
    end
    if sangreal["cur"] then
        _curSangreal=sangreal["cur"]
    end
    
    if sangreal["sangreal"] then
        local s = sangreal["sangreal"]
        for i=1, #s do
            _sangreal[i] = s[i]
        end
    end    
end

function parseFragment(fragment)
    _fragment = {}
    for i=1, 6 do
        _fragment[6000+i]=fragment["frag"..i]
    end
    _robbedTimes=fragment["robbed"]
end

function parseEnemy(enemy)
    _enemy = {}
    
    local enemys = enemy["enemys"]
    if enemys then
        for i=1, #enemys do
            local enemy = enemys[i]
                                  
            local enemyData = clone(PlayerProperty)            
            enemyData._playerId = enemy["id"]
            enemyData._lv=v["lv"]
            enemyData._nick=v["nick"]
            enemyData._fashionID=v["fashionID"]
            enemyData._num=v["num"]
            enemyData._hate=v["hate"]
            enemyData._time=v["time"]
            enemyData._power = v["power"]
            enemyData._format = v["format"]
            enemyData._hero = v["hero"] --[{"id":1001,"star":1,"lv":1}]

            table.insert(_enemy, enemyData)
        end
    end
    
    _msg={}
    
    local msg = enemy["msg"]
    if msg then
        for i=1, #msg do
            local m = clone(msgProperty)
            m._type=msg[i]["type"]
            m._time=msg[i]["time"]
            m._msg=msg[i]["msg"]

            table.insert(_msg, m)
        end
    end
end

function parseFragpvp(fragpvp)    --解析普通玩家
    _fragpvp = {}
    
    for id, v in pairs(fragpvp) do
        local playerData = clone(PlayerProperty)
        id = tonumber(id)

        playerData._playerId=id
        playerData._lv=v["lv"]
        playerData._nick=v["nick"]
        playerData._fashionID=v["fashionID"]
        playerData._num=v["num"]
        playerData._power = v["power"]
        playerData._format = v["format"]
        playerData._hero = v["hero"] --[{"id":1001,"star":1,"lv":1}]

        table.insert(_fragpvp,playerData)
    end
end

--查找玩家信息
function findUserInEnemy(uid)
    local enemy = _enemy
    for i=1, #enemy do
        if enemy[i]._playerId == uid then
            return enemy[i]
        end
    end
    
    return nil
end

--查找玩家信息
function findUserInFragpvp(uid)
    local fragpvp = _fragpvp
    for i=1, #fragpvp do
        if fragpvp[i]._playerId == uid then
            return fragpvp[i]
        end
    end

    return nil
end



