local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1036 = class("Buff_1036",BattleBuff)

function Buff_1036:onEnter()
    eventUtil.dispatchCustom("on_weather_change",{buff=self,weather=Const.WEATHER.SUNNY})
end

function Buff_1036:onExit()
    eventUtil.dispatchCustom("on_random_weather")
end

function Buff_1036:onUpgrade()
    self._round=self._config.round
    eventUtil.dispatchCustom("on_update_weather",self)
end

function Buff_1036:schedulePerRound()
    self.super.schedulePerRound(self)
    eventUtil.dispatchCustom("on_update_weather",self)
end

return Buff_1036