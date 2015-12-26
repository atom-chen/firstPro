local ValueHelp={}

--飘血量增加减少数值
function ValueHelp:showValueEffect(target,value,nType,comboCount,comboDelay)
    self:callWithDelay(0.3,function()
        local combo=comboCount or 1
        if combo==0 then combo=1 end
        local quantity=math.floor(value/combo)
        local fmt="+%d"
        local fn=string.format("fonts/fnt_battle_%d.fnt",nType)
        if quantity<0 then
            fmt="%d"
        end
        local dot=1
        for i=1,combo do
            local label=cc.Label:createWithBMFont(fn,string.format(fmt,quantity))
            local delta_x=30
            if target:isEnemy() then
                self._battleScene._uiLayer["panel_enemy_value"..tostring(dot)]:addChild(label)
            else
                delta_x=-30
                self._battleScene._uiLayer["panel_our_value"..tostring(dot)]:addChild(label)
            end
            dot=dot+1
            if dot>3 then
                dot=1
            end
            label:setOpacity(0)
            label:runAction(cc.Sequence:create(
                cc.DelayTime:create((i-1)*comboDelay or 0),
                cc.FadeTo:create(0.1,255),
                cc.EaseBounceOut:create(cc.MoveBy:create(0.3,cc.p(delta_x,80))),
                cc.DelayTime:create(0.32),
                cc.FadeTo:create(0.2,0),
                cc.RemoveSelf:create()
            ))
        end
    end)
end

--显示伤害文本
function ValueHelp:showTextEffect(target,textPath)
    self:callWithDelay(0.3,function()
        local textSprite=cc.Sprite:create(textPath)
        textSprite:setAnchorPoint(1,0.5)
        local delta_x=-30
        if target:isEnemy() then
            self._battleScene._uiLayer.panel_enemy_value1:addChild(textSprite)
        else
            local delta_x=30
            self._battleScene._uiLayer.panel_our_value1:addChild(textSprite)
        end
        textSprite:setPositionX(delta_x)
        textSprite:runAction(cc.Sequence:create(
            cc.MoveBy:create(0.3,cc.p(delta_x,80)),
            cc.DelayTime:create(0.3),
            cc.RemoveSelf:create()
        ))
    end)
end

return ValueHelp