
local t_skill=require("config/t_skill")                     --技能表
local t_strategy=require("config/t_skill_strategy")         --策略表
local t_skill_value=require("config/t_skill_value")

--英雄动画
local SStar3="s1"
local SStar5="s2"
local SAnger="s3"
local SBorn="s4"
local SIdle="s5"
local SAttack="s6"
local SInjury="s7"
local SVictory="s8"
local SDead="s9"

--战斗释放步骤，每一个步骤执行完，异步回调，执行下一个步骤
local Step=commonUtil.createEnum({
    "skill7",                   --被动技能
    "buff",                     --BUFF效果
    "skill3",                   --主动技能1
    "strike_back1",             --敌方反击
    "skill5",                   --主动技能2
    "strike_back2",             --敌方反击
    "skill1",                   --普通攻击
    "end_strike"                --结束攻击
})

local property={
    _img=0,                         --英雄CG图像ID
    _icon=0,                        --英雄头像ID
    _battleSide=0,                  --战斗方[我方，敌方]
    _pos=0,                         --英雄阵位
    _hp=0,                          --英雄血量
    _maxHp=0,                       --英雄血量最大值
    _atk=0,                         --攻击力
    _elementType=0,                 --英雄属性{水,火,木}
    _level=0,                       --英雄等级
    _starLevel=0,                   --英雄星级
    _angerPoint=0,                  --怒气点
    _skillCD=nil,                   --技能CD
    _angerSkillMaxCD=0,             --怒气技能CD最大值
    _randAP=0,                      --怒气点随机异或值
    _randHp=0,                      --血量随机异或值
    _randAtk=0,                     --攻击力随机异或值
    _state=SIdle,                   --英雄动画状态
    _anim=nil,                      --英雄动画
    _isBorn=false,
    _buffs={},                      --BUFF数组
    _skills={},                     --技能列表
    _def={},                        --属性防御,水，火，木
    _critRate = 0,                  --暴击率
    _critrdRate = 0,                --暴击减免率
    _dodgeRate = 0,                 --闪避率
    _hitRate = 0,                   --命中率
    _crit = 0,                      --暴击加成
    _cure = 0,                      --治疗加成
}


local BattleSoldier=require("battle/BattleSoldier")
local BattleHero = class("BattleHero",property)
local SkillHelp = require("battle/BattleSkillHelp")
local ValueHelp = require("battle/BattleValueHelp")
local StrategyHelp = require("battle/BattleStrategyHelp")

function BattleHero:ctor(battleScene,battleSide,pos,heroData)
    local widget=battleScene._uiLayer
    self._battleScene=battleScene
    self._pos=pos
    self._battleSide=battleSide
    self._skills={}
    self._def={}
    self._buffs={}
    self._skillCD={}
    for k,v in pairs(SkillHelp) do self[k] = v end
    for k,v in pairs(ValueHelp) do self[k] = v end
    for k,v in pairs(StrategyHelp) do self[k] = v end
    
    if self:isOur() then
        self._panel_soldier=self._battleScene._uiLayer.panel_soldier_our
        self._progHp=self._battleScene._uiLayer["prog_our_hp"]
        self._labelHp=self._battleScene._uiLayer["label_our_hp"]
        self._labelName=self._battleScene._uiLayer["label_our_name"]
        self._panelBuff=self._battleScene._uiLayer["panel_our_buff"]
        self._panelBuffFace=self._battleScene._uiLayer["panel_our_buff_face"]
    else
        self._panel_soldier=self._battleScene._uiLayer.panel_soldier_enemy
        self._progHp=self._battleScene._uiLayer["prog_enemy_hp"]
        self._labelHp=self._battleScene._uiLayer["label_enemy_hp"]
        self._labelName=self._battleScene._uiLayer["label_enemy_name"]
        self._panelBuff=self._battleScene._uiLayer["panel_enemy_buff"]
        self._panelBuffFace=self._battleScene._uiLayer["panel_enemy_buff_face"]
    end

    self:initData(heroData)
    self:initUI()
    self:setAngerPoint(0)
    local widget_name="panel_enemy_"..self._pos
    if self:isOur() then
        widget_name="panel_our_"..self._pos
    end

