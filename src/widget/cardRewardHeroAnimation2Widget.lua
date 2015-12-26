local t_item = require('src/config/t_item')
local t_hero = require('src/config/t_hero')

local BaseWidget = require('widget.BaseWidget')

local CardRewardHeroAnimation2Widget = class("CardRewardHeroAnimation2Widget", function()
    return BaseWidget:new()
end)

function CardRewardHeroAnimation2Widget:create(save, opt)
    return CardRewardHeroAnimation2Widget.new(save, opt)
end

function CardRewardHeroAnimation2Widget:getWidget()
    return self._widget
end

function CardRewardHeroAnimation2Widget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIcard_hero_animation2.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)

    local itemID = opt["itemID"]
    self._bClicked = false

    self._widget:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            if self._bClicked == false then
                self._bClicked = true
                eventUtil.dispatchCustom("ui_CardRewardHeroAnimation2Widget_on_close_click")
                eventUtil.dispatchCustom("ui_cardRewardAnimation_continue_play_item_get")
            end
        end
    end)
    
    for i=1, 5 do
        self._widget["image_star"..i]:setVisible(false)
    end

    local item = t_item[itemID]
    if not item then
        return
    end

    local hero = t_hero[item.reward_hero]
    if not hero then
        return
    end
    
    --名称
    self._widget.label_name:setString(hero.name)
    
    --星级
    local lv = item.xlv
    if lv == 1 then
        self._widget.image_star3:setVisible(true)
    elseif lv == 2 then --
        self._widget.image_star3:setVisible(true)
        self._widget.image_star4:setVisible(true)
        self:setStarPos(self._widget.image_star3)
        self:setStarPos(self._widget.image_star4)
    elseif lv == 3 then
        self._widget.image_star2:setVisible(true)
        self._widget.image_star3:setVisible(true)
        self._widget.image_star4:setVisible(true)
    elseif lv == 4 then --
        self._widget.image_star2:setVisible(true)
        self._widget.image_star3:setVisible(true)
        self._widget.image_star4:setVisible(true)
        self._widget.image_star5:setVisible(true)
        self:setStarPos(self._widget.image_star2)
        self:setStarPos(self._widget.image_star3)
        self:setStarPos(self._widget.image_star4)
        self:setStarPos(self._widget.image_star5)
    elseif lv == 5 then
        self._widget.image_star1:setVisible(true)
        self._widget.image_star2:setVisible(true)
        self._widget.image_star3:setVisible(true)
        self._widget.image_star4:setVisible(true)
        self._widget.image_star5:setVisible(true)
    end
    
    --英雄是否转为魂石
    if item.item == Const.ITEM_TYPE.HERO then
        local find = Hero.isInHeroList(item.reward_hero)
        if find then
            self._widget.label_desc:setVisible(true)
        else
            self._widget.label_desc:setVisible(false)
        end
    end
    
    --特效
    --[[
    local animBegin = commonUtil.getAnim(9003)
    if animBegin then
        animBegin:setPosition(self._widget.Panel_hero_animation:getPosition())
        self._widget.Panel_11:addChild(animBegin, 0)
        animBegin:PlaySection("s1", true)
    end
    ]]
    --胜利动画
    local path = string.format("effect/animation/%d/%d.sam", item.reward_hero, item.reward_hero)
    if cc.FileUtils:getInstance():isFileExist(path) then
        local animWin = commonUtil.getAnim(item.reward_hero)
        if animWin then
            animWin:setPosition(self._widget.Panel_hero_animation:getPosition())
            self._widget.Panel_11:addChild(animWin, 0)
            animWin:PlaySection("s8", true)
        end
    end
end

function CardRewardHeroAnimation2Widget:onEnter()
    eventUtil.addCustom(self._widget,"ui_CardRewardHeroAnimation2Widget_on_close_click",function(event)CardRewardHeroAnimation2Widget.onClose(self,event)end)
end

function CardRewardHeroAnimation2Widget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function CardRewardHeroAnimation2Widget:onClose(event)
    UIManager.popWidget()
end

--设置星星的位置
function CardRewardHeroAnimation2Widget:setStarPos(widget)
    local newP = cc.pSub(cc.p(widget:getPosition()), cc.p(40, 0))
    widget:setPosition(newP)
end

return CardRewardHeroAnimation2Widget