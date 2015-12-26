local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1006 = class("Buff_1006",BattleBuff)

function Buff_1006:execute()
    self.super.execute(self)
    local target=self:getTarget()
    local ratio=self._config.val+(self._lv-1)*self._config.var
    local hp=ratio/100*target:getMaxHp()
    target:hpDown(hp)
    target:showValueEffect(self:getTarget(),-hp,1,1,0)

    local caster=nil
    if target:isOur() then
        caster=target._battleScene:getEnemyHero()
    else
        caster=target._battleScene:getOurHero()
    end
    caster:hpUp(hp)
    caster:showValueEffect(caster,hp,2,1,0)
end

return Buff_1006