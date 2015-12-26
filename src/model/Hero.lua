module("Hero", package.seeall)

local t_hero = require('src/config/t_hero')
local t_item =require('src/config/t_item')
local t_lv =require('src/config/t_lv')
local t_xlv =require('src/config/t_xlv')
local t_talent =require('src/config/t_talent')
local t_skill =require('src/config/t_skill')
local t_skill_formula =require('src/config/t_skill_formula')
local t_skill_strategy =require('src/config/t_skill_strategy')
local t_endow =require('src/config/t_endow')
local t_hero_equip =require('src/config/t_hero_equip')

local HeroProperty = {
    _heroID = 0,    --配置编号 
    _star   = 0,    --星级
    _lv     = 0,    --等级
    _exp    = 0,    --当前经验
    _lvTmp  = 0,    
    _expTmp = 0,
    _time   = 0,    --上次更新时间
    _attr   = 0,    --属性(水,火,木)(配置读取)
    _armsLv = 0,    --武器品质等级
    _skill1 = 0,    --怒攻技能等级
    _skill3 = 0,    --三星技等级
    _skill5 = 0,    --五星技等级
    _skill7 = 0,     --七星技等级
    _curEquip = {},  --当前装备栏情况存放装备Id,0表示没装备
    _pos    = 0     --英雄训练位置
}

local AbilityProperty = {
    atk = 0,    --攻击力
    hp = 0,     --生命值
    water = 0,  --水防御
    fire = 0,   --火防御
    wood = 0,   --木防御
    critRate = 0,  --暴击率
    critrdRate = 0,  --暴击减免率
    dodgeRate = 0,  --闪避率
    hitRate = 0,  --命中率
    crit = 0,   --暴击加成
    cure = 0     --治疗加成
}

local _heroList = {}    --英雄列表
local _format = {}      --阵型
local _unheroList = {}      --未招募英雄key列表
local _pos = {}  --英雄训练位置

local removeHeroByID = function(heroID)
    for i=1, #_heroList do
        if _heroList[i]._heroID == heroID then
            table.remove(_heroList, i)
            break
        end
    end
end

local addHero = function(id, v)
    --先移除同编号英雄
    id = tonumber(id)    
    removeHeroByID(id)
        
    local hero = clone(HeroProperty)
    hero._heroID = id

    hero._star = v["star"]
    hero._lv = v["lv"]
    hero._lvTmp = v["lv"]
    hero._exp = v["exp"]
    hero._expTmp = v["exp"]
    hero._attr = t_hero[hero._heroID]['type']
    hero._armsLv = v["elv"]
    hero._curEquip=v["equip"]
    hero._pos = v["pos"]
    hero._time = v["time"]
    
    local skill = v["skill"]
    
    hero._skill1 =  skill[1]
    hero._skill3 = skill[2]
    hero._skill5 = skill[3]
    hero._skill7 = skill[4]

    table.insert(_heroList, hero)
end

local clearHeroList = function()
    _heroList = {}
end
local clearUnHeroList = function()
    _unheroList = {}
end
local clearFormat = function()
    _format = {}
end

function getHeroList()
    -- return clone(_heroList)
    return _heroList
end
--获取已招募英雄个数
function getHeroNum()
    return #_heroList
end

--获取英雄当前总战斗力
function getHeroPower(heroID)
    return 1000
end

