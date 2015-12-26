
--[[
    装备
]]


local t_lv=require("src/config/t_lv")
local t_equip=require("src/config/t_equip")
local t_item=require("src/config/t_item")

local EquipProperty={
    _uniqueID=0,        --装备唯一ID
    _itemID=0,          --物品ID
    _quality=1,         --装备品质
    _type=1,            --装备类型
    _attributeIDs={},   --属性
}

local Equipment=class("Equipment",EquipProperty)


function Equipment:ctor(data)
    self._uniqueID=data.uniqueID
    self._itemID=data.itemID
    self._attributeIDs[1]=data.attrID1
    self._attributeIDs[2]=data.attrID2
    self._attributeIDs[3]=data.attrID3
    self._attributeIDs[4]=data.attrID4
    
    local itemConfig=t_item[tonumber(data.itemID)]
    self._quality=itemConfig.grade
    self._type=itemConfig.type
    
end

--获得装备四个属性的配置
function Equipment:getAttrConfigs()
    local result={}
    for i,attrID in pairs(self._attributeIDs) do

        local attr=t_equip[attrID]
        table.insert(result,attr)

    end
    return result
end

--获得装备品质所需的背景图
function Equipment:getQualityBg(quality)
    return quality+9
end
--获得装备四个属性所需的背景图
function Equipment:getAttBg(grade)
    return grade+10
end
--获得装备强化石图标
function Equipment:getEquipStone(type)
    return type+3096
end


--获取战斗力
function Equipment:getFC()

    return 0
end

--获取战斗力加成
function Equipment:getFCAddition()

    return 0
end

--获取装备各属性值
function Equipment:getAttrValue(level)

    local growRatio=t_lv[level or 1].equip_up_grow     --成长率    
    local result={
        atk=0,
        hp=0,
        defWater=0,
        defFire=0,
        defWood=0
    }

    for _,attrID in pairs(self._attributeIDs) do  
        local attr=t_equip[attrID]
        
        result.atk=result.atk+attr.atk*growRatio   
        result.hp=result.hp+attr.hp*growRatio        
        result.defWater=result.defWater+attr.def_water*growRatio      
        result.defFire=result.defFire+attr.def_fire*growRatio     
        result.defWood=result.defWood+attr.def_wood*growRatio       
    end
    
    result.atk=math.ceil(result.atk)
    result.hp=math.ceil(result.hp)
    result.defWater=math.ceil(result.defWater)
    result.defFire=math.ceil(result.defFire)
    result.defWood=math.ceil(result.defWood)
    
    return result
end

--获取装备下个等级额外提升各属性值
function Equipment:getDifAttr(level)
    local result={
        atk=0,
        hp=0,
        defWater=0,
        defFire=0,
        defWood=0
    }
    local resultCur=self:getAttrValue(level)
    if level+1<=Const.MAX_LEVEL then
        local resultNext=self:getAttrValue(level+1)
        result.atk=resultNext.atk-resultCur.atk
        result.hp=resultNext.hp-resultCur.hp
        result.defWater=resultNext.defWater-resultCur.defWater
        result.defFire=resultNext.defFire-resultCur.defFire
        result.defWood=resultNext.defWood-resultCur.defWood
    end
    
    result.atk=math.ceil(result.atk)
    result.hp=math.ceil(result.hp)
    result.defWater=math.ceil(result.defWater)
    result.defFire=math.ceil(result.defFire)
    result.defWood=math.ceil(result.defWood)
    return result
end

--获取装备当前各属性的总值（加上附魔）
function Equipment:getAttrLastValue(equipFold)

    local result={
        atk=0,
        hp=0,
        defWater=0,
        defFire=0,
        defWood=0
    }
    local resultCur=self:getAttrValue(equipFold._level)
    local attrAddition=Hero.getAttrValueAddition(equipFold)
    
    result.atk=math.ceil(resultCur.atk+attrAddition.atk)
    result.hp=math.ceil(resultCur.hp+attrAddition.hp)
    result.defWater=math.ceil(resultCur.defWater+attrAddition.defWater)
    result.defFire=math.ceil(resultCur.defFire+attrAddition.defFire)
    result.defWood=math.ceil(resultCur.defWood+attrAddition.defWood)
    return result
end





return Equipment