--    local locationNode=widget[widget_name]
--    local size=locationNode:getContentSize()
--    self._uiLayer:setPosition(size.width/2,size.height/2)
--    locationNode:addChild(self._uiLayer)

end

---------------------------
--初始化数据
--@return
function BattleHero:initData(data)
    self._name=data.name
    self._soldierId=data.soldierId
    self._img=data.img
    self._icon=data.icon
    self:setHp(data.hp)
    self:setAtk(data.atk)
    self._critRate=data.critRate
    self._critrdRate=data.critrdRate
    self._dodgeRate=data.dodgeRate
    self._hitRate=data.hitRate
    self._crit=data.crit
    self._cure=data.cure
    self._cate=data.cate
    self._elementType=data.elementType
    self._level=data.level
    self._starLevel=data.starLevel
    self._quality=data.quality
    self._skills[Const.SKILL_TYPE_NORMAL]=data.skillNormal
    self._skills[Const.SKILL_TYPE_ANGER]=data.skillAnger
    self._skills[Const.SKILL_TYPE_STAR_3]=data.skillStar3
    self._skills[Const.SKILL_TYPE_STAR_5]=data.skillStar5
    self._skills[Const.SKILL_TYPE_STAR_7]=data.skillStar7
    self._def[Const.HERO_ELEMENT_WATER]=data.water or 0
    self._def[Const.HERO_ELEMENT_FIRE]=data.fire or 0
    self._def[Const.HERO_ELEMENT_WOOD]=data.wood or 0
    self._skillCD[Const.SKILL_TYPE_NORMAL]=0
    self._skillCD[Const.SKILL_TYPE_STAR_3]=0
    self._skillCD[Const.SKILL_TYPE_STAR_5]=0
    self._skillCD[Const.SKILL_TYPE_STAR_7]=0
    self._skillCD[Const.SKILL_TYPE_ANGER]=0
    self._angerSkillMaxCD=99999
    local stra=t_strategy[self._skills[Const.SKILL_TYPE_ANGER][1]]
    if stra then
        self._angerSkillMaxCD=stra.cd
    end
end

---------------------------
--初始化UI
--@return
function BattleHero:initUI()
--    local widget_path="ui/BattleEnemy.csb"
--    if self:isOur() then
--        widget_path="ui/BattleOur.csb"
--    end
--    local widget=ccs.GUIReader:getInstance():widgetFromBinaryFile(widget_path)
--    widgetUtil.widgetReader(widget)
--    widget:setAnchorPoint(0.5,0.5)

--    --创建属性球
--    local sprElement=cc.Sprite:create(string.format("ui/common_ball%d.png",self._elementType))
--    if sprElement then
--        local size=widget.img_ball:getContentSize()
--        sprElement:setPosition(size.width/2+1,size.height/2-1)
--        widget.img_ball:addChild(sprElement)
--    end
--
--    if self:isOur() or not self._battleScene:isReplay() then
--        widget:addTouchEventListener(function(sender,eventType)
--            if eventType == ccui.TouchEventType.ended then
--                eventUtil.dispatchCustom(string.format("on_fire_anger_skill_%d_%d",self._battleSide,self._pos))
--            end
--        end)
--    end
    local widget=self._battleScene._uiLayer.panel_our_head
    self._deadImg=self._battleScene._uiLayer["img_our_dead_"..tostring(self._pos)]
    if self:isEnemy() then
        widget=self._battleScene._uiLayer.panel_enemy_head
        self._deadImg=self._battleScene._uiLayer["img_enemy_dead_"..tostring(self._pos)]
    end
    
    --创建头像
    local path=string.format("icon/%d.png",self._icon)
    local sprIcon=cc.Sprite:create(path)
    if sprIcon==nil then
        sprIcon=cc.Sprite:create("icon/99999.png")
    end
    widget:addChild(sprIcon,1,0x100)
--    local size=widget.img_icon:getContentSize()
    sprIcon:setPosition(self._deadImg:getPosition())
    sprIcon:setScale(0.5)
--    self._uiAnger=widget.image_angry
--    self._angerProg=widget.progress_angry
--    self._angerProg:setPercent(100)
    self._uiLayer=sprIcon
    self._uiLayer:addChild(require("battle/HeroController"):create(self))
end

