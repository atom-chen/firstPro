local BattleBuff=require("battle.buff.BattleBuff")
local Buff_1040 = class("Buff_1040",BattleBuff)

function Buff_1040:onEnter()
    self._anim=commonUtil.getAnim(self._config.effect_id)
    local target=self:getTarget()
    if self._anim then
        self._anim:PlaySection("s1",true)

        target._battleScene._uiLayer.panel_center:addChild(self._anim,0,10)
        if target:isOur() then
            self._anim:setPosition(-280,-50)
        else
            self._anim:setScaleX(-1)
            self._anim:setPosition(280,-50)
        end
    end
end

function Buff_1040:onExit()
    self._anim:removeFromParent()
end

function Buff_1040:execute(isOur)
    local target=self:getTarget()
    if target:isOur()~=isOur then return 0 end
    local delay=self.super.execute(self)
    local ratio=self._config.val+(self._lv-1)*self._config.var
    local hp=ratio/100*target:getHp()
    target:hpDown(hp)
    target:showValueEffect(target,-hp,1,1,0)
    return delay
end

return Buff_1040