
local HeroController=class("HeroController",function()
    return cc.Node:create()
end)

function HeroController:create(owner)
    return HeroController.new(owner)
end

function HeroController:ctor(owner)
    self:setName("HeroController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function HeroController:onEnter()
    local hero=self._owner
    eventUtil.addCustom(self,"on_call_per_round",function(event)self:onCallPerRound(event.param)end)
    eventUtil.addCustom(self,string.format("on_fire_anger_skill_%d_%d",hero._battleSide,hero._pos),function(event)self:onFireAngerSkill(event.param)end)
end

function HeroController:onExit()
    eventUtil.removeCustom(self)
end

function HeroController:onFireAngerSkill(param)
    local hero=self._owner

    hero._fireAnim=commonUtil.getAnim(3005)
    if hero._fireAnim then
--        hero._fireAnim:setPosition(60,80)
--        hero._fireAnim:PlaySection("s1",true)
--        hero._uiLayer:addChild(hero._fireAnim,0xFFFF)
    end
--    hero._uiAnger:setVisible(false)
--    hero._angerProg:setPercent(100)
    
    table.insert(hero._battleScene._angerSkillList,{hero=hero,skill=param})
    if hero._battleScene._isPvp then
        hero._battleScene:appendAngerSkillLog(hero:isOur(),hero._pos)
    end
end

function HeroController:onCallPerRound(param)
    local round=param
    local hero=self._owner
    hero._skillCD[Const.SKILL_TYPE_NORMAL]=hero._skillCD[Const.SKILL_TYPE_NORMAL]+1
    hero._skillCD[Const.SKILL_TYPE_STAR_3]=hero._skillCD[Const.SKILL_TYPE_STAR_3]+1
    hero._skillCD[Const.SKILL_TYPE_STAR_5]=hero._skillCD[Const.SKILL_TYPE_STAR_5]+1
    hero._skillCD[Const.SKILL_TYPE_STAR_7]=hero._skillCD[Const.SKILL_TYPE_STAR_7]+1
    hero._skillCD[Const.SKILL_TYPE_ANGER]=hero._skillCD[Const.SKILL_TYPE_ANGER]+1
    hero._attacked=false

    local cdMax=hero._angerSkillMaxCD
    local cd=hero._skillCD[Const.SKILL_TYPE_ANGER]
    local isFull=(cd>=cdMax)
--    hero._uiAnger:setVisible(isFull)
--    if round >= 1 then
--        hero._angerProg:setPercent(100-math.ceil(cd/cdMax*100))
--    end
    if hero:isOur() and not hero._isInBattle then
        if hero:canFireSkill(Const.SKILL_TYPE_ANGER,1) then
            eventUtil.dispatchCustom(string.format("on_fire_anger_skill_%d_%d",hero._battleSide,hero._pos),Const.SKILL_TYPE_ANGER)
        end
    end
    
end

return HeroController