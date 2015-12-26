
local StrategyHelp={}

local lvgrow_config=require("config/t_lv")                  --等级成长表
local stargrow_config=require("config/t_xlv")               --星级成长表
local t_skill=require("config/t_skill")                     --技能表
local t_strategy=require("config/t_skill_strategy")         --策略表
local t_skill_value=require("config/t_skill_value")
local t_skill_buff=require("config/t_skill_buff")
local t_skill_condition=require("config/t_skill_condition")
local t_skill_ball=require("config/t_skill_ball")
local t_parameter=require("config/t_parameter")             --公共配置表
---------------------------
--@param
--@return
function StrategyHelp:canFireSkill(skillType,step)

    local unlockLevel={
        [Const.SKILL_TYPE_ANGER]=1,
        [Const.SKILL_TYPE_NORMAL]=1,
        [Const.SKILL_TYPE_STAR_3]=3,
        [Const.SKILL_TYPE_STAR_5]=5,
        [Const.SKILL_TYPE_STAR_7]=7
    }
    local skillLevel=self._skills[skillType][2]
    local skillId=self._skills[skillType][1]
    --技能等级小于1级，为未解锁
    if skillId==0 or skillLevel<=0 then
        print("技能未解锁")
        return false
    end
    local skillConf=t_skill[skillId]
    print(skillId)
    local stra=t_strategy[skillConf.strategy]
    --判断被动技能
    if skillType==Const.SKILL_TYPE_STAR_7 then
        if skillConf.type==5 then
            if not self._isBorn then
                return false
            end
        elseif skillConf.type==6 then

        elseif skillConf.type==7 then

        elseif skillConf.type==8 then
            return false
        end

    end
    --如果技能CD未到
    if self._skillType~=Const.SKILL_TYPE_ANGER then
        if self._skillCD[skillType]<stra.cd then
            return false
        end
    end
    local condition=stra["condition_"..tostring(step)]
    local val=stra["val_"..tostring(step)]
    local var=stra["var_"..tostring(step)]

    if condition==0 then
        return false
    elseif condition==1 then
        local prob=(val+var*skillLevel)
        return commonUtil.isProbHappen(prob)
    elseif condition==2 then
        return self._battleScene:getBallAmount(Const.HERO_ELEMENT_FIRE)>=val
    elseif condition==3 then
        return self._battleScene:getBallAmount(Const.HERO_ELEMENT_WATER)>=val
    elseif condition==4 then
        return self._battleScene:getBallAmount(Const.HERO_ELEMENT_WOOD)>=val
    elseif condition==5 then
        local val=(val+var*skillLevel)/Const.DENOMINATOR
        return self:hpRatio()<val
    elseif condition==6 then
        local val=(val+var*skillLevel)/Const.DENOMINATOR
        return self:getTarget():hpRatio()<val
    elseif condition==7 then
        return false
    elseif condition==8 then
        return false
    elseif condition==9 then
        return false
    end

    local skill_condition=t_skill_condition[condition]
    local s_ids=commonUtil.split(skill_condition.buff_id,",")
    local ids={}
    for _,sid in pairs(s_ids) do
        table.insert(ids,tonumber(sid))
    end
    return BattleBuffMgr.has_buffs(skill_condition.cond,ids)

end

