local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1002 = class("Buff_1002",BattleBuff)

function Buff_1002:schedulePerRound()
    self.super.schedulePerRound(self)
    if self._round>0 then
        local prob=self._config.val-(self._lv-1)*self._config.var
        if prob>0 and commonUtil.isProbHappen(prob) then
            self._round=0
            self.super.schedulePerRound(self)
        end
    end
end

return Buff_1002