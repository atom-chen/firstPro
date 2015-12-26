
local SStar3="s1"
local SStar5="s2"
local SAnger="s3"
local SBorn="s4"
local SIdle="s5"
local SAttack="s6"
local SInjury="s7"
local SVictory="s8"
local SDead="s9"

local HeroOnBattleController=class("BattleHeroOnBattleController",function()
    return cc.Node:create()
end)

function HeroOnBattleController:create(owner)
    return HeroOnBattleController.new(owner)
end

function HeroOnBattleController:ctor(owner)
    self:setName("HeroOnBattleController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function HeroOnBattleController:onEnter()
    eventUtil.addCustom(self,"on_hp_change",function(event)self:onHpChange(event.param)end)
    local hero=self._owner
    self:scheduleUpdateWithPriorityLua(function(dt) self:update(dt) end,0)
    hero._labelHp:setString(tostring(hero:getHp()))
    --设置头像出战图片

    hero._uiLayer.image_status1:setVisible(false)
    hero._uiLayer.image_status2:setVisible(true)
    --设置名字
    hero._labelName:setString(hero._name)
    --设置血量UI

    local ui=hero._battleScene._uiLayer
    if hero:isOur() then
        ui.label_our_hp_max:setString("/"..tostring(hero:getMaxHp()))
    else
        ui.label_enemy_hp_max:setString("/"..tostring(hero:getMaxHp()))
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

function HeroOnBattleController:onExit()
    eventUtil.removeCustom(self)
    local hero=self._owner
--    print(hero._name,"死了")
    self:unscheduleUpdate()
end

function HeroOnBattleController:onHpChange(param)
    local hero=param
    hero._labelHp:setString(tostring(hero:getHp()))
end

function HeroOnBattleController:update(dt)
    local hero=self._owner
    local per=hero._progHp:getPercent()
    local hpPer=hero:hpRatio()*100
    if per<hpPer-3 then
        hero._progHp:setPercent(per+2)
    elseif per>hpPer+3 then
        hero._progHp:setPercent(per-2)
    end
end

return HeroOnBattleController