function StrategyHelp:strategyFunc(strategy,skillValue,skillLevel,step)
    local val=0
    local den=Const.DENOMINATOR
    local hp=self:getHp()
    local maxHp=self:getMaxHp()
    local atk=self:getAtk()
    local s_step=tostring(step)
    local stra=strategy["strategy_"..s_step]
    local cond=strategy["cond_"..s_step]
    local t_condition=strategy["t_condition_"..s_step]
    local t_val=strategy["t_val_"..s_step]
    local s_val1=strategy["s_val1_"..s_step]
    local s_var1=strategy["s_var1_"..s_step]
    local s_val2=strategy["s_val2_"..s_step]
    local s_var2=strategy["s_var2_"..s_step]

    local value_type=skillValue["value_type"..s_step]
    local combo_num=skillValue["combo_num"..s_step]
    local combo_delay=skillValue["combo_delay"..s_step]

    local caster="我方"
    if self:isEnemy() then
        caster="敌方"
    end
    local target_n="我方"
    local target=self
    local buff_side=1
    if cond==1 then
        buff_side=3
        target=self._battleScene
        target_n="场景"
    elseif cond==2 then
        buff_side=1
        target=self
        if self._skillType==Const.SKILL_TYPE_ANGER then
            if self:isOur() then
                target=self._battleScene:getOurHero()
            else
                target=self._battleScene:getEnemyHero()
            end
        end
    elseif cond==3 then
        buff_side=2
        target=self:getTarget()
        target_n="敌方"
    end

    if t_condition>0 then

    else
        t_val=1
    end

    print(caster,self._name,"攻击",target_n)

    --获取珠子加成
    local function getBallAddition(id)
        local res=1
        if self._skillType==Const.SKILL_TYPE_ANGER then
            res=t_skill_ball[id]["ball"..tostring(self._battleScene:getBallAmount(self._elementType))]
        end
        return res
    end

    if stra==2 then
        --是否命中
        if self._skillType==Const.SKILL_TYPE_ANGER or commonUtil.isProbHappen(self._hitRate-target:getDodgeRate()) then
            --是否暴击
            local crit=0
            if commonUtil.isProbHappen(self:getCritRate()-target._critrdRate) then
                crit=self:getCrit()/den
            end
            val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
            val=val+val*crit
            --
            val=val-val*target:getDefReduce(self._elementType)
            val=val*getBallAddition(1002)
            target:hpDown(val,true)
            if crit>0 then
                value_type=5
            end
            self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
        else
            self:showTextEffect(target,"common/miss.png")
        end

    elseif stra==3 then
        --是否命中
        if self._skillType==Const.SKILL_TYPE_ANGER or commonUtil.isProbHappen(self._hitRate-target:getDodgeRate()) then
            --是否暴击
            local crit=0
            if commonUtil.isProbHappen(self:getCritRate()-target._critrdRate) then
                crit=self:getCrit()/den
            end
            val=t_val*(s_val1+s_var1*skillLevel)/den*hp
            val=val+val*crit
            val=val-val*target:getDefReduce(self._elementType)
            val=val*getBallAddition(1002)
            target:hpDown(val,true)
            if crit>0 then
                value_type=5
            end
            self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
        else
            self:showTextEffect(target,"common/miss.png")
        end    
    elseif stra==4 then
        --是否命中
        if self._skillType==Const.SKILL_TYPE_ANGER or commonUtil.isProbHappen(self._hitRate-target:getDodgeRate()) then
            --是否暴击
            local crit=0
            if commonUtil.isProbHappen(self:getCritRate()-target._critrdRate) then
                crit=self:getCrit()/den
            end
            val=t_val*(s_val1+s_var1*skillLevel)/den*maxHp
            val=val+val*crit
            val=val-val*target:getDefReduce(self._elementType)
            val=val*getBallAddition(1002)
            target:hpDown(val,true)
            if crit>0 then
                value_type=5
            end
            self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
        else
            self:showTextEffect(target,"common/miss.png")
        end    
    elseif stra==5 then
        if BattleBuffMgr.has_no_recover_buff(target) then
            val=0
        else        
            val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
            val=val+val*self:getCure()/den
            val=val*getBallAddition(1002)
            target:hpUp(val)
        end
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)

    elseif stra==6 then
        if BattleBuffMgr.has_no_recover_buff(target) then
            val=0
        else
            val=t_val*(s_val1+s_var1*skillLevel)/den*hp
            val=val+val*self:getCure()/den
            val=val*getBallAddition(1002)
            target:hpUp(val)
        end
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)

    elseif stra==7 then
        if BattleBuffMgr.has_no_recover_buff(target) then
            val=0
        else
            val=t_val*(s_val1+s_var1*skillLevel)/den*maxHp
            val=val+val*self:getCure()/den
            val=val*getBallAddition(1002)
            target:hpUp(val)
        end
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)

    elseif stra==8 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:atkUp(val)
        self:showTextEffect(target,"common/atk_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)

    elseif stra==9 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWater(target:getDefWater()+val)
        self:showTextEffect(target,"common/water_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==10 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefFire(target:getDefFire()+val)
        self:showTextEffect(target,"common/fire_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==11 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWood(target:getDefWood()+val)
        self:showTextEffect(target,"common/wood_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==12 then
        val=t_val*(s_val1+s_var1*skillLevel)/den*hp
        val=val*getBallAddition(1002)
        target:atkUp(val)
        self:showTextEffect(target,"common/atk_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==13 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:atkDown(val)
        self:showTextEffect(target,"common/atk_down.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
    elseif stra==14 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWater(target:getDefWater()-val)
        self:showTextEffect(target,"common/water_down.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
    elseif stra==15 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefFire(target:getDefFire()-val)
        self:showTextEffect(target,"common/fire_down.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)    
    elseif stra==16 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWood(target:getDefWood()-val)
        self:showTextEffect(target,"common/wood_down.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
    elseif stra==17 then
        val=t_val*(s_val1+s_var1*skillLevel)/den*atk
        val=val*getBallAddition(1002)
        target:atkDown(val)
        self:showTextEffect(target,"common/atk_down.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)
    elseif stra==18 then
        if s_val1 > 0 then
            BattleBuffMgr.add_buff(s_val1,self,target,t_val*s_var1)
        end
        if s_val2 > 0 then
            BattleBuffMgr.add_buff(s_val2,self,target,t_val*s_var2)
        end
    elseif stra==19 then
        self._battleScene:generateBall(Const.HERO_ELEMENT_WATER)
    elseif stra==20 then
        self._battleScene:generateBall(Const.HERO_ELEMENT_FIRE)
    elseif stra==21 then
        self._battleScene:generateBall(Const.HERO_ELEMENT_WOOD)
    elseif stra==22 then
        local val=t_val*(self._straHurt1 or 1)
        val=val*getBallAddition(1002)
        target:hpUp(val)
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==23 then
--        local buff=self:getBuff_cateId(1023)
--        if buff~=nil then
--            local multi=buff:getValue()-1
--            self:setAtk(self:getAtk()*multi)
--        end
    elseif stra==24 then
        if s_val1 > 0 then
            BattleBuffMgr.delete_buff(BattleBuffMgr.get_buff(buff_side,s_val1))
        end
        if s_var1 > 0 then
            BattleBuffMgr.delete_buff(BattleBuffMgr.get_buff(buff_side,s_var1))
        end
        if s_val2 > 0 then
            BattleBuffMgr.delete_buff(BattleBuffMgr.get_buff(buff_side,s_val2))
        end
        if s_var2 > 0 then
            BattleBuffMgr.delete_buff(BattleBuffMgr.get_buff(buff_side,s_var2))
        end
    elseif stra==25 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWater(target:getDefWater()+val)
        target:setDefWater(target:getDefFire()+val)
        target:setDefWater(target:getDefWood()+val)
        --self:showTextEffect(target,"common/water_up.png")
        self:showValueEffect(target,val,value_type,combo_num,combo_delay)
    elseif stra==26 then
        val=t_val*(s_val1+s_var1*skillLevel+atk*s_val2/den+atk*s_var2/den)
        val=val*getBallAddition(1002)
        target:setDefWater(target:getDefWater()-val)
        target:setDefWater(target:getDefFire()-val)
        target:setDefWater(target:getDefWood()-val)
        --self:showTextEffect(target,"common/water_up.png")
        self:showValueEffect(target,-val,value_type,combo_num,combo_delay)

    elseif stra==27 then
        self._battleScene:wheelBall(1,2,s_val1)
    elseif stra==28 then
        self._battleScene:wheelBall(1,3,s_val1)
    elseif stra==29 then
        self._battleScene:wheelBall(2,1,s_val1)
    elseif stra==30 then
        self._battleScene:wheelBall(2,3,s_val1)
    elseif stra==31 then
        self._battleScene:wheelBall(3,1,s_val1)
    elseif stra==32 then
        self._battleScene:wheelBall(3,2,s_val1)
    elseif stra==33 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._critRate=self._critRate+val
    elseif stra==34 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._crit=self._crit+val
    elseif stra==35 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._cure=self._cure+val
    elseif stra==36 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._critRate=self._critRate-val
    elseif stra==37 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._crit=self._crit-val
    elseif stra==38 then
        val=t_val*(s_val1+s_var1*skillLevel)/den
        self._cure=self._cure-val
    end

    self._straHurt1=val
end

return StrategyHelp