function getHeroAbility(heroID)
    local hero = getHeroByHeroID(heroID)
    
    local baseAtk = t_hero[heroID]["atk"]
    local baseHP = t_hero[heroID]["hp"]
    
    --初始值
    local ability = clone(AbilityProperty)
    ability.atk = baseAtk
    ability.hp = baseHP
    ability.hitRate = Const.DENOMINATOR
    ability.crit = Const.DENOMINATOR
    ability.cure = Const.DENOMINATOR  

    local lvAtk = t_lv[hero._lv]["hero_up_atk"]/Const.DENOMINATOR
    local lvHp = t_lv[hero._lv]["hero_up_hp"]/Const.DENOMINATOR

    local starAtk = t_xlv[hero._star]["hero_skill_atk"]/Const.DENOMINATOR
    local starHp = t_xlv[hero._star]["hero_skill_hp"]/Const.DENOMINATOR
    
    --基础*(1+等级加成)*(1+星级加成) 
    ability.atk = math.ceil(baseAtk * (1+lvAtk) * (1+starAtk))
    ability.hp = math.ceil(baseHP * (1+lvHp) * (1+starHp))
    
    --羁绊加成
    for i=1, 4 do
        local loveID = t_hero[heroID]["love"..i]
        local tHero = getHeroByHeroID(loveID)
        if tHero then
            local tid = t_hero[heroID]["talent"..i]
            
            local t_atk = tonumber(t_talent[tid]["atk"]) or 0
            local t_hp = tonumber(t_talent[tid]["hp"]) or 0
            local t_water = tonumber(t_talent[tid]["def_water"]) or 0
            local t_fire = tonumber(t_talent[tid]["def_fire"]) or 0
            local t_wood = tonumber(t_talent[tid]["def_wood"]) or 0
            
            local t_critp = tonumber(t_talent[tid]["crit_rate"]) or 0
            local t_critrdp = tonumber(t_talent[tid]["critrd_rate"]) or 0
            local t_dodge = tonumber(t_talent[tid]["dodge_rate"]) or 0
            local t_hitp = tonumber(t_talent[tid]["hit_rate"]) or 0
            local t_crit = tonumber(t_talent[tid]["crit"]) or 0
            local t_cure = tonumber(t_talent[tid]["cure"]) or 0
            
            local plus = 0
            for j=2, tHero._star do
                plus = plus + (tonumber(t_talent[tid]["var"..(j-1)]) or 0)
            end
            
            if plus > 0 then
                plus = 1 + plus/Const.DENOMINATOR
                
                if t_atk > 0 then t_atk = math.ceil(plus * t_atk) end
                if t_hp > 0 then t_hp = math.ceil(plus * t_hp) end
                if t_water > 0 then t_water = math.ceil(plus * t_water) end
                if t_fire > 0 then t_fire = math.ceil(plus * t_fire) end
                if t_wood > 0 then t_wood = math.ceil(plus * t_wood) end
                
                if t_critp > 0 then t_critp = math.ceil(plus * t_critp) end
                if t_critrdp > 0 then t_critrdp = math.ceil(plus * t_critrdp) end
                if t_dodge > 0 then t_dodge = math.ceil(plus * t_dodge) end
                if t_hitp > 0 then t_hitp = math.ceil(plus * t_hitp) end 
                if t_crit > 0 then t_crit = math.ceil(plus * t_crit) end
                if t_cure > 0 then t_cure = math.ceil(plus * t_cure) end
            end
            
            ability.atk = ability.atk + t_atk
            ability.hp = ability.hp + t_hp
            ability.water = ability.water + t_water
            ability.fire = ability.fire + t_fire
            ability.wood = ability.wood + t_wood
                        
            ability.critRate = ability.critRate + t_critp
            ability.critrdRate = ability.critrdRate + t_critrdp
            ability.dodgeRate = ability.dodgeRate + t_dodge
            ability.hitRate = ability.hitRate + t_hitp
            ability.crit = ability.crit + t_crit
            ability.cure = ability.cure + t_cure
        end
    end
    
    --装备加成
    for i=1, hero._armsLv do            --武器前面几级的所有装备 
        local equips = t_hero[heroID]["equip"..(i-1)]
        for j=1, #equips do
            local equipId=equips[j]
            
            local t_atk = tonumber(t_hero_equip[equipId]["atk"]) or 0
            local t_hp = tonumber(t_hero_equip[equipId]["hp"]) or 0
            local t_water = tonumber(t_hero_equip[equipId]["def_water"]) or 0
            local t_fire = tonumber(t_hero_equip[equipId]["def_fire"]) or 0
            local t_wood = tonumber(t_hero_equip[equipId]["def_wood"]) or 0
            
            local t_critp = tonumber(t_hero_equip[equipId]["crit_rate"]) or 0
            local t_critrdp = tonumber(t_hero_equip[equipId]["critrd_rate"]) or 0
            local t_dodge = tonumber(t_hero_equip[equipId]["dodge_rate"]) or 0
            local t_hitp = tonumber(t_hero_equip[equipId]["hit_rate"]) or 0
            local t_crit = tonumber(t_hero_equip[equipId]["crit"]) or 0
            local t_cure = tonumber(t_hero_equip[equipId]["cure"]) or 0
            
            ability.atk = ability.atk + t_atk
            ability.hp = ability.hp + t_hp
            ability.water = ability.water + t_water
            ability.fire = ability.fire + t_fire
            ability.wood = ability.wood + t_wood

            ability.critRate = ability.critRate + t_critp
            ability.critrdRate = ability.critrdRate + t_critrdp
            ability.dodgeRate = ability.dodgeRate + t_dodge
            ability.hitRate = ability.hitRate + t_hitp
            ability.crit = ability.crit + t_crit
            ability.cure = ability.cure + t_cure
        end
    end
    
    for k=1, #hero._curEquip do                           --当前装备栏的装备
        local equipId = hero._curEquip[k]
        if equipId > 0 then
            local t_atk = tonumber(t_hero_equip[equipId]["atk"]) or 0
            local t_hp = tonumber(t_hero_equip[equipId]["hp"]) or 0
            local t_water = tonumber(t_hero_equip[equipId]["def_water"]) or 0
            local t_fire = tonumber(t_hero_equip[equipId]["def_fire"]) or 0
            local t_wood = tonumber(t_hero_equip[equipId]["def_wood"]) or 0
            
            local t_critp = tonumber(t_hero_equip[equipId]["crit_rate"]) or 0
            local t_critrdp = tonumber(t_hero_equip[equipId]["critrd_rate"]) or 0
            local t_dodge = tonumber(t_hero_equip[equipId]["dodge_rate"]) or 0
            local t_hitp = tonumber(t_hero_equip[equipId]["hit_rate"]) or 0
            local t_crit = tonumber(t_hero_equip[equipId]["crit"]) or 0
            local t_cure = tonumber(t_hero_equip[equipId]["cure"]) or 0
            
            ability.atk = ability.atk + t_atk
            ability.hp = ability.hp + t_hp
            ability.water = ability.water + t_water
            ability.fire = ability.fire + t_fire
            ability.wood = ability.wood + t_wood

            ability.critRate = ability.critRate + t_critp
            ability.critrdRate = ability.critrdRate + t_critrdp
            ability.dodgeRate = ability.dodgeRate + t_dodge
            ability.hitRate = ability.hitRate + t_hitp
            ability.crit = ability.crit + t_crit
            ability.cure = ability.cure + t_cure
        end
    end

    return ability
