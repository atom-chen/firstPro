local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1039 = class("Buff_1039",BattleBuff)

function Buff_1039:onEnter()
    eventUtil.dispatchCustom("on_weather_change",{buff=self,weather=Const.WEATHER.FOG})
end

function Buff_1039:onExit()
    eventUtil.dispatchCustom("on_random_weather")
end

function Buff_1039:onUpgrade()
    self._round=self._config.round
    eventUtil.dispatchCustom("on_update_weather",self)
end

function Buff_1039:schedulePerRound()
    self.super.schedulePerRound(self)
    eventUtil.dispatchCustom("on_update_weather",self)
end

return Buff_1039