---------------------------
--攻击
--@return
function BattleHero:strike(target)

    local side="我方"
    if self:isEnemy() then
        side="敌方"
    end
    print(side,"攻击")
    self._attacked=true
    self._hasFire3Star=false
    self._step=Step.skill1
    self:callWithDelay(0,function()
        self:onStrikeStep()
    end)

end

---------------------------
--战斗步骤回调
--@return
function BattleHero:onStrikeStep()

    --如果自己死亡
    if self:isDead() then
        self:callWithDelay(1,function()
            self._battleScene:onHeroDead(self:isOur())
        end)
        return
    end
    --如果目标死亡
    if self:getTarget():isDead() then
        self:callWithDelay(1,function()
            self._battleScene:onHeroDead(self:getTarget():isOur())
        end)
        return
    end
    self._panelBuffFace:setVisible(true)

    local step=self._step
    local delay=0
    if step==Step.skill7 then   --被动技能

        self._step=Step.buff
        local stype=self:getSkillType(Const.SKILL_TYPE_STAR_7)
        --如果被动技能是降临技能或者回合开始技能才判断被动技能是否释放
        if (stype==5 or stype==6) and self:canFire7StarAtk() then
            self:fire7StarAtk()
        else
            self:callWithDelay(delay,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.buff then --回合BUFF效果

        delay=BattleBuffMgr.execute_buffs(self:isOur())
        self._step=Step.skill3
        self:callWithDelay(delay,function()
            self:onStrikeStep()
        end)

    elseif step==Step.skill3 then --释放主动技能1

        self._step=Step.strike_back1
        if self:canFire3StarAtk() then
            self._hasFire3Star=true
            self:fire3StarAtk()
        else
            self._step=Step.skill5
            self:callWithDelay(0,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.strike_back1 then --反击1

        self._step=Step.skill5
        if self:getTarget():getSkillType(Const.SKILL_TYPE_STAR_7)==7
            and self:getTarget():canFire7StarAtk() then

            self:getTarget():fire7StarAtk()
        else
            self:callWithDelay(0,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.skill5 then --释放主动技能2

        self._step=Step.strike_back2
        if self:canFire5StarAtk() then
            self:fire5StarAtk()
        else
            self._step=Step.skill1
            self:callWithDelay(0,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.strike_back2 then --反击2

        self._step=Step.end_strike
        if self:getTarget():getSkillType(Const.SKILL_TYPE_STAR_7)==7
            and self:getTarget():canFire7StarAtk() then

            self:getTarget():fire7StarAtk()
        else
            self:callWithDelay(0,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.skill1 then --释放普通技能

        self._step=Step.end_strike
        if not self._hasFire3Star and self:canFireNormalAtk() then
            self:fireNormalAtk()
        else
            self:callWithDelay(0,function()
                self:onStrikeStep()
            end)
        end

    elseif step==Step.end_strike then --攻击结束

        self:callWithDelay(1,function()
            self._battleScene:nextBattle()
        end)

    end
    self._isBorn=false
end

function BattleHero:fireAngerAtk()
    local delay=0
    if self:isOur() then
        delay=delay+1
        self:showSkillDrawing(Const.SKILL_TYPE_ANGER)
    end
--    self:callWithDelay(0.2,function()
--        if self:isOur() then
--            local ourHero=self._battleScene:getOurHero()
--            if not ourHero:isDead() then
--                ourHero._anim:setVisible(false)
--            end
--        else
--            local enemyHero=self._battleScene:getEnemyHero()
--            if not enemyHero:isDead() then
--                enemyHero._anim:setVisible(false)
--            end
--        end
--    end)
    
    local anim=self:createAnim(self._img,60)
    anim:PlaySection(SIdle,true)
    if not self._isInBattle then
        anim:runAction(cc.Sequence:create(
            cc.MoveBy:create(0,cc.p(-400,0)),
            cc.MoveBy:create(0.4,cc.p(400,0))
            ))
    end
    self._panelBuffFace:setVisible(false)
    self:callWithDelay(delay,function()
        self:createBlackLayer()
--        self._battleScene:playBallAnimation(self._elementType,self:isOur())
    end)
    
    delay=delay+0.4
    delay=self:showBallCombo(delay,self._battleScene:getBallAmount(self._elementType))
    
    self:callWithDelay(delay,function()
        self._skillType=Const.SKILL_TYPE_ANGER
        local skillId=self._skills[self._skillType][1]
        local skillLevel=self._skills[self._skillType][2]
        local skillValue=t_skill_value[skillId]
        local stra=t_strategy[skillId]
        local skillConf=t_skill[skillId]
        self:showSkillName(skillId)

--        if self._fireAnim then
--            self._fireAnim:removeFromParent()
--        end

        eventUtil.dispatchCustom("on_cleanup_skill",4)

        if skillConf.effects_id~="" then
            anim:PlaySection(skillConf.effects_id,false)
        else
            anim:PlaySection(SAnger,false)
        end
        if skillConf.animation~="" then
            self:createAnim(skillConf.animation,70,true):PlaySection(skillConf.animation_id,false)
        end

        self:callWithDelay(skillValue.value_delay1,function()
            eventUtil.dispatchCustom("on_shake_screen")
            self:strategyFunc(stra,skillValue,skillLevel,1)
        end)
        local all_delay=skillValue.all_delay1
        if self:canFireSkill(self._skillType,2) then
            print("效果2")
            all_delay=skillValue.all_delay2
            self:callWithDelay(skillValue.value_delay2,function()
                self:strategyFunc(stra,skillValue,skillLevel,2)
            end)
        end
        self._skillCD[self._skillType]=0
        self:callWithDelay(all_delay,function()
            self._battleScene:useBall(self._elementType)
            self._battleScene:generateBall()
        end)
        self:callWithDelay(all_delay,function()
            if self:isOur() then
                local ourHero=self._battleScene:getOurHero()
                if not ourHero:isDead() then
                    ourHero._anim:setVisible(true)
                end
            else
                local enemyHero=self._battleScene:getEnemyHero()
                if not enemyHero:isDead() then
                    enemyHero._anim:setVisible(true)
                end
            end
            self._panelBuffFace:setVisible(true)
            self:removeBlackLayer()
            self._battleScene:nextBattle()
        end)
    end)
end

function BattleHero:fire7StarAtk()
    print("被动技能")

    self._skillType=Const.SKILL_TYPE_STAR_7
    local skillId=self._skills[self._skillType][1]
    local skillLevel=self._skills[self._skillType][2]
    local skillValue=t_skill_value[skillId]
    local stra=t_strategy[skillId]
    local skillConf=t_skill[skillId]
    if self:getSkillType(Const.SKILL_TYPE_STAR_7)~=8 then
        self:showSkillName(skillId)
    end
    self:showSkillName2(skillId)

    if skillConf.animation~="" then
        self:createAnim(skillConf.animation,70,true):PlaySection(skillConf.animation_id,false)
    end
    
    eventUtil.dispatchCustom("on_cleanup_skill",1)

    self:callWithDelay(skillValue.value_delay1,function()
        self:strategyFunc(stra,skillValue,skillLevel,1)
    end)
    local all_delay=skillValue.all_delay1
    if self:canFireSkill(self._skillType,2) then
        print("效果2")
        all_delay=skillValue.all_delay2
        self:callWithDelay(skillValue.value_delay2,function()
            self:strategyFunc(stra,skillValue,skillLevel,2)
        end)
    end
    self._skillCD[self._skillType]=0
    self:callWithDelay(all_delay,function()
        self._anim:PlaySection(SIdle,true)
        self:onStrikeStep()
    end)
end

function BattleHero:fire3StarAtk()
    print("3星技能")
    self._panelBuffFace:setVisible(false)
    --如果目标死亡
    if self:getTarget():isDead() then
        print("目标死亡")
        performWithDelay(self._uiLayer,function()
            self._battleScene:nextBattle()
        end,0)
        return
    end
    self._skillType=Const.SKILL_TYPE_STAR_3

    self._battleScene._uiLayer.panel_center:reorderChild(self._anim,60)
    local skillId=self._skills[self._skillType][1]
    local skillLevel=self._skills[self._skillType][2]
    local skillValue=t_skill_value[skillId]
    local stra=t_strategy[skillId]
    local skillConf=t_skill[skillId]
    
    eventUtil.dispatchCustom("on_cleanup_skill",2)

    self:createBlackLayer()
    if skillConf.effects_id~="" then
        self._anim:PlaySection(skillConf.effects_id,true)
    else
        self._anim:PlaySection(SStar3,true)
    end
    if skillConf.animation~="" then
        self:createAnim(skillConf.animation,70,true):PlaySection(skillConf.animation_id,false)
    end
    self:showSkillName(skillId)

    self:callWithDelay(skillValue.value_delay1,function()
        eventUtil.dispatchCustom("on_shake_screen")
        self:strategyFunc(stra,skillValue,skillLevel,1)
    end)
    local all_delay=skillValue.all_delay1
    if self:canFireSkill(self._skillType,2) then
        print("效果2")
        all_delay=skillValue.all_delay2
        self:callWithDelay(skillValue.value_delay2,function()
            self:strategyFunc(stra,skillValue,skillLevel,2)
        end)
    end
    self._skillCD[self._skillType]=0
    self:callWithDelay(all_delay,function()
        self:removeBlackLayer()
        self._anim:PlaySection(SIdle,true)
        self:onStrikeStep()
    end)
end

function BattleHero:fire5StarAtk()
    print("5星技能")
    self._panelBuffFace:setVisible(false)
    --如果目标死亡
    if self:getTarget():isDead() then
        print("目标死亡")
        performWithDelay(self._uiLayer,function()
            self._battleScene:nextBattle()
        end,0)
        return
    end
    self._skillType=Const.SKILL_TYPE_STAR_5
    self._battleScene._uiLayer.panel_center:reorderChild(self._anim,60)
    local skillId=self._skills[self._skillType][1]
    local skillLevel=self._skills[self._skillType][2]
    local skillValue=t_skill_value[skillId]
    local stra=t_strategy[skillId]
    local skillConf=t_skill[skillId]
    
    eventUtil.dispatchCustom("on_cleanup_skill",3)

    self:createBlackLayer()
    if skillConf.effects_id~="" then
        self._anim:PlaySection(skillConf.effects_id,true)
    else
        self._anim:PlaySection(SStar5,true)
    end
    if skillConf.animation~="" then
        self:createAnim(skillConf.animation,70,true):PlaySection(skillConf.animation_id,false)
    end
    self:showSkillName(skillId)

    self:callWithDelay(skillValue.value_delay1,function()
        eventUtil.dispatchCustom("on_shake_screen")
        self:strategyFunc(stra,skillValue,skillLevel,1)

    end)
    local all_delay=skillValue.all_delay1
    if self:canFireSkill(self._skillType,2) then
        print("效果2")
        all_delay=skillValue.all_delay2
        self:callWithDelay(skillValue.value_delay2,function()
            self:strategyFunc(stra,skillValue,skillLevel,2)
        end)
    end
    self._skillCD[self._skillType]=0
    self:callWithDelay(all_delay,function()
        self:removeBlackLayer()
        self._anim:PlaySection(SIdle,true)
        self:onStrikeStep()
    end)
end

function BattleHero:fireNormalAtk()
    print("普通攻击")
    --如果目标死亡
    if self:getTarget():isDead() then
        print("目标死亡")
        performWithDelay(self._uiLayer,function()
            self._battleScene:nextBattle()
        end,0)
        return
    end
    if self._cate~=3 then
        self:callWithDelay(0.5,function()
            eventUtil.dispatchCustom("on_soldier_strike",self)
        end)
    end
    self._skillType=Const.SKILL_TYPE_NORMAL
    self._battleScene._uiLayer.panel_center:reorderChild(self._anim,31)
    local skillId=self._skills[self._skillType][1]
    local skillLevel=self._skills[self._skillType][2]
    local skillValue=t_skill_value[skillId]
    local stra=t_strategy[skillId]
    local skillConf=t_skill[skillId]
    if skillConf.effects_id~="" then
        self._anim:PlaySection(skillConf.effects_id,true)
    else
        self._anim:PlaySection(SAttack,true)
    end

    self:callWithDelay(skillValue.value_delay1,function()
        self:strategyFunc(stra,skillValue,skillLevel,1)
    end)
    local all_delay=skillValue.all_delay1
    if self:canFireSkill(self._skillType,2) then
        print("效果2")
        all_delay=skillValue.all_delay2
        self:callWithDelay(skillValue.value_delay2,function()
            self:strategyFunc(stra,skillValue,skillLevel,2)
        end)
    end
    self._skillCD[self._skillType]=0
    self:callWithDelay(all_delay,function()
        self._anim:PlaySection(SIdle,true)
        self:onStrikeStep()
    end)
end

function BattleHero:hpRatio()
    return self:getHp()/self:getMaxHp()
end

function BattleHero:toBattle()
    self._attacked=false
    self._isBorn=true
    self._isInBattle=true
    self._uiLayer:addChild(require("battle/HeroInBattleController"):create(self))
end

function BattleHero:createAnim(animId,zOrder,unOffset)
    local anim=commonUtil.getAnim(animId)
    if anim then
        self._battleScene._uiLayer.panel_center:addChild(anim,zOrder)
        if self:isEnemy() then
            if unOffset==nil then
                anim:setPosition(120,0)
            end
            anim:setScaleX(-1)
        else
            if unOffset==nil then
                anim:setPosition(-120,0)
            end
        end
    end
    return anim
end

function BattleHero:getBuff(id)
    local side=2
    if self:isOur() then side=1 end
    return BattleBuffMgr.get_buff(side,id)
end

function BattleHero:getDefWater()
    local buff=self:getBuff(1017)
    local val =self._def[Const.HERO_ELEMENT_WATER]
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio--/100*val
    end
    buff=self:getBuff(1024)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1011)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1005)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    return val
end

function BattleHero:setDefWater(v)
    self._def[Const.HERO_ELEMENT_WATER]=v
end

function BattleHero:getDefFire()
    local buff=self:getBuff(1018)
    local val =self._def[Const.HERO_ELEMENT_FIRE]
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio--/100*val
    end
    buff=self:getBuff(1025)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1012)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1005)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    return val
end

function BattleHero:setDefFire(v)
    self._def[Const.HERO_ELEMENT_FIRE]=v
end

function BattleHero:getDefWood()
    local buff=self:getBuff(1019)
    local val =self._def[Const.HERO_ELEMENT_WOOD]
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio--/100*val
    end
    buff=self:getBuff(1026)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1013)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    buff=self:getBuff(1005)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio--/100*val
    end
    return val
