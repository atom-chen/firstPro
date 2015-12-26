
local WeatherController=class("WeatherController",function()
    return cc.Node:create()
end)

function WeatherController:create(owner)
    return WeatherController.new(owner)
end

function WeatherController:ctor(owner)
    self:setName("WeatherController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
end

function WeatherController:randomWeather()
    local ids={1036,1037,1038,1039}
    local id=ids[commonUtil.isProbWithArrayEx({1000,1000,7000,1000})]
    BattleBuffMgr.add_buff(id,self._owner:getOurHero(),self._owner)
end

function WeatherController:onWeatherChange(param)
    local winSize=cc.Director:getInstance():getWinSize()
    local uiLayer=self._owner._uiLayer
    uiLayer.panel_weather:removeChildByTag(0x100)
    uiLayer.panel_weather:removeChildByTag(0x101)
    local buff=param.buff
    if param.weather~=Const.WEATHER.NONE then
        local anim=commonUtil.getAnim(buff._config.effect_id)
        if anim then
            anim:setAnchorPoint(1,1)
            if param.weather~=Const.WEATHER.FOG then 
                anim:setBlendFunc(gl.ONE,gl.ONE)
            end
            anim:PlaySection("s1",true)
            uiLayer.panel_weather:addChild(anim,2,0x101)
        end
    end
    uiLayer.label_num:setString(tostring(buff._round))
    uiLayer.battle_weather_img1:setVisible(false)
    uiLayer.battle_weather_img2:setVisible(false)
    uiLayer.battle_weather_img3:setVisible(false)
    uiLayer.battle_weather_img4:setVisible(false)
    uiLayer.battle_weather_img5:setVisible(false)
    if param.weather==Const.WEATHER.NONE then
        uiLayer.battle_weather_img5:setVisible(true)
    elseif param.weather==Const.WEATHER.SUNNY then
        uiLayer.battle_weather_img1:setVisible(true)
        local layer=cc.LayerColor:create(cc.c4b(255,255,255,255*0.2))
        layer:setPosition(-winSize.width,-winSize.height)
        uiLayer.panel_weather:addChild(layer,1,0x100)
    elseif param.weather==Const.WEATHER.RAIN then
        uiLayer.battle_weather_img2:setVisible(true)
        local layer=cc.LayerColor:create(cc.c4b(0,0,0,255*0.2))
        layer:setPosition(-winSize.width,-winSize.height)
        uiLayer.panel_weather:addChild(layer,1,0x100)
    elseif param.weather==Const.WEATHER.FOG then
        uiLayer.battle_weather_img4:setVisible(true)
    end
end

function WeatherController:onEnter()
    eventUtil.addCustom(self,"on_weather_change",function(event)self:onWeatherChange(event.param)end)
    eventUtil.addCustom(self,"on_random_weather",function(event)self:randomWeather()end)
    eventUtil.addCustom(self,"on_update_weather",function(event)
        self._owner._uiLayer.label_num:setString(tostring(event.param._round))
    end)
end

function WeatherController:onExit()
    eventUtil.removeCustom(self)
end


return WeatherController