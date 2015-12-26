local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1033 = class("Buff_1033",BattleBuff)

function Buff_1033:execute()
    local target=self:getTarget()
    self.super.execute(self)
    local ratio=self._config.val+(self._lv-1)*self._config.var
    local atk=ratio/100*target:getAtk()
    target:atkDown(atk)
    target:showValueEffect(target,atk,3,1,0)
end

return Buff_1033