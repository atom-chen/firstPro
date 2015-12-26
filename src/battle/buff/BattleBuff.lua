
local BattleBuff = class("BattleBuff")
local t_skill_buff=require("config.t_skill_buff")

function BattleBuff:ctor(id,caster,target,level)
    self._config=t_skill_buff[id]
    self._config.id=id
    self._caster=caster
    self._target=target
    self._lv=level or 1
    self._round=self._config.round
    
end

function BattleBuff:getTarget()
    local target=nil
    if self._target:isOur() then
        target=self._target._battleScene:getEnemyHero()
    else
        target=self._target._battleScene:getOurHero()
    end
    return target
end

function BattleBuff:schedulePerRound()
    self._round=self._round-1
    if self._round<=0 then
        self._deleteFlag=true
        BattleBuffMgr.add_delete_buff(self)
    end
end

function BattleBuff:onEnter()
    local launch_id=self._config.launch_id
    eventUtil.dispatchCustom("on_buff_launch_anim",self)
end

function BattleBuff:onExit()
    eventUtil.dispatchCustom("on_remove_buff",self)
end

--升级回调
function BattleBuff:onUpgrade(level)
    if self._lv>=self._config.lv then return end
    self._lv=self._lv+level
    if self._lv>self._config.lv then
        self._lv=self._config.lv
    end
    self._round=self._config.round
    eventUtil.dispatchCustom("on_buff_change_lv",self)
end

--降级回调
function BattleBuff:onDegrade(level)
    self._lv=self._lv-level
    eventUtil.dispatchCustom("on_buff_change_lv",self)
end

--执行buff策略
function BattleBuff:execute()
    local delay=0
    local toggle_id=self._config.toggle_id
    if toggle_id~="" then
        delay=1
        eventUtil.dispatchCustom("on_buff_toggle_anim",self)
    end
    return delay
end

return BattleBuff
