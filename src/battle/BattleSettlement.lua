--[[
*战斗结算界面
*
]]

require "Cocos2d"
require "Cocos2dConstants"

local t_item=require("config/t_item")
local t_hero = require('src/config/t_hero')
local t_lv = require('src/config/t_lv')
local t_music=require("config/t_music")

local BattleSettlementInst

--***********************************************

local BattleSettlement = class("BattleSettlement",function()
    return cc.Layer:create()
end)

function BattleSettlement.create(param)
    return BattleSettlement.new(param)
end

function BattleSettlement:ctor(param)
    BattleSettlementInst=self
    self._bClicked=false
    self:createLayer(param)
end

function BattleSettlement:onEnter()
    
end

function BattleSettlement:onExit()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._scheduleId)
end

function BattleSettlement.tick(dt)
    local self=BattleSettlementInst
    if self._roleExp<=self._roleExpMax then
        self._roleExp=self._roleExp+self._roleExpInc
        self._widget.label_reward_exp_number:setString("+"..tostring(math.floor(self._roleExp)))
    end
    if self._roleExpPercent<=self._roleExpPercentMax then
        self._roleExpPercent=self._roleExpPercent+1
        self._widget.progress_exp:setPercent(self._roleExpPercent)
    end
end

function BattleSettlement:createLayer(param)

    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    --    读取UI文件---------------------------------------
    local winSize = cc.Director:getInstance():getWinSize()
    local widget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIresult.csb")
    widgetUtil.widgetReader(widget)
    self._widget=widget
    self:addChild(widget)
    widget.image_star_1:setVisible(false)
    widget.image_star_2:setVisible(false)
    widget.image_star_3:setVisible(false)
    widget.image_result_win:setVisible(param.isWin)
    widget.image_result_lose:setVisible(not param.isWin)
    widget.image_top:setVisible(param.isWin)
    widget.label_lv:setString(tostring(Character.level))
    local index = 1
    local format = Hero.getFormatByType(Const.FORMATION_TYPE.ATTACK)
    for i=1, #format do
        if format[i] > 0 then
            local hero = Hero.getHeroByHeroID(format[i])
            if hero then
                widgetUtil.getHeroWeaponQuality(hero._armsLv,widget["image_hero"..index.."_bottom"],widget["image_hero"..index.."_grade"])
                local icon = string.format('icon/%d.png', hero._heroID)
                widget["image_hero"..index]:loadTexture(icon)
                widget["label_hero"..index.."_lv"]:setString(tostring(hero._lv))
                widget["label_hero"..index.."_exp"]:setString("+"..tostring(param.heroExp))
                if not hero._exp then
                    print("error","BattleSettlement -> hero._exp was nil.")
                end
                widget["progress_hero"..index.."_lv"]:setPercent((hero._exp or 0)/t_lv[hero._lv].hero_up_exp*100)
                index = index + 1
            end
        end
    end
    for i=index, 4 do
        widget["image_hero"..i.."_bottom"]:setVisible(false)
    end

    if param.items then
        for index=1, #param.items do
            local itemID = param.items[index]["itemID"]
            local num = param.items[index]["num"]
            local itemConfig=t_item[itemID]
            local icon = string.format('icon/%d.png', itemConfig.icon)
            local itemWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIresult_item.csb")
            widgetUtil.widgetReader(itemWidget)
            itemWidget.label_num:setString(tostring(num))
            itemWidget.image_icon:loadTexture(icon)
            widget.list_item:pushBackCustomItem(itemWidget)
            widgetUtil.getItemQuality(itemConfig.grade,itemWidget["image_icon_bottom"],itemWidget["image_icon_grade"])
        end
    end
    self._roleExp=0
    self._roleExpMax=param.exp
    self._roleExpInc=param.exp/50
    self._roleExpPercent=0
    self._roleExpPercentMax=Character.exp/Character.getMaxExp()*100
    
    local scale=1.0
    if winSize.width/winSize.height <1.4 then
        scale=0.86
    end
    widget.bg:setScale(0.5)
    local act1=cc.EaseOut:create(cc.ScaleTo:create(0.5,scale),0.3)
    widget.bg:runAction(cc.Sequence:create(act1,cc.CallFunc:create(function()
        widget:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                if self._bClicked == false then
                    self._bClicked=true
                    performWithDelay(self,function()
                        self._bClicked=false
                    end,2)
                    UIManager.popScene()
                end
            end
        end)
        
        self._scheduleId=cc.Director:getInstance():getScheduler():scheduleScriptFunc(BattleSettlement.tick,0,false)
        --
        if param.isWin then
            commonUtil.playEffect(t_music[1400].path)
            widget.image_top:runAction(cc.RepeatForever:create(cc.RotateBy:create(1,180)))
            for i=1,param.rate do
                local starSpr=widget["image_star_"..tostring(i)]
                starSpr:setVisible(true)
                starSpr:setScale(10)
                starSpr:setOpacity(0)
                starSpr:setRotation(90)
                local act=cc.Spawn:create(cc.ScaleTo:create(0.3,1),
                    cc.FadeTo:create(0.3,255),
                    cc.RotateTo:create(0.3,0))
                starSpr:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.35-0.35),act))

            end
        else
            commonUtil.playEffect(t_music[1410].path)
        end

    end)))
    
end

return BattleSettlement
