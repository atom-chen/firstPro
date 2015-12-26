require "model/Login"

local BaseScene = require "scene/BaseScene"

local MainScene = require "scene/MainScene"

local LoginScene = class("LoginScene", function()
    return BaseScene:new()
end)

function LoginScene:create(save, opt)
    return LoginScene.new(save, opt)
end

function LoginScene:ctor(save, opt)
    commonUtil.playBakGroundMusic(1701)
end

return LoginScene
