
module("particleUtil",package.seeall)

STYLE_SINGLE=1  --单个粒子样式
STYLE_DOUBLE=2  --双向的样式

--------------------------
--创建矩形粒子特效
--@param #style default is STYLE_DOUBLE
--@return #cc.Node
function createRetangle(plist,width,height,style)
    height=height or width
    style=style or STYLE_DOUBLE
    local speed=0.5
    local node=cc.Node:create()
    local particle=cc.ParticleSystemQuad:create(plist)
    particle:setPosition(-width/2,height/2)
    particle:runAction(cc.RepeatForever:create(
        cc.Sequence:create(
            cc.MoveBy:create(speed,cc.p(width,0)),
            cc.MoveBy:create(speed,cc.p(0,-height)),
            cc.MoveBy:create(speed,cc.p(-width,0)),
            cc.MoveBy:create(speed,cc.p(0,height))
        )
    ))
    node:addChild(particle)
    if style==STYLE_DOUBLE then
        particle=cc.ParticleSystemQuad:create(plist)
        particle:setPosition(width/2,-height/2)
        particle:runAction(cc.RepeatForever:create(
            cc.Sequence:create(
                cc.MoveBy:create(speed,cc.p(-width,0)),
                cc.MoveBy:create(speed,cc.p(0,height)),
                cc.MoveBy:create(speed,cc.p(width,0)),
                cc.MoveBy:create(speed,cc.p(0,-height))
            )
        ))
        node:addChild(particle)
    end
    return node
end

--------------------------
--创建圆形粒子特效
--@param #style default is STYLE_DOUBLE
--@return #cc.Node
function createCircle(plist,radius,style)
    style=style or STYLE_DOUBLE
    local speed=0.5
    local node=cc.Node:create()
    local particle=cc.ParticleSystemQuad:create(plist)
    particle:setPosition(-radius/2,radius/2)
    particle:runAction(cc.RepeatForever:create(cc.RotateBy:create(speed,360)))
    node:addChild(particle)
    if style==STYLE_DOUBLE then
        particle=cc.ParticleSystemQuad:create(plist)
        particle:setPosition(radius/2,-radius/2)
        particle:runAction(cc.RepeatForever:create(cc.RotateBy:create(speed,360)))
        node:addChild(particle)
    end
    return node
end

function createParticleToWidget(plist,widget)
    local particle=cc.ParticleSystemQuad:create(plist)
    local size=widget:getContentSize()
    particle:setPosition(size.width/2,size.height/2)
    widget:addChild(particle)
end