end

--获取英雄上个武器等级时英雄的所有属性值（只用于武器炼化完的弹窗描述）
function getHeroLastArmLvAbility(heroID)
    local heroInList=getHeroByHeroID(heroID)
    heroInList._armsLv=heroInList._armsLv-1
    local lastAbility=getHeroAbility(heroID)
    heroInList._armsLv=heroInList._armsLv+1
    return lastAbility
end

--获取英雄未进阶时的属性值
function getHeroLastStarAbility(heroID)
    local heroInList=getHeroByHeroID(heroID)
    heroInList._star=heroInList._star-1
    local lastAbility=getHeroAbility(heroID)
    heroInList._star=heroInList._star+1
    return lastAbility
end

 
--通过技能ID找到对应d1,d2,d3的值并保存
function getSkillDescAllDValue(skillId,isDesc2)
    local skillFormulaIds={}
    if t_skill[skillId] then
        if isDesc2 then
            if t_skill[skillId]["d3"]~="" then
                table.insert(skillFormulaIds,t_skill[skillId]["d3"])
            end
            if t_skill[skillId]["d4"]~="" then
                table.insert(skillFormulaIds,t_skill[skillId]["d4"])
            end
        else
            if t_skill[skillId]["d1"]~="" then
                table.insert(skillFormulaIds,t_skill[skillId]["d1"])
            end
            if t_skill[skillId]["d2"]~="" then
                table.insert(skillFormulaIds,t_skill[skillId]["d2"])
            end
        end
    end
    return skillFormulaIds