end

function BattleHero:setDefWood(v)
    self._def[Const.HERO_ELEMENT_WOOD]=v
end

function BattleHero:isOur()
    return self._battleSide==Const.BATTLE_OBJ_OUR
end

function BattleHero:isEnemy()
    return self._battleSide==Const.BATTLE_OBJ_ENEMY or
        self._battleSide==Const.BATTLE_OBJ_BOSS
end

function BattleHero:canFireNormalAtk()
    return not BattleBuffMgr.has_no_move_buff(self) and self:canFireSkill(Const.SKILL_TYPE_NORMAL,1)
end

function BattleHero:canFire3StarAtk()
    local res=BattleBuffMgr.has_no_move_buff(self) or BattleBuffMgr.has_no_skill_buff(self)
    return not res and self:canFireSkill(Const.SKILL_TYPE_STAR_3,1)
end

function BattleHero:canFire5StarAtk()
    local res=BattleBuffMgr.has_no_move_buff(self) or BattleBuffMgr.has_no_skill_buff(self)
    return not res and self:canFireSkill(Const.SKILL_TYPE_STAR_5,1)
end

function BattleHero:canFire7StarAtk()
    if self:getSkillType(Const.SKILL_TYPE_STAR_7)==7 then
        if BattleBuffMgr.has_no_move_buff(self) then
            return false
        end
    end
    return self:canFireSkill(Const.SKILL_TYPE_STAR_7,1)
