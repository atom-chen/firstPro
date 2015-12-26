local t_music=require("config/t_music")

local AudioController=class("AudioController",function()
    return cc.Node:create()
end)

function AudioController:create(owner)
    return AudioController.new(owner)
end

function AudioController:ctor(owner)
    self:setName("AudioController")
    self._owner=owner
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

end

function AudioController:onEnter()
    commonUtil.preloadEffect(t_music[1400].path)
    commonUtil.preloadEffect(t_music[1410].path)
end

function AudioController:onExit()
    commonUtil.unloadEffect(t_music[1400].path)
    commonUtil.unloadEffect(t_music[1410].path)
end

return AudioController