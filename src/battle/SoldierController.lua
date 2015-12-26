local BattleSoldier=require("battle/BattleSoldier")

local SoldierController=class("BattleSoldierController",function()
    return cc.Node:create()
end)

function SoldierController:create(owner)
    return SoldierController.new(owner)
end

function SoldierController:ctor(owner)
    self:setName("SoldierController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function SoldierController:onEnter()
    eventUtil.addCustom(self,"on_soldier_strike",function(event)self:onSoldierStrike(event.param)end)
    eventUtil.addCustom(self,"on_incr_soldier",function(event)self:onIncrSoldier(event.param)end)
    eventUtil.addCustom(self,"on_decr_soldier",function(event)self:onDecrSoldier(event.param)end)
    self:createSoldiers()
end

function SoldierController:onExit()
    eventUtil.removeCustom(self)
end

function SoldierController:onIncrSoldier(hero)
    if hero~=self._owner then return end
    local total=Const.SOLDIER_ROW_SUM*Const.SOLDIER_COL_SUM
    local amount=self:getSoldierAmount()
    local count=math.ceil(hero._hp_up_v/(hero:getMaxHp()/total))-amount
    if (count+amount)>total then
        count=total-amount
    end
    for i=1,count do
        local pos=self:pickOneEmpty()
        if pos~=nil then
            self:createSoldierWithPos(pos[1],pos[2])
            self._soldiers[pos[1]][pos[2]]:setIdleState()
        end
    end
end

function SoldierController:onDecrSoldier(hero)
    if hero~=self._owner then return end
    local total=Const.SOLDIER_ROW_SUM*Const.SOLDIER_COL_SUM
    local count=self:getSoldierAmount()-math.ceil(hero:getHp()/(hero:getMaxHp()/total))
    local soldiers={}
    for i=1,count do
        table.insert(soldiers,self:pickOneSoldier(soldiers))
    end
    for _,soldier in ipairs(soldiers) do
        soldier:goingToDie(isFlyout)
        self._soldiers[soldier._pos.x][soldier._pos.y]=nil
    end
end

function SoldierController:createSoldiers()
    local hero=self._owner
    self._soldiers={}
    for i=1,Const.SOLDIER_ROW_SUM do
        self._soldiers[i]={}
        for j=1,Const.SOLDIER_COL_SUM do
            self:createSoldierWithPos(i,j)
            local soldier=self._soldiers[i][j]
            if hero:isOur() then
                soldier._sprite:setPositionX(soldier._sprite:getPositionX()-480)
                soldier._sprite:runAction(cc.MoveBy:create(0.4,cc.p(480,0)))
            else
                soldier._sprite:setPositionX(soldier._sprite:getPositionX()+480)
                soldier._sprite:runAction(cc.MoveBy:create(0.4,cc.p(-480,0)))
            end
        end
    end

end

function SoldierController:createSoldierWithPos(x,y)
    local hero=self._owner
    local pos=cc.p(x,y)
    local soldier=BattleSoldier.new(hero._soldierId,pos,hero:isEnemy())
    hero._battleScene._uiLayer.panel_center:addChild(soldier._sprite,y*12)
    self._soldiers[x][y]=soldier
end

function SoldierController:getSoldierAmount()
    local amount=0
    for i=1,Const.SOLDIER_ROW_SUM do
        for j=1,Const.SOLDIER_COL_SUM do
            local soldier=self._soldiers[i][j]
            if soldier~=nil and not soldier:isDead() then
                amount=amount+1
            end
        end
    end
    return amount
end

function SoldierController:pickOneEmpty()
    local temp={}
    for i=1,Const.SOLDIER_ROW_SUM do
        for j=1,Const.SOLDIER_COL_SUM do
            local soldier=self._soldiers[i][j]
            if soldier==nil then
                table.insert(temp,{i,j})
            elseif soldier:isDead() then
                table.insert(temp,{i,j})
            end
        end
    end
    return temp[math.random(#temp)]
end

function SoldierController:pickOneSoldier(filter)
    local temp={}
    for i=1,Const.SOLDIER_ROW_SUM do
        for j=1,Const.SOLDIER_COL_SUM do
            local soldier=self._soldiers[i][j]
            if soldier and not soldier:isDead() then
                local bFilter=false
                for _,s in ipairs(filter) do
                    if s==soldier then
                        bFilter=true
                        break
                    end
                end
                if not bFilter then
                    table.insert(temp,soldier)
                end
            end
        end
    end
    return temp[math.random(#temp)]
end

function SoldierController:onSoldierStrike(hero)
    if hero~=self._owner then return end
    local delay=0.9
    local duration=0.4
    for x=3,1,-1 do
        local isInc=false
        for y=1,3 do
            local soldier=self._soldiers[x][y]
            if soldier then
                isInc=true
                soldier:strike(delay,duration)
            end
        end
        if isInc then
            delay=delay-0.2
        end
    end

    performWithDelay(self,function()
        local hero=self._owner
        local anim=commonUtil.getAnim(3002)
        if anim then
            anim:PlaySection("s1",false)
            if hero:getTarget():isOur() then
                anim:setPosition(-250,50)
            else
                anim:setPosition(250,50)
            end
            hero._battleScene._uiLayer.panel_center:addChild(anim,3002,0xffff)
        end
    end,duration)
end

return SoldierController