end

--------------------------
--@function 攻击上升
function BattleHero:atkUp(v)
    local val=self:getAtk()
    self:setAtk(val+v)
end
--------------------------
--@function 攻击下降
function BattleHero:atkDown(v)
    local val=self:getAtk()
    self:setAtk(val-v)
end
-------------------------
--@function 增加怒气点
function BattleHero:upAngerPoint(n)
    local num=self:getAngerPoint()
    if num<Const.BATTLE_ANGER_SUM then
        num=num+n
        if num<0 then num=0 end
        if num>Const.BATTLE_ANGER_SUM then num=Const.BATTLE_ANGER_SUM end
        self:setAngerPoint(num)
    end
end
-------------------------
--@function 减少怒气点
function BattleHero:downAngerPoint(n)
    local num=self:getAngerPoint()-n
    if num<0 then num=0 end
    self:setAngerPoint(num)
end

function BattleHero:getAngerPoint()
    return xor(self._angerPoint,self._randAp)
end

function BattleHero:setAngerPoint(v)
    self._randAp=os.time()
    self._angerPoint=xor(v,self._randAp)
end

function BattleHero:getCritRate()
    local buff=self:getBuff(1021)
    local val=self._critRate
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end
    buff=self:getBuff(1008)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end

    return val
end

function BattleHero:getCrit()
    local buff=self:getBuff(1027)
    local val=self._crit
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end
    buff=self:getBuff(1028)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio
    end

    return val
