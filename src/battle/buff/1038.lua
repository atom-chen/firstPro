local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1038 = class("Buff_1038",BattleBuff)

function Buff_1038:onEnter()
    eventUtil.dispatchCustom("on_weather_change",{buff=self,weather=Const.WEATHER.NONE})
end

function Buff_1038:onExit()
    eventUtil.dispatchCustom("on_random_weather")
end

function Buff_1038:onUpgrade()
    self._round=self._config.round
    eventUtil.dispatchCustom("on_update_weather",self)
end

function Buff_1038:schedulePerRound()
    self.super.schedulePerRound(self)
    eventUtil.dispatchCustom("on_update_weather",self)
end

return Buff_1038