end 
--通过技能描述d对应的ID计算描述所需的值
function getSkillDescValue(skillFormulaId,skillId,skillLv)
    local result=0
    local parameters={}
    if t_skill_formula[skillFormulaId] then
        --参数a
        local val_a = t_skill_formula[skillFormulaId]["a"]
        if val_a=="skill_lv" then
            table.insert(parameters,skillLv)
        elseif #val_a > 0 then
            table.insert(parameters,t_skill_strategy[skillId][val_a])
        end

        --参数b   
        local val_b = t_skill_formula[skillFormulaId]["b"]
        if val_b=="skill_lv" then
            table.insert(parameters,skillLv)
        elseif #val_b > 0 then
            table.insert(parameters,t_skill_strategy[skillId][val_b])
        end

        --参数c
        local val_c = t_skill_formula[skillFormulaId]["c"]
        if val_c=="skill_lv" then
            table.insert(parameters,skillLv)
        elseif #val_c > 0 then
            table.insert(parameters,t_skill_strategy[skillId][val_c])
        end

        --计算函数
        local skill_formula = t_skill_formula[skillFormulaId]["skill_formula"]    
        local f = loadstring(skill_formula)()    
        result = f(parameters[1], parameters[2], parameters[3])
    end
    return result
end
--获得描述最后的所有值，一个描述最多两个  %d
function getSkillDescAllValue(skillId,skillLv,isDesc2)
    local values={}
    local skillFormulaIds=getSkillDescAllDValue(skillId,isDesc2)
    
    local result1=getSkillDescValue(skillFormulaIds[1],skillId,skillLv)
    table.insert(values,result1)
    local result2=getSkillDescValue(skillFormulaIds[2],skillId,skillLv)
    table.insert(values,result2)

    return values