end

function BattleHero:getCure()
    local buff=self:getBuff(1029)
    local val=self._cure
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end
    buff=self:getBuff(1030)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio
    end

    return val
end

function BattleHero:getDodgeRate()
    local buff=self:getBuff(1031)
    local val=self._dodgeRate
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end
    buff=self:getBuff(1032)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val-ratio
    end
    buff=self:getBuff(1009)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        val=val+ratio
    end

    return val
end

function BattleHero:getAtk()
    local atk=xor(self._atk,self._randAtk)
    local buff=self:getBuff(1016)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        atk=atk-ratio/100*atk
    end
    buff=self:getBuff(1005)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        atk=atk-ratio/100*atk
    end
    buff=self:getBuff(1015)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        atk=atk+ratio/100*atk
    end
    buff=self:getBuff(1007)
    if buff then
        local ratio=buff._config.val+(buff._lv-1)*buff._config.var
        atk=atk+ratio/100*atk
    end
    return atk
end

function BattleHero:setAtk(v)
    self._randAtk=os.time()
    self._atk=xor(v,self._randAtk)
end

function BattleHero:getHp()
    return xor(self._hp,self._randHp)
end

function BattleHero:setHp(v)
    self._randHp=os.time()
    self._hp=xor(v,self._randHp)
    if self:getMaxHp()==0 then
        self:setMaxHp(v)
    else
        if v>self:getMaxHp() then self._hp=self:getMaxHp() end
    end
    eventUtil.dispatchCustom("on_hp_change",self)
