local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1001 = class("Buff_1001",BattleBuff)

function Buff_1001:execute()
    self.super.execute(self)
    local target=self:getTarget()
    local ratio=self._config.val+(self._lv-1)*self._config.var
    local hp=ratio/100*target:getMaxHp()
    target:hpDown(hp)
    target:showValueEffect(target,-hp,1,1,0)
end

return Buff_1001