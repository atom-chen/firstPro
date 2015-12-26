local t_skill=require("config/t_skill")
local SStar3="s1"
local SStar5="s2"
local SAnger="s3"
local SBorn="s4"
local SIdle="s5"
local SAttack="s6"
local SInjury="s7"
local SVictory="s8"
local SDead="s9"

local HeroInBattleController=class("BattleHeroInBattleController",function()
    return cc.Node:create()
end)

function HeroInBattleController:create(owner)
    return HeroInBattleController.new(owner)
end

function HeroInBattleController:ctor(owner)
    self:setName("HeroInBattleController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function HeroInBattleController:onCallPerRound(param)
    local hero=self._owner
    local ui=hero._battleScene._uiLayer
    if hero:canFire7StarAtk() then
        if hero:isOur() then
            ui.img_skill_gray1:setVisible(false)
            self:showCircle(1)
        end
    end
    if hero:canFire3StarAtk() then
        if hero:isOur() then
            ui.img_skill_gray2:setVisible(false)
            self:showCircle(2)
        end
    end
    if hero:canFire5StarAtk() then
        if hero:isOur() then
            ui.img_skill_gray3:setVisible(false)
            self:showCircle(3)
        end
    end
    if hero:canFireSkill(Const.SKILL_TYPE_ANGER,1) then
        if hero:isOur() then
            ui.img_skill_gray4:setVisible(false)
            self:showCircle(4)
        end
    end
    
end

function HeroInBattleController:showCircle(pos)
    local particle=particleUtil.createRetangle("particle/star.plist",90)
    particle:setPosition(-2,2)
    self._owner._battleScene._uiLayer["panel_skill"..pos]:removeChildByTag(0x1999)
    self._owner._battleScene._uiLayer["panel_skill"..pos]:addChild(particle,25,0x1999)
end

function HeroInBattleController:onSkillClick(param)
    local hero=self._owner
    if hero._battleScene._uiLayer["img_skill_gray"..param]:isVisible() then return end
    if param==4 then
        param=Const.SKILL_TYPE_ANGER
    elseif param==3 then
        param=Const.SKILL_TYPE_STAR_5
    elseif param==2 then
        param=Const.SKILL_TYPE_STAR_3
    elseif param==1 then
        param=Const.SKILL_TYPE_STAR_7
    end
    
    
    eventUtil.dispatchCustom(string.format("on_fire_anger_skill_%d_%d",hero._battleSide,hero._pos),param)
end

function HeroInBattleController:onCleanupSkill(param)
    self._owner._battleScene._uiLayer["panel_skill"..param]:removeChildByTag(0x1999)
    self._owner._battleScene._uiLayer["img_skill_gray"..param]:setVisible(true)
end

function HeroInBattleController:onEnter()
    eventUtil.addCustom(self,"on_hp_change",function(event)self:onHpChange(event.param)end)
    eventUtil.addCustom(self,"on_call_per_round",function(event)self:onCallPerRound(event.param)end)
    local hero=self._owner
    if hero:isOur() then
        eventUtil.addCustom(self,"on_cleanup_skill",function(event)self:onCleanupSkill(event.param)end)
        eventUtil.addCustom(self,"ui_battle_on_skill_click",function(event)self:onSkillClick(event.param)end)
    end
    self:scheduleUpdateWithPriorityLua(function(dt) self:update(dt) end,0)
--    hero._labelHp:setString(tostring(hero:getHp()))
    --设置头像出战图片

--    hero._uiLayer.image_status1:setVisible(false)
--    hero._uiLayer.image_status2:setVisible(true)
    --设置名字
--    hero._labelName:setString(hero._name)
    --设置血量UI

    local ui=hero._battleScene._uiLayer
    
    local partiBlood=cc.ParticleSystemQuad:create("particle/blood.plist")
    hero._partiBlood=partiBlood
    if hero:isOur() then
        self._prog_hp_w=ui.prog_our_hp:getContentSize().width
        partiBlood:setPosition(self._prog_hp_w,10)
        ui.prog_our_hp:removeChildByTag(0x100)
        ui.prog_our_hp:addChild(partiBlood,22,0x100)
        
    else
        self._prog_hp_w=ui.prog_enemy_hp:getContentSize().width
        partiBlood:setPosition(0,10)
        ui.prog_enemy_hp:removeChildByTag(0x100)
        ui.prog_enemy_hp:addChild(partiBlood,22,0x100)
        self._prog_hp_w=ui.prog_our_hp:getContentSize().width
    end
    if hero:isOur() then
        local skillId=hero._skills[Const.SKILL_TYPE_STAR_7][1]
        local skillConf=t_skill[skillId]
        widgetUtil.createIconToWidget(skillConf.icon,ui.panel_skill1)
        
        local skillId=hero._skills[Const.SKILL_TYPE_STAR_3][1]
        local skillConf=t_skill[skillId]
        widgetUtil.createIconToWidget(skillConf.icon,ui.panel_skill2)
        
        local skillId=hero._skills[Const.SKILL_TYPE_STAR_5][1]
        local skillConf=t_skill[skillId]
        widgetUtil.createIconToWidget(skillConf.icon,ui.panel_skill3)
        
        local skillId=hero._skills[Const.SKILL_TYPE_ANGER][1]
        local skillConf=t_skill[skillId]
        widgetUtil.createIconToWidget(skillConf.icon,ui.panel_skill4)
    end
    
    hero._progHp:setPercent(100)
    hero._skillCD[Const.SKILL_TYPE_NORMAL]=1
    hero._skillCD[Const.SKILL_TYPE_STAR_3]=1
    hero._skillCD[Const.SKILL_TYPE_STAR_5]=1
    hero._skillCD[Const.SKILL_TYPE_STAR_7]=1
    hero._state=SBorn
    if hero._cate~=3 then
        hero._uiLayer:addChild(require("battle/SoldierController"):create(hero))
    end
    hero._anim=hero:createAnim(hero._img,30)
    hero._anim:registerTimeEvent(SStar3,1,function()
        hero._anim:PlaySection(SIdle,true)
    end)
    hero._anim:registerTimeEvent(SStar5,1,function()
        hero._anim:PlaySection(SIdle,true)
    end)
    hero._anim:registerTimeEvent(SBorn,1,function()
        hero._anim:PlaySection(SIdle,true)
    end)
    hero._anim:registerTimeEvent(SAttack,1,function()
        hero._anim:PlaySection(SIdle,true)
    end)
    hero._anim:registerTimeEvent(SInjury,1,function()
        hero._anim:PlaySection(SIdle,true)
    end)

    hero._anim:PlaySection(SBorn,true)

    hero:callWithDelay(0.3,function()
        local anim=hero:createAnim(3003,300)
        anim:PlaySection("s1",false)
    end)
end

function HeroInBattleController:onExit()
    eventUtil.removeCustom(self)
    local hero=self._owner
--    print(hero._name,"死了")
    self:unscheduleUpdate()
end

function HeroInBattleController:onHpChange(param)
    local hero=param
--    hero._labelHp:setString(tostring(hero:getHp()))
end

function HeroInBattleController:update(dt)
    local hero=self._owner
    local per=hero._progHp:getPercent()
    local hpPer=hero:hpRatio()*100
    if per<hpPer-3 then
        hero._progHp:setPercent(per+2)
        self:updateBloodParti(per+2)
    elseif per>hpPer+3 then
        hero._progHp:setPercent(per-2)
        self:updateBloodParti(per-2)
    end
end

function HeroInBattleController:updateBloodParti(hpPer)
    local hero=self._owner
    if hero:isOur() then
        hero._partiBlood:setPositionX(self._prog_hp_w/100*hpPer)
    else
        hero._partiBlood:setPositionX(self._prog_hp_w-self._prog_hp_w/100*hpPer)
    end
end

return HeroInBattleController