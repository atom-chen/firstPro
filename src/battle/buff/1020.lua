local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1020 = class("Buff_1020",BattleBuff)

function Buff_1020:execute()
    self.super.execute(self)
    local target=self:getTarget()
    if BattleBuffMgr.has_no_recover_buff(target) then
        local ratio=self._config.val+(self._lv-1)*self._config.var
        local hp=ratio/100*target:getMaxHp()
        target:hpUp(hp)
        target:showValueEffect(target,hp,2,1,0)
    end
end

return Buff_1020