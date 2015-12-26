
local SkillHelp={}
local t_skill=require("config/t_skill")

--显示技能名字
function SkillHelp:showSkillName(skillId)
    self:callWithDelay(0.3,function()
        local skillConf=t_skill[skillId]
        local uiLayer=self._battleScene._uiLayer
        uiLayer.panel_skill:setVisible(true)
        uiLayer.img_our_skill:setVisible(self:isOur())
        uiLayer.img_enemy_skill:setVisible(not self:isOur())

        uiLayer.label_skill1:setString(skillConf.name)
        uiLayer.label_skill2:setString(skillConf.name)
        uiLayer.label_skill3:setString(skillConf.name)

        uiLayer.panel_skill:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.Hide:create()))
    end)
end

--显示技能名字2
function SkillHelp:showSkillName2(skillId)
    self:callWithDelay(0.3,function()
        local skillConf=t_skill[skillId]
        local uiLayer=self._battleScene._uiLayer
        local anim=commonUtil.getAnim(3010)
        local s={
            [5]="s1",
            [6]="s2",
            [7]="s3",
            [8]="s4",
        }
        anim:PlaySection(s[skillConf.type],false)
        anim:setPosition(50,-50)
        uiLayer.panel_skill:addChild(anim)
    end)
end

--显示技能立绘
function SkillHelp:showSkillDrawing(skillType)
    local winSize=cc.Director:getInstance():getWinSize()
    local layer=cc.LayerColor:create(cc.c4b(0,0,0,220))
    local anim=commonUtil.getAnim(3004)
    anim:PlaySection("s1",false)
    anim:setPosition(winSize.width/2,winSize.height/2)
    layer:addChild(anim,5)
    local heroImg=cc.Sprite:create(string.format("img/%d.png",self._img))
    if heroImg then
        heroImg:setPosition(winSize.width/2,winSize.height/2-30)
        --heroImg:setOpacity(0)
        heroImg:setScale(0.8)
        local act1=cc.Spawn:create(cc.FadeTo:create(0.5,255),
            cc.MoveBy:create(0.3,cc.p(-10,0)))
        local act2=cc.MoveBy:create(0.3,cc.p(-20,0))   
        local act3=cc.Spawn:create(cc.FadeTo:create(0.5,0),
            cc.MoveBy:create(0.3,cc.p(-10,0)))
        --heroImg:runAction(cc.Sequence:create(act3))
        layer:addChild(heroImg,25)
    end
--    local nameSprite=cc.Sprite:create(string.format("skill_name/%d.png",self._skills[skillType][1]))
--    if nameSprite then
--        nameSprite:setPosition(winSize.width/2+50,winSize.height/2)
--        nameSprite:setScale(3)
--        nameSprite:runAction(cc.ScaleTo:create(0.4,0.8))
--        layer:addChild(nameSprite,30)
--    end

--    local mask1=cc.LayerColor:create(cc.c4b(0,0,0,255),winSize.width,70)
--    local mask2=cc.LayerColor:create(cc.c4b(0,0,0,255),winSize.width,70)
--
--    mask1:setPosition(0,570)
--    mask2:setPosition(0,0)
--    layer:addChild(mask1,20)
--    layer:addChild(mask2,21)

    layer:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.RemoveSelf:create()))
    self._battleScene._uiLayer:addChild(layer,0xffff)
end

function SkillHelp:createBlackLayer()
    local layer=cc.LayerColor:create(cc.c4b(0,0,0,0))
    local winSize=cc.Director:getInstance():getWinSize()
    layer:setPosition(-winSize.width*0.5,-winSize.height*0.5)
    layer:runAction(cc.FadeTo:create(0.2,150))
    self._battleScene._uiLayer.panel_center:addChild(layer,59)
    self._blackLayer=layer
end

function SkillHelp:removeBlackLayer()

    if self._blackLayer then
        self._blackLayer:runAction(cc.Sequence:create(cc.FadeTo:create(0.2,0),cc.RemoveSelf:create()))
        self._blackLayer=nil
    end

end

--获取技能类型
function SkillHelp:getSkillType(skillType)
    local skillId=self._skills[skillType][1]
    return t_skill[skillId].type
end

--显示怒气技能的珠子连击
function SkillHelp:showBallCombo(delay,num)
    for i=1,num do
        local sprCombo=cc.Sprite:create("common/battle_combo.png")
        local size=sprCombo:getContentSize()
        local sprNum=cc.Sprite:create(string.format("common/battle_combo%d.png",i))
        sprNum:setAnchorPoint(0,0)
        sprNum:setPositionX(size.width)
        sprCombo:setAnchorPoint(0,0)
        sprCombo:addChild(sprNum)
        sprCombo:setVisible(false)
        sprCombo:runAction(cc.Sequence:create(
            cc.DelayTime:create(delay),
            cc.Show:create(),
            cc.DelayTime:create(0.2),
            cc.RemoveSelf:create()
        ))
        sprNum:runAction(cc.Sequence:create(
            cc.DelayTime:create(delay),
            cc.EaseBounceOut:create(cc.ScaleBy:create(0.2,1.5))
        ))
        if self:isOur() then
            sprCombo:setPosition(-470,-20)
        else
            sprCombo:setPosition(180,-20)
        end
        self._battleScene._uiLayer.panel_center:addChild(sprCombo,0xFFFFF)
        delay=delay+0.15
    end
    return delay+0.2
end

return SkillHelp