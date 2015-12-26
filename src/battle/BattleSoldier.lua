--[[
*士兵
*
]]

local SRun=1
local SIdle=2
local SAttack=3
local SDead=4

local property={
    _sprite=nil,
    _pos=0,                    --站位
    _state=SIdle,              --状态
    _arm=1,                    --兵种
}

local BattleSoldier = class("BattleSoldier",property)

-------------------------
--构造函数
--@param #cc.p pos 位置，二维坐标
function BattleSoldier:ctor(sId,pos,isEnemy)
    self._pos=pos
    self._isEnemy=isEnemy
    self._sprite=cc.Sprite:create(string.format("soldier/%d.png",sId))
    self._sprite:setPosition(self:getPointByPos(pos,isEnemy))
    self._scale=0.9
    self._sprite:setScale(self._scale)
    if isEnemy then
        self._sprite:setScaleX(-self._scale)
    end
    self._arm=1
    self:setIdleState(SIdle)

end
-------------------------
--设置状态
function BattleSoldier:setState(state,unRepeat)
    self._state=state
    
end
-------------------------
--死亡
--@param isFlyout 是否弹飞出屏幕
function BattleSoldier:goingToDie(isFlyout)
    self:flyout()
    self:setDeadState()
    local delay=1.1
    self._sprite:runAction(cc.Sequence:create(cc.DelayTime:create(delay),cc.RemoveSelf:create()))
    
end

-------------------------
--弹飞
function BattleSoldier:flyout()
    local m_x=-700
    local r_x=-359
    if self._isEnemy then
        m_x=700
        r_x=359
    end
    self._sprite:stopAllActions()
    local bezier = {
        cc.p(0,0),
        cc.p(m_x/10,200),
        cc.p(m_x,200),
    }
    local act2=cc.Spawn:create(
        cc.FadeTo:create(0.8,100),
        cc.BezierBy:create(0.6,bezier),
        cc.RotateBy:create(0.4,r_x)
    )
    self._sprite:runAction(cc.Sequence:create(cc.MoveBy:create(0.2,cc.p(0,-10)),act2))
end

-------------------------
--根据位置获得坐标
--@return #cc.p 坐标
function BattleSoldier:getPointByPos(pos,isEnemy)
    local x=-540
    local offset_x=40
    if isEnemy then
        x=240
        offset_x=-40 
    end
    return cc.p(pos.x*75+x+pos.y*offset_x,90-pos.y*55)
end

function BattleSoldier:strike(delay,duration)
    if self._arm==1 then
        self._sprite:stopAllActions()
        self._sprite:setPosition(self:getPointByPos(self._pos,self._isEnemy))
        local offset_x=600
        if self._isEnemy then
            offset_x=-480
        end
        local act1=cc.MoveBy:create(duration,cc.p(offset_x-self._pos.x*70,0))
        local act2=act1:reverse()
        local actScale1=cc.ScaleTo:create(0,-self._scale,self._scale)
        local actScale2=cc.ScaleTo:create(0,self._scale,self._scale)
        if self._isEnemy then
            actScale1,actScale2=actScale2,actScale1
        end
        self._sprite:runAction(cc.Sequence:create(act1,cc.DelayTime:create(delay),actScale1,act2,actScale2,cc.CallFunc:create(function()
            self:setIdleState()
        end)))
    end
    
end

function BattleSoldier:setRunState()
    self:setState(SRun)
end

function BattleSoldier:setIdleState()
    self:setState(SIdle)
    performWithDelay(self._sprite,function()
        local act1=cc.MoveBy:create(0.3,cc.p(0,5))
        local act2=act1:reverse()
        local movement=cc.RepeatForever:create(cc.Sequence:create(act1,act2))
        self._sprite:runAction(movement)
    end,self._pos.x*0.1-0.1)
end

function BattleSoldier:setAttackState()
    self:setState(SAttack)
end

function BattleSoldier:setDeadState()
    self:setState(SDead,true)
end

function BattleSoldier:isDead()
    return self._state==SDead
end

return BattleSoldier