end
--技能描述富文本
function getSkillRich(desc,values)
    local richText=ccui.RichText:create()
    local result=commonUtil.split(desc,"d")
    local pos1,pos2=string.find(result[1],"%d+%%") --概率在d前面
    if pos1 then
        local s1=string.sub(result[1],1,pos1-1)
        local r1=ccui.RichElementText:create(1,cc.c3b(123,58,35),255,s1,"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r1)
        local s2=string.sub(result[1],pos1,pos2)
        local r2=ccui.RichElementText:create(2,cc.c3b(0,200,0),255,s2,"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r2)
        local s3=string.sub(result[1],pos2+1,string.len(result[1]))
        local r3=ccui.RichElementText:create(3,cc.c3b(123,58,35),255,s3,"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r3)
    else
        local r1=ccui.RichElementText:create(1,cc.c3b(123,58,35),255,result[1],"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r1)
    end
    
    for j=2, #result do
        local r1=ccui.RichElementText:create(2*j+10,cc.c3b(0,200,0),255,tostring( values[j-1] or "" ),"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r1)
        local r2=ccui.RichElementText:create(2*j-1+10,cc.c3b(123,58,35),255,result[j],"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r2)
    end 
    
    return richText
end
 
 
--获得羁绊技能属性的基础值,描述一和描述二用的基础值一样
function getTalentValue(talent)
    local value={}
    if nil~=talent then
        if talent.atk~="" then
            table.insert(value,talent.atk)
    	end
        if talent.hp~="" then
            table.insert(value,talent.hp)
        end
        if talent.def_water~="" then
            table.insert(value,talent.def_water)
        end
        if talent.def_fire~="" then
            table.insert(value,talent.def_fire)
        end
        if talent.def_wood~="" then
            table.insert(value,talent.def_wood)
        end      
        if talent.crit_rate~="" then
            table.insert(value,talent.crit_rate)
        end
        if talent.critrd_rate~="" then
            table.insert(value,talent.critrd_rate)
        end
        if talent.hit_rate~="" then
            table.insert(value,talent.hit_rate)
        end
        if talent.dodge_rate~="" then
            table.insert(value,talent.dodge_rate)
        end    
        if talent.crit~="" then
            table.insert(value,talent.crit)
        end
        if talent.cure~="" then
            table.insert(value,talent.cure)
        end  
    end
    return value
end
--羁绊技能描述富文本，rate为下级提升的百分比
function getTalentRich(desc,talent,rate)
    local value=getTalentValue(talent)
    for i, var in pairs(value) do
        value[i]=value[i]*rate
        value[i]=math.ceil(value[i])
    end
    
    --rich
    local result=commonUtil.split(desc,"d")
    local richText=ccui.RichText:create()
    for j=1, #result do
        local r1=ccui.RichElementText:create(2*j-1,cc.c3b(123,58,35),255,result[j],"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r1)
        local r2=ccui.RichElementText:create(2*j,cc.c3b(0,200,0),255,tostring( value[j] or "" ),"fonts/FZZhengHeiS-DB-GB.ttf",16)
        richText:pushBackElement(r2)
    end     
    return richText
end


function getUnHeroList()
    return _unheroList
end

--通过Key获得t_hero里的英雄
function getTHeroByKey(key)
    for k, v in pairs(t_hero) do
        if key==k then
            return v
        end
    end 
end

--按id获得已招募英雄
function getHeroByHeroID(heroID)
    for i=1, #_heroList do
        if _heroList[i]._heroID == heroID then
            return _heroList[i]
        end
    end    
    return nil
end

--按属性获得已招募英雄
function getHeroByAttr(attr)
    if attr == Const.HERO_ATTR_TYPE.NONE then
        return getHeroList()
    else
        local list = {}
        for i=1, #_heroList do
            if _heroList[i]._attr == attr then
                table.insert(list, _heroList[i])
            end
        end    
        return list
    end
end

--按武器品质等级获得已招募英雄
function getHeroByArmsLv(armsLv)
    local ret = {}
    for i=1, #_heroList do
        if _heroList[i]._armsLv >= armsLv then
            table.insert(ret, _heroList[i]._heroID)
        end
    end    
    return ret
end

--按属性获得未招募英雄
function getUnHeroByAttr(attr)
    if attr == Const.HERO_ATTR_TYPE.NONE then
        return getUnHeroList()
    else
        local list = {}
        for i=1, #_unheroList do
            if t_hero[_unheroList[i]].type == attr then
                table.insert(list, _unheroList[i])
            end
        end    
        return list
    end   
end


--获取英雄属性图标
function getAttrIcon(attr)
    local image_attr = ""
    if attr == Const.HERO_ATTR_TYPE.SHUI then
        image_attr = Const.HERO_ATTR_BALL_SHUI
    elseif attr == Const.HERO_ATTR_TYPE.HUO then
        image_attr = Const.HERO_ATTR_BALL_HUO
    elseif attr == Const.HERO_ATTR_TYPE.MU then
        image_attr = Const.HERO_ATTR_BALL_MU
    end
    return image_attr
end

function getHeroSoulStoneItemID(heroId)
    return heroId+1000
end

--
function getFormatByType(_type)
    return _format[_type]
end

--是否在阵中
function isAtFormat(_type, id)
    local format = _format[_type]
    for i=1, #format do
        if id == format[i] then
            return true
        end
    end    
    return false
end

--获取装备属性加成值用于描述
function getEquipAdd(equipId)
    local equip=t_hero_equip[equipId]
    local ability = clone(AbilityProperty)
    ability.atk=tonumber(equip.atk) or 0
    ability.hp =tonumber(equip.hp) or 0
    ability.water =tonumber(equip.def_water) or 0
    ability.fire=tonumber(equip.def_fire) or 0
    ability.wood =tonumber(equip.def_wood) or 0
    ability.critRate=tonumber(equip.crit_rate) or 0
    ability.critrdRate=tonumber(equip.critrd_rate) or 0
    ability.hitRate =tonumber(equip.hit_rate) or 0
    ability.dodgeRate=tonumber(equip.dodge_rate) or 0
    ability.crit =tonumber(equip.crit) or 0
    ability.cure =tonumber(equip.cure) or 0

    return ability
end

--获取装备属性加成描述（装备描述界面）
function getEquipDesc(ability)
    local desc={}
    if ability.atk > 0 then
        local values=string.format("+%d",ability.atk)
        table.insert(desc,"攻击力")
        table.insert(desc,values)  
    end
    if ability.hp > 0 then
        local values=string.format("+%d",ability.hp)
        table.insert(desc,"生命值")
        table.insert(desc,values)  
    end
    if ability.water > 0 then
        local values=string.format("+%d",ability.water)
        table.insert(desc,"水防御")
        table.insert(desc,values)  
    end
    if ability.fire> 0 then
        local values=string.format("+%d",ability.fire)
        table.insert(desc,"火防御")
        table.insert(desc,values)  
    end
    if ability.wood > 0 then
        local values=string.format("+%d",ability.wood)
        table.insert(desc,"木防御")
        table.insert(desc,values)  
    end
    if ability.critRate > 0 then
        local values=string.format("+%d%%",ability.critRate/100)
        table.insert(desc,"暴击率")
        table.insert(desc,values)  
    end
    if ability.critrdRate > 0 then
        local values=string.format("+%d%%",ability.critrdRate/100)
        table.insert(desc,"暴击减免")
        table.insert(desc,values)  
    end
    if ability.hitRate > 0 then
        local values=string.format("+%d%%",ability.hitRate/100)
        table.insert(desc,"命中率")
        table.insert(desc,values)  
    end
    if ability.dodgeRate > 0 then
        local values=string.format("+%d%%",ability.dodgeRate/100)
        table.insert(desc,"闪避率")
        table.insert(desc,values)  
    end
    if ability.crit > 0 then
        local values=string.format("+%d%%",ability.crit/100)
        table.insert(desc,"暴击加成")
        table.insert(desc,values)  
    end
    if ability.cure > 0 then
        local values=string.format("+%d%%",ability.cure/100)
        table.insert(desc,"治疗加成")
        table.insert(desc,values)  
    end
    return desc
end

--获取装备炼化完后加成描述
function getUpEquipDesc(heroInList)
    local curHeroAbility=getHeroAbility(heroInList._heroID)
    local lastHeroAbility=getHeroLastArmLvAbility(heroInList._heroID)
    local equipsId=t_hero[heroInList._heroID]["equip"..heroInList._armsLv-1]   --未炼化前的四件装备
    local ability=getArmsAdd(equipsId)
    local desc={}
    if ability.atk > 0 then
        table.insert(desc,"攻击力")
        table.insert(desc,lastHeroAbility.atk)
        table.insert(desc,curHeroAbility.atk)   
    end
    if ability.hp > 0 then
        table.insert(desc,"生命值")
        table.insert(desc,lastHeroAbility.hp)
        table.insert(desc,curHeroAbility.hp) 
    end
    if ability.water > 0 then
        table.insert(desc,"水防御")
        table.insert(desc,lastHeroAbility.water)
        table.insert(desc,curHeroAbility.water) 
    end
    if ability.fire> 0 then
        table.insert(desc,"火防御")
        table.insert(desc,lastHeroAbility.fire)
        table.insert(desc,curHeroAbility.fire)  
    end
    if ability.wood > 0 then
        table.insert(desc,"木防御")
        table.insert(desc,lastHeroAbility.wood)
        table.insert(desc,curHeroAbility.wood)  
    end
    if ability.critRate > 0 then
        local lable1=string.format("%d%%",lastHeroAbility.critRate/100)
        local lable2=string.format("%d%%",curHeroAbility.critRate/100)
        table.insert(desc,"暴击率")
        table.insert(desc,lable1)  
        table.insert(desc,lable2) 
    end
    if ability.critrdRate > 0 then
        local lable1=string.format("%d%%",lastHeroAbility.critrdRate/100)
        local lable2=string.format("%d%%",curHeroAbility.critrdRate/100)
        table.insert(desc,"暴击减免")
        table.insert(desc,lable1)  
        table.insert(desc,lable2) 
    end
    if ability.hitRate > 0 then
        local lable1=string.format("%d%%",lastHeroAbility.hitRate/100)
        local lable2=string.format("%d%%",curHeroAbility.hitRate/100)
        table.insert(desc,"命中率")
        table.insert(desc,lable1)  
        table.insert(desc,lable2) 
    end
    if ability.dodgeRate > 0 then
        local lable1=string.format("%d%%",lastHeroAbility.dodgeRate/100)
        local lable2=string.format("%d%%",curHeroAbility.dodgeRate/100)
        table.insert(desc,"闪避率")
        table.insert(desc,lable1)  
        table.insert(desc,lable2) 
    end
    if ability.crit > 0 then
        local lable1=string.format("%d%%",lastHeroAbility.crit/100)
        local lable2=string.format("%d%%",curHeroAbility.crit/100)
        table.insert(desc,"暴击加成")
        table.insert(desc,lable1)  
        table.insert(desc,lable2) 
    end
    if ability.cure > 0 then
        local lable1=string.format("%d%%",curHeroAbility.cure/100)
        local lable2=string.format("%d%%",curHeroAbility.cure/100)
        table.insert(desc,"治疗加成")
        table.insert(desc,lable1)  
        table.insert(desc,lable2)   
    end
    return desc
end

--武器该等级四件装备的属性和
function getArmsAdd(equipsId)
    local values=getEquipAdd(equipsId[1])
    for i=2, #equipsId do
        local ability=getEquipAdd(equipsId[i])
        
        values.atk = values.atk + ability.atk
        values.hp = values.hp + ability.hp
        values.water = values.water + ability.water
        values.fire = values.fire + ability.fire
        values.wood = values.wood + ability.wood

        values.critRate = values.critRate + ability.critRate
        values.critrdRate = values.critrdRate + ability.critrdRate
        values.dodgeRate = values.dodgeRate + ability.dodgeRate
        values.hitRate = values.hitRate + ability.hitRate
        values.crit = values.crit + ability.crit
        values.cure = values.cure + ability.cure
    end
    return values
end


--判断英雄是否是已经招募的
function isInHeroList(heroID)
    for i=1, #_heroList do
        if _heroList[i]._heroID == heroID then
            return true
        end
    end 
    return false   
end

function parseHero(msg)
    local sync = false
    if msg["_sync_"] then
        sync = true
    end
    
    if msg["heros"] then
        if not sync then
            clearHeroList()
        end        
        
        clearUnHeroList()
        
        local heros = msg["heros"]
        if heros then
            for i=1, #heros do
                addHero(heros[i]["id"], heros[i])
            end
            
            Timer.startHeroExpTimer()
        end
        
        --英雄排序
        sortHero()
        
        for k, v in pairs(t_hero) do
            if isInHeroList(k)==false then
                table.insert(_unheroList, k)
            end
        end
        
        sortUnHero()
        
        Event.notify(Const.EVENT.HEROS, nil)     --通知
    end
    
    local posInfo = msg["pos"]
    if posInfo then
        for i=1, #posInfo do
            local id = tonumber(posInfo[i]["id"])
            _pos[id] = posInfo[i]["lv"]
        end
    end
    
    if msg["format"] then
        if not sync then
            clearFormat()
        end

        for k, v in pairs(msg["format"]) do
            _format[tonumber(k)] = v
        end

        Event.notify(Const.EVENT.FORMAT, nil)
    end
        
    return true
end


--获取装备栏的属性值加成
--@param equipFoldType 装备栏类型
function getAttrValueAddition(equipFold)

    local result={
        atk=0,
        hp=0,
        defWater=0,
        defFire=0,
        defWood=0
    }

    local endow=equipFold._endow
    for i, var in pairs(endow) do
        if t_endow[var._id].type==Const.ENDOW_TYPE.ATK  then
            result.atk=result.atk+var._num
        elseif t_endow[var._id].type==Const.ENDOW_TYPE.HP  then
            result.hp=result.hp+var._num
        elseif t_endow[var._id].type==Const.ENDOW_TYPE.DEFWATER  then
            result.defWater=result.defWater+var._num
        elseif t_endow[var._id].type==Const.ENDOW_TYPE.DEFFIRE  then
            result.defFire=result.defFire+var._num
        elseif t_endow[var._id].type==Const.ENDOW_TYPE.DEFWOOD  then
            result.defWood=result.defWood+var._num
        end     
    end  

    return result
end

--英雄排序函数
function sortHeroList(a, b)
    if a._star == b._star then
        if a._lv == b._lv then
            if a._armsLv == b._armsLv then
                return a._heroID < b._heroID
            else
                return a._armsLv > b._armsLv
            end
        else
            return a._lv > b._lv
        end
    else
        return a._star > b._star  
    end
end

--英雄排序
function sortHero()
    table.sort(_heroList, sortHeroList)
end

--未招募英雄排序函数
function sortUnHeroList(heroID1, heroID2)
    local soulId1=getHeroSoulStoneItemID(heroID1)
    local soulStoneNum1=Item.getNum(soulId1)

    local soulId2=getHeroSoulStoneItemID(heroID2)
    local soulStoneNum2=Item.getNum(soulId2)

    if soulStoneNum1 == soulStoneNum2 then
        return heroID1 < heroID2
    else
        return soulStoneNum1 > soulStoneNum2
    end
end

--未招募英雄排序
function sortUnHero()
    table.sort(_unheroList, sortUnHeroList)
end

--获得英雄训练位置信息
function getHeroPos()
    return _pos --按位置排序下
end

--查询某位置是否有英雄在训练,有返回英雄ID，没有返回nil
function isHeroInPos(pos)
    for i=1, #_heroList do
        if _heroList[i]._pos == pos then
            return _heroList[i]._heroID
        end
    end
    
    return nil
end

