module("GameGuide", package.seeall)

--新手指引表格配置数据
local t_guide = require("config/t_guide")
local _guideList = {} --当前和没有面板相关的引导 及 前置ID

--当前显示的面板,名称
local _curShowWidget

--新手引导展示层
local _guideLayer

--服务器保存已触发的新手引导的ID
local _finishStep = {}

--查询某新手引导是否完成
function isFinishGuide(id)
    return _finishStep[id]
end

--新手指引回调
local _guideCallBack = {}
--派遣消息
function dispatchEvent(type, param1, param2)
    local param = clone(Const.GAME_GUIDE_PARAM)
    param["type"] = type
    param["param1"] = param1
    param["param2"] = param2
    Event.notify(Const.EVENT.GUIDE, param)
end

--注册新手指引回调事件
Event.subscribe(_guideCallBack, Const.EVENT.GUIDE, function (param)
    local type = param["type"]
    if Const.GAME_GUIDE_TYPE.REGIST == type then
    	local name = param["param2"]
        _curShowWidget = param["param1"]
        _curShowWidget["name"] = name
        
        _guideList = {}
        for k,v in pairs(t_guide) do
            local panel = tostring(v["panel"])
            if name == panel or "" == panel then
            _guideList[k] = v["preid"] --相关的ID 及对应的前置ID
            end
        end
    elseif Const.GAME_GUIDE_TYPE.NORMAL == type then --打开面板or鼠标点击
        local show = false
        for k,v in pairs(_guideList) do
            local cfg = t_guide[k]
            if cfg["activateType"] == type or cfg["activateType"] == "" then --不填或者0
                --k未完成，且v已完成，弹出显示
                if not isFinishGuide(k) then
                    --if isFinishGuide(cfg["preid"]) then
                    	showGameGuide(k)
                    	show = true
                    	break
                    --end
                end
            end
        end
        
        if not show then
            removeGuideLayer()
        end
    
    elseif Const.GAME_GUIDE_TYPE.LEVEL == type then --满足等级
    
    end
end)

--新手引导展示层onEnter
local function onEnter()
    local winSize=cc.Director:getInstance():getWinSize()
    local guideWidget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIgame_guide.csb")
    _guideLayer._widget = guideWidget
    widgetUtil.widgetReader(_guideLayer._widget)

    guideWidget.Panel_touch:setContentSize(200, 200)
    guideWidget.Panel_touch:setPosition(700, 20)
    guideWidget.Panel_touch:addTouchEventListener(function(sender,eventType)
    
        if eventType == ccui.TouchEventType.ended then
            print("guideWidgetbegan")
           --guideWidget:setTouchEnabled(false)
           --sender:setTouchEnabled(false)
           --eventUtil.dispatchCustom("ui_gameguide_resume_panel_click")
           
           --通知服务器保存完成的ID
           --设置本地完成
           _finishStep[_guideLayer.curID] = _guideLayer.curID
           dispatchEvent(Const.GAME_GUIDE_TYPE.NORMAL)
        end
    end)
    
    local clip = cc.ClippingNode:create()
    clip:setAnchorPoint(0, 0)
    clip:setInverted(true)
    clip:addChild(guideWidget)
    clip:setStencil(guideWidget.Panel_touch)

    _guideLayer:addChild(clip, 1)
    
    --[[
    eventUtil.addCustom(_guideLayer._widget,"ui_gameguide_resume_panel_click",
    function(event)
            guideWidget:setTouchEnabled(true)
            guideWidget.Panel_touch:setTouchEnabled(true)
            print("sssss")
    end)
    ]]
end

--新手引导展示层onExit
local function onExit()
    print("GuideLayerononExit")
    eventUtil.removeCustom(_guideLayer._widget)
    _guideLayer = nil
end

--解析新手引导提示情况
function parseGameGuide(msg)
    --_finishStep
end

--创建新手引导层
function createGuideLayer()
    if _guideLayer then
    	return
    end

    _guideLayer = cc.Layer:create()
    _guideLayer:setAnchorPoint(0, 0)
    _guideLayer:registerScriptHandler(function(event)
        if "enter" == event then
            onEnter()
        elseif "exit" == event then
            onExit()
        end
    end)
    cc.Director:getInstance():getRunningScene():addChild(_guideLayer,0xFFF)
end

--删除新手引导层
function removeGuideLayer()
    if _guideLayer then
        _guideLayer:runAction(cc.RemoveSelf:create())
    end
end

--显示引导
function showGameGuide(id)
    local cfg = t_guide[id]
    createGuideLayer()
    local widgetSub = tostring(cfg["widget"])
    if widgetSub ~= "" then
        local w = _curShowWidget[widgetSub] --控件
        local wParent = w:getParent() --控件的父控件
        local woldPos = cc.p(w:getPosition())
        local wPos = wParent:convertToWorldSpace(woldPos) --控件坐标变换成屏幕坐标
        local nPos = _guideLayer._widget:convertToNodeSpace(wPos) --控件w坐标变换到UIgame_guide.csb里面
        _guideLayer._widget.Panel_touch:setAnchorPoint(cc.p(w:getAnchorPoint()))
        
        --偏移
        local offX,offY = cfg["offsetpos"][1], cfg["offsetpos"][2]
        if offX and offY then
            _guideLayer._widget.Panel_touch:setPosition(cc.pAdd(cc.p(nPos), cc.p(offX, offY)))
        else
            _guideLayer._widget.Panel_touch:setPosition(nPos)
        end
        
        --大小
        local width,height = cfg["size"][1], cfg["size"][2]
        if width and height then
            _guideLayer._widget.Panel_touch:setContentSize(cc.size(width, height))
        else
            _guideLayer._widget.Panel_touch:setContentSize(w:getContentSize())
        end
        
    else --未配置的情况
    
    end
    
    --保存当前显示的引导的ID
    _guideLayer.curID = id
    --[[
    local anim=commonUtil.getAnim(1001)
    anim:PlaySection("s4")
    anim:setPosition(nPos)
    _guideLayer._widget:addChild(anim,1000000)
    ]]
end
