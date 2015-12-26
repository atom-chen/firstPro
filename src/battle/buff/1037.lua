local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1037 = class("Buff_1037",BattleBuff)

function Buff_1037:onEnter()
    eventUtil.dispatchCustom("on_weather_change",{buff=self,weather=Const.WEATHER.RAIN})
end

function Buff_1037:onExit()
    eventUtil.dispatchCustom("on_random_weather")
end

function Buff_1037:onUpgrade()
    self._round=self._config.round
    eventUtil.dispatchCustom("on_update_weather",self)
end

function Buff_1037:schedulePerRound()
    self.super.schedulePerRound(self)
    eventUtil.dispatchCustom("on_update_weather",self)
end

return Buff_1037