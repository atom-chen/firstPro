
module("BattleBuffMgr",package.seeall)

local t_skill_buff=require("config.t_skill_buff")
local t_parameter=require("config/t_parameter")
local BattleBuff=require("battle.buff.BattleBuff")

e_hero=1        --英雄身上的BUFF
e_scene=2       --场景上的BUFF
e_team=3        --全队上面的BUFF

local _buffs={}
_buffs[e_hero]={}
_buffs[e_team]={}
local _delete_buffs={}
local _no_move_ids={}
local _no_skill_ids={}
local _no_recover_ids={}

function init()
    _buffs[e_hero][1]={}
    _buffs[e_hero][2]={}
    _buffs[e_scene]={}
    _buffs[e_team][1]={}
    _buffs[e_team][2]={}
    _delete_buffs={}
    _no_move_ids={}
    _no_skill_ids={}
    _no_recover_ids={}
    
    local t=commonUtil.split(t_parameter.no_move.var,",")
    for _,sid in pairs(t) do
        table.insert(_no_move_ids,tonumber(sid))
    end
    
    t=commonUtil.split(t_parameter.no_skill.var,",")
    for _,sid in pairs(t) do
        table.insert(_no_skill_ids,tonumber(sid))
    end
    
    t=commonUtil.split(t_parameter.no_recover.var,",")
    for _,sid in pairs(t) do
        table.insert(_no_recover_ids,tonumber(sid))
    end
end

--给目标添加BUFF
--caster:释放者
--target:buff加到上面目标身上
function add_buff(id,caster,target,level)
    level=level or 1
    local config=t_skill_buff[id]
    local exist_type=config.exist_type
    local reject_type=config.reject_type
    local name="我方"
    if caster:isEnemy() then name="敌方" end
    local name2="我方"
    if target.isEnemy==nil then
        name2="场景"
    else
        if target:isEnemy() then name2="敌方" end
    end
    print(name,"给",name2,"添加BUFF:",id)
    local buffs=nil
    if exist_type==e_scene then
        buffs=_buffs[exist_type]
    else
        if target:isOur() then
            buffs=_buffs[exist_type][1]
        else
            buffs=_buffs[exist_type][2]
        end
    end
    --同ID升级
    for _,buff in ipairs(buffs) do
        if not buff._deleteFlag and buff._config.id==id then
            buff:onUpgrade(level)
            return
        end
    end
    --互斥
    for _,buff in ipairs(buffs) do
        if not buff._deleteFlag then
            local t_reject_type=buff._config.reject_type
            if t_reject_type==reject_type then
                if t_reject_type>=20 and buff._lv>level then
                    buff:onDegrade(level)
                else
                    level=level-buff._lv
                    delete_buff(buff)
                    if level>0 then
                        local t_buff=new_buff(id,caster,target,level)
                        table.insert(buffs,t_buff)
                        t_buff:onEnter()
                    end
                end
                return
            end
        end
    end
    local t_buff=new_buff(id,caster,target,level)
    table.insert(buffs,t_buff)
    t_buff:onEnter()
end

function new_buff(id,caster,target,level)
    local filename=string.format("battle/buff/%d.lua",id)
    local buff_class=BattleBuff
    if cc.FileUtils:getInstance():isFileExist(filename) then
	   buff_class=require(string.format("battle/buff/%d",id))
	end
    return buff_class.new(id,caster,target,level)
end

function get_buff(side,id)
    if side==3 then
        for _,buff in ipairs(_buffs[e_scene]) do
            if buff._config.id==id then
                return buff
            end
        end
        return nil
    end
    for _,buff in ipairs(_buffs[e_hero][side]) do
        if buff._config.id==id then
            return buff
        end
    end
    for _,buff in ipairs(_buffs[e_team][side]) do
        if buff._config.id==id then
            return buff
        end
    end
    return nil
end

function delete_buff(buff)
    if buff==nil then return end
    local config=buff._config
    local exist_type=config.exist_type
    local buffs=nil
    if exist_type==e_scene then
        buffs=_buffs[exist_type]
    else
        local side=2
        if buff._target:isOur() then side=1 end
        buffs=_buffs[exist_type][side]
    end
    for pos,t_buff in ipairs(buffs) do
        if buff==t_buff then
            buff:onExit()
            table.remove(buffs,pos)
            return
        end
    end
end

function execute_buffs(isOur)
    local delay=0
    local side=2
    if isOur then side=1 end
    for _,buff in ipairs(_buffs[e_hero][side]) do
        delay=delay+buff:execute()
    end
    for _,buff in ipairs(_buffs[e_scene]) do
        delay=delay+buff:execute(isOur)
    end
    for _,buff in ipairs(_buffs[e_team][side]) do
        delay=delay+buff:execute()
    end
    return delay
end

--每一轮调用一次这个函数
function schedule_per_round()
    for _,buff in ipairs(_buffs[e_hero][1]) do
        buff:schedulePerRound()
    end
    execute_delete()
    for _,buff in ipairs(_buffs[e_hero][2]) do
        buff:schedulePerRound()
    end
    execute_delete()
    for _,buff in ipairs(_buffs[e_scene]) do
        buff:schedulePerRound()
    end
    execute_delete()
    for _,buff in ipairs(_buffs[e_team][1]) do
        buff:schedulePerRound()
    end
    execute_delete()
    for _,buff in ipairs(_buffs[e_team][2]) do
        buff:schedulePerRound()
    end
    execute_delete()
end

function add_delete_buff(buff)
    table.insert(_delete_buffs,buff)
end

function execute_delete()
    for _,buff in ipairs(_delete_buffs) do
        delete_buff(buff)
    end
    _delete_buffs={}
end

function has_buffs(side,ids)
    if side==3 then
        for _,buff in ipairs(_buffs[e_scene]) do
            local t_id=buff._config.id
            for _,id in pairs(ids) do
                if t_id==id then
                    return true
                end
            end
        end
        return false
    end
    
    for _,buff in ipairs(_buffs[e_hero][side]) do
        local t_id=buff._config.id
        for _,id in pairs(ids) do
            if t_id==id then
                return true
            end
        end
    end
    
    for _,buff in ipairs(_buffs[e_team][side]) do
        local t_id=buff._config.id
        for _,id in pairs(ids) do
            if t_id==id then
                return true
            end
        end
    end
	return false
end

function clear_hero_buff(side)
    _buffs[e_hero][side]={}
end

function has_no_move_buff(hero)
    local side=2
    if hero:isOur() then side=1 end
    return has_buffs(side,_no_move_ids)
end

function has_no_skill_buff(hero)
    local side=2
    if hero:isOur() then side=1 end
    return has_buffs(side,_no_skill_ids)
end

function has_no_recover_buff(hero)
    local side=2
    if hero:isOur() then side=1 end
    return has_buffs(side,_no_recover_ids)
end