end

function BattleHero:getMaxHp()
    if self._maxHp==0 then return 0 end
    return self._maxHp-439974
end

function BattleHero:setMaxHp(v)
    if v==0 then return end
    self._maxHp=v+439974
end

function BattleHero:isDead()
    return self:getHp()==0
end

---------------------------
--@param    defType 防御力属性
--@return   #number 防御力减免
function BattleHero:getDefReduce(defType)
    local nDef=self._def[defType]
    return nDef/Const.DENOMINATOR
end

---------------------------
--@return
function BattleHero:callWithDelay(delay,callback)
    local actDelay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(actDelay, cc.CallFunc:create(callback,self))
    self._uiLayer:runAction(sequence)
end

function BattleHero:setDead()
    self._isBorn=false
    self._isInBattle=false
    self._uiLayer:removeChildByName("HeroInBattleController")
    self._uiLayer:removeChildByName("SoldierController")
    --设置头像
    self._deadImg:setVisible(true)

end

function BattleHero:getTarget()
    if self:isOur() then
        return self._battleScene:getEnemyHero()
    end
    return self._battleScene:getOurHero()
end

--------------------------
--@function HP下降
function BattleHero:hpDown(v,isFlyout)
    v=self:getHp()-v
    if v<0 then v=0 end
    self:setHp(v)
    self._anim:PlaySection(SInjury,true)
    --死亡
    if v==0 then
        print(self._name,"死了")
        local anim=self._anim
        self:callWithDelay(0.8,function()
            anim:PlaySection(SDead,false)
        end)
    end
    if self._cate~=3 then
        eventUtil.dispatchCustom("on_decr_soldier",self)
    end
end
--------------------------
--@function HP上升
function BattleHero:hpUp(v)
    v=self:getHp()+v
    if self._cate~=3 then
        self._hp_up_v=v
        eventUtil.dispatchCustom("on_incr_soldier",self)
    end
    if v>self:getMaxHp() then v=self:getMaxHp() end
    self:setHp(v)
end

function BattleHero:setVictoryState()
    self._state=SVictory
    self._anim:PlaySection(SVictory,true)
end




return BattleHero

