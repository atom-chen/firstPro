local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1023 = class("Buff_1023",BattleBuff)

function Buff_1023:execute()
    self.super.execute(self)
    local target=self:getTarget()
    local ratio=self._config.val+(self._lv-1)*self._config.var
    local atk=ratio/100*target:getAtk()
    target:atkUp(atk)
    target:showValueEffect(target,atk,3,1,0)
end

return Buff_1023