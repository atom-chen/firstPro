
local SceneController=class("SceneController",function()
    return cc.Node:create()
end)

function SceneController:create(owner)
    return SceneController.new(owner)
end

function SceneController:ctor(owner)
    self:setName("SceneController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function SceneController:onEnter()
    cc.Director:getInstance():getScheduler():setTimeScale(1.2)
    eventUtil.addCustom(self,"on_shake_screen",function(event)self:onShakeScreen(event.param)end)
    eventUtil.addCustom(self,"on_buff_launch_anim",function(event)self:onBuffLaunchAnim(event.param)end)
    eventUtil.addCustom(self,"on_buff_toggle_anim",function(event)self:onBuffToggleAnim(event.param)end)
    eventUtil.addCustom(self,"on_remove_buff",function(event)self:onRemoveBuff(event.param)end)
    eventUtil.addCustom(self,"on_buff_change_lv",function(event)self:onBuffChangeLv(event.param)end)
    
    local parti=cc.ParticleSystemQuad:create("particle/fire.plist")
    parti:setPosition(self._owner._uiLayer.img_flash1:getPosition())
    self._owner._uiLayer.panel_info:addChild(parti,9)
    local parti2=cc.ParticleSystemQuad:create("particle/fire.plist")
    parti2:setPosition(self._owner._uiLayer.img_flash2:getPosition())
    self._owner._uiLayer.panel_info:addChild(parti2,9)
end

function SceneController:onExit()
    eventUtil.removeCustom(self)
    cc.Director:getInstance():getScheduler():setTimeScale(1)
end

--释放BUFF特效
function SceneController:onBuffLaunchAnim(buff)
    local _uiLayer=self._owner._uiLayer
    if buff._config.launch_id~="" then
        local anim=commonUtil.getAnim(buff._config.launch_id)
        anim:PlaySection("s1", false)
        _uiLayer.panel_center:addChild(anim,35)
        if buff._target:isOur() then
            anim:setPosition(-280,-50)
        else
            anim:setScaleX(-1)
            anim:setPosition(280,-50)
        end
    end
    local panelBuffFace=_uiLayer.panel_our_buff_face
    if buff._target:isEnemy() then
        panelBuffFace=_uiLayer.panel_enemy_buff_face
    end
    local panelBuff=_uiLayer.panel_our_buff
    if buff._target:isEnemy() then
        panelBuff=_uiLayer.panel_enemy_buff
    end
    if buff._config.exist_type==1 then

        panelBuffFace:removeAllChildren()
        local icon=commonUtil.getAnim(buff._config.effect_id)
        icon:PlaySection("s1",true)
        panelBuffFace:addChild(icon)
    elseif buff._config.exist_type==3 then
        local pos=#panelBuff._buffIcons
        local x=25
        local delta=50
        if buff._target:isEnemy() then
            delta=-delta
            x=x*11
        end
        x=x+pos*delta
        local buffIcon={}
        local icon=cc.Sprite:create(string.format("buff/%d.png",buff._config.icon))
        icon:setScale(0.2)
        icon:setPosition(x,0)
        icon:setOpacity(0)
        icon:runAction(cc.FadeIn:create(0.5))
        panelBuff:addChild(icon)
        local labelLev=cc.Label:createWithBMFont("ui/fnt_battle_5.fnt",tostring(buff._lv))
        labelLev:setPosition(x+10,-15)
        panelBuff:addChild(labelLev)
        buffIcon.icon=icon
        buffIcon.labelLev=labelLev
        buffIcon.buff=buff
        table.insert(panelBuff._buffIcons,buffIcon)
    end
end

--BUFF触发特效
function SceneController:onBuffToggleAnim(buff)
    local _uiLayer=self._owner._uiLayer
    local anim=commonUtil.getAnim(buff._config.toggle_id)
    anim:PlaySection("s1", false)
    _uiLayer.panel_center:addChild(anim,35)
    if buff:getTarget():isOur() then
        anim:setPosition(-280,-50)
    else
        anim:setScaleX(-1)
        anim:setPosition(280,-50)
    end
end

function SceneController:onBuffChangeLv(buff)
    local _uiLayer=self._owner._uiLayer
    if buff._config.exist_type==3 then
        local panelBuff=_uiLayer.panel_our_buff
        if buff._target:isEnemy() then
            panelBuff=_uiLayer.panel_enemy_buff
        end
        for _,buffIcon in ipairs(panelBuff._buffIcons) do
            if buff==buffIcon.buff then
                buffIcon.icon:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,0.3),cc.ScaleTo:create(0.1,0.2)))
                buffIcon.labelLev:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,2),cc.ScaleTo:create(0.1,1)))
                buffIcon.labelLev:setString(tostring(buffIcon.buff._lv))
                break
            end
        end
    end
end

function SceneController:onRemoveBuff(buff)
    local _uiLayer=self._owner._uiLayer
    if buff._config.exist_type==1 then
        local panelBuffFace=_uiLayer.panel_our_buff_face
        if buff._target:isEnemy() then
            panelBuffFace=_uiLayer.panel_enemy_buff_face
        end
        panelBuffFace:removeAllChildren()
    elseif buff._config.exist_type==3 then
        local panelBuff=_uiLayer.panel_our_buff
        if buff._target:isEnemy() then
            panelBuff=_uiLayer.panel_enemy_buff
        end
        local pos
        for i,buffIcon in ipairs(panelBuff._buffIcons) do
            if buff==buffIcon.buff then
                pos=i
                break
            end
        end
        local buffIcon=panelBuff._buffIcons[pos]
        local delay=0.2
        buffIcon.icon:runAction(cc.Sequence:create(cc.ScaleTo:create(delay,0.1),cc.RemoveSelf:create()))
        buffIcon.labelLev:removeFromParent()
        if pos==#panelBuff._buffIcons then
            table.remove(panelBuff._buffIcons,pos)
            return
        end
        table.remove(panelBuff._buffIcons,pos)
        performWithDelay(_uiLayer,function()
            local delta=-50
            if buff._target:isEnemy() then
                delta=-delta
            end
            for i=pos,#panelBuff._buffIcons do
                local buffIcon=panelBuff._buffIcons[i]
                buffIcon.icon:runAction(cc.MoveBy:create(0.2,cc.p(delta,0)))
                buffIcon.labelLev:runAction(cc.MoveBy:create(0.2,cc.p(delta,0)))
            end

        end,delay)
    end
end

function SceneController:onShakeScreen()
    local dura=0.05
    local delta=0.01
    self._owner._uiLayer:runAction(cc.Sequence:create(
        cc.MoveBy:create(dura,cc.p(0,-15)),
        cc.MoveBy:create(dura+delta,cc.p(0,30)),
        cc.MoveBy:create(dura+delta,cc.p(0,-15)),
        cc.MoveBy:create(dura+delta,cc.p(0,15)),
        cc.MoveBy:create(dura+delta,cc.p(0,-30)),
        cc.MoveBy:create(dura+delta,cc.p(0,15)),
        cc.MoveBy:create(dura+delta,cc.p(0,-15)),
        cc.MoveBy:create(dura+delta,cc.p(0,30)),
        cc.MoveBy:create(dura+delta,cc.p(0,-15))
    ))
end

return SceneController