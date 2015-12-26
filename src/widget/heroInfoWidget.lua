--[[
*          英雄信息界面
*
]]

local BaseWidget = require('widget.BaseWidget')

local HeroInfoWidget = class("HeroInfoWidget", function()
    return BaseWidget:new()
end)

function HeroInfoWidget:create(save, opt)
    return HeroInfoWidget.new(save, opt)
end

function HeroInfoWidget:getWidget()
    return self._widget
end

function HeroInfoWidget:ctor(save,id)
    self:setScene(save._scene)    
    
    self.heroInList=Hero.getHeroByHeroID(id)   --获得已招募列表里的英雄
    self.tHero = Hero.getTHeroByKey(self.heroInList._heroID)  --获得配置里的英雄
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_infor.csb")
    widgetUtil.widgetReader(self._widget)
    
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    self._widget:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.popWidget()
        end
    end) 
    
    self:heroInfo()
end

function HeroInfoWidget:heroInfo()
    local widget=self._widget
    
    local bg_hero_img = string.format('img/%d.png',self.tHero.img)
    if cc.FileUtils:getInstance():isFileExist(bg_hero_img) then
        widget.image_hero:loadTexture(bg_hero_img)  --大图
    end
    
    widget.label_title:setString(tostring(self.tHero.title)) 
    widget.label_name:setString(tostring(self.tHero.name)) 
    widget.label_desc:setString(tostring(self.tHero.desc1)) 
    
    local image_attr = Hero.getAttrIcon(self.heroInList._attr)
    --属性图标
    widget.image_ball:loadTexture(image_attr) 
    
    local abilitys=Hero.getHeroAbility(self.heroInList._heroID)
    
    widget.label_power:setString(tostring(abilitys.atk)) 
    widget.label_atk:setString(tostring(abilitys.atk)) 
    widget.label_hp:setString(tostring(abilitys.hp)) 
    widget.label_def_water:setString(tostring(abilitys.water)) 
    widget.label_def_fire:setString(tostring(abilitys.fire)) 
    widget.label_def_wood:setString(tostring(abilitys.wood)) 
    widget.label_crit_rate:setString(tostring(abilitys.critRate)) 
    widget.label_crit:setString(tostring(abilitys.crit)) 
    widget.label_cure:setString(tostring(abilitys.cure)) 
end

function HeroInfoWidget:onEnter()

end

function HeroInfoWidget:onExit()

end
return HeroInfoWidget