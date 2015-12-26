module("UIManager", package.seeall)

SCHE_SCENE  = 1
SCHE_WIDGET = 2

ScheProperty = {
    _name   = '',       --场景或界面标识名称
    _save   = nil,      --需保存用于恢复的数据
    _type   = 0,        --场景或界面(SCHE_SCENE,SCHE_WIDGET)
    _instance = nil,    --实例对象
    _show   = false,    --是否显示
    _zOrder = 1         --UI层次
}

SaveProperty = {
    _scene  = nil,
    _save   = nil
}

local _ScheList = {}

local _lookup = function(name)
    for i=#_ScheList, -1 do
        if _ScheList[i]._name == name then
            return 
        end
    end
end

local _saveLastScene = function()
    for i=#_ScheList,1,-1 do
        if _ScheList[i]._instance then
            if _ScheList[i]._instance.onSave then
                _ScheList[i]._save = _ScheList[i]._instance:onSave()
            end
            
            _ScheList[i]._instance:unsubscribeAll()
            _ScheList[i]._instance = nil
        end

        if _ScheList[i]._type == SCHE_SCENE then
            break
        end
    end
end

local _saveLastWidget = function()
    if #_ScheList == 0 then
        return
    end
    
    local index = #_ScheList
    
    if _ScheList[index]._type ~= SCHE_WIDGET then
        return
    end

    if not _ScheList[index]._instance then
        return
    end
    
    if _ScheList[index]._instance.onSave then
        _ScheList[index]._save = _ScheList[index]._instance:onSave()
    end
    
    _ScheList[index]._instance:unsubscribeAll()
    _ScheList[index]._instance = nil
end

local _getLastScene = function()
    for i=#_ScheList,1,-1 do
        if _ScheList[i]._type == SCHE_SCENE then
            return _ScheList[i]._instance
        end
    end
    --assert(false, 'last scene not found:')
    return nil
end

local _removeLastScene = function()
    while 1 do
        local sche = table.remove(_ScheList)
        if sche then
            if sche._instance then
                sche._instance:unsubscribeAll()
                sche._instance = nil
            end            
            
            if sche._type==SCHE_SCENE then
                break
            end
        else
            break
        end
    end
end

local _getLastWidgetSche = function()
    if #_ScheList > 0 then
        if _ScheList[#_ScheList]._type == SCHE_WIDGET then
            return _ScheList[#_ScheList]
        end
    end
    return nil
end

local _getLastWidget = function()
    for i=#_ScheList,1,-1 do
        if _ScheList[i]._type == SCHE_WIDGET then
            return _ScheList[i]._instance
        elseif _ScheList[i]._type == SCHE_SCENE then
            return nil
        end
    end
    --assert(false, 'last widget not found')
    return nil
end

local _creator = function(name)
    local widgetTable = require('UITable')
    local creator = require(widgetTable[name])
    --assert(creator, 'creator not found:' .. name)
    return creator
end

local cleanUnusedObj = function(delay)
    local scheduler = cc.Director:getInstance():getScheduler()
    local entry = nil
    local clean = function(dt)
        cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
        cc.Director:getInstance():getTextureCache():removeUnusedTextures()

        scheduler:unscheduleScriptEntry(entry)
    end
    entry = scheduler:scheduleScriptFunc(clean, delay, false)
end

local cleanWidget = function(widget, scene)
    
    local scheduler = cc.Director:getInstance():getScheduler()
    local entry = nil
    local clean = function(dt)
        if scene == _getLastScene() then
            widget:removeFromParent()
        end      
        
        scheduler:unscheduleScriptEntry(entry)

        cleanUnusedObj(3.0)
    end
    entry = scheduler:scheduleScriptFunc(clean, 1.0, false)
end

function pushScene(name, opt)
    _saveLastScene()
    
    local creator = _creator(name)
    local scene = creator:create(nil, opt)
    
    local sche = clone(ScheProperty)
    sche._name = name
    sche._type = SCHE_SCENE
    sche._instance = scene
    table.insert(_ScheList, sche)
    
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(scene)
    else
        cc.Director:getInstance():runWithScene(scene)
    end

    cleanUnusedObj(3.0)
end

function popScene()
    --当前场景
    local scene = _getLastScene()
    if not scene then
        return
    end
    
    _removeLastScene()
    
    --重建新场景
    local pos = 0
    for i=#_ScheList, 1, -1 do
        if _ScheList[i]._type == SCHE_SCENE then
            pos = i
            break
        end
    end
    
    if pos == 0 then    --前一场景为空
        cc.Director:getInstance():popScene()
    else
        --重建场景
        local save = clone(SaveProperty)
        save._scene = nil
        save._save = _ScheList[pos]._save
        
        local creator = _creator(_ScheList[pos]._name)
        local scene = creator:create(save, nil)
        
        _ScheList[pos]._instance = scene
        
        --重建界面
        for i=pos+1, #_ScheList do
            local save = clone(SaveProperty)
            save._scene = scene
            save._save = _ScheList[i]._save
            
            if _ScheList[i]._show then --最后一个widget显示，或者手动需要显示的
                local creator = _creator(_ScheList[i]._name)
                local widget = creator:create(save, nil)
                
                _ScheList[i]._instance = widget
                
                scene:addChild(widget:getWidget(), _ScheList[i]._zOrder)

                if i==#_ScheList and widget.onResume then
                    widget:onResume()
                end
            end

            scene:_pushWidget(_ScheList[i])
        end
        
        if scene.onResume then
            scene:onResume()
        end
        
        cc.Director:getInstance():replaceScene(scene)
    end

    cleanUnusedObj(3.0)
end

function replaceScene(name, opt)
    local creator = _creator(name)
    local scene = creator:create(nil, opt)
    
    _removeLastScene()
    
    local sche = clone(ScheProperty)
    sche._name = name
    sche._type = SCHE_SCENE
    sche._instance = scene
    table.insert(_ScheList, sche)
    
    cc.Director:getInstance():replaceScene(scene)
    
    cleanUnusedObj(3.0)
end

function pushWidget(name, opt, show)
    local scene = _getLastScene()
    local save = clone(SaveProperty)
    save._scene = scene
    
    local zOrder = 1
    local _sche_last = _getLastWidgetSche()
    if _sche_last then
        zOrder = _sche_last._zOrder + 1
        if not show then
            _sche_last._show = false
            
            local widget = _sche_last._instance:getWidget()
            if widget then
                widget:setVisible(false)
                _saveLastWidget()
                cleanWidget(widget, scene)
            end
        end
    end
    
    local creator = _creator(name)
    local widget = creator:create(save, opt)
    
    local sche = clone(ScheProperty)
    sche._name = name
    sche._type = SCHE_WIDGET
    sche._instance = widget
    sche._zOrder = zOrder
    sche._show = true
    table.insert(_ScheList, sche)
    
    scene:_pushWidget(sche)
    
    scene:addChild(widget:getWidget(), sche._zOrder)
end

function popWidget(idle)
    local scene = _getLastScene()
    
    if _ScheList[#_ScheList]._type == SCHE_WIDGET then
        local sche = table.remove(_ScheList)
        sche._instance:unsubscribeAll()
        local widget = sche._instance:getWidget()
        widget:setVisible(false)
        
        scene:_popWidget()
        
        cleanWidget(widget, scene)
    end
    
    local sche = _ScheList[#_ScheList]
    if sche._type == SCHE_WIDGET then
        sche._show = true

        if idle then
            return
        end

        local widget = nil
        if nil == sche._instance then
            --重建上一个窗体
            local save = clone(SaveProperty)
            save._scene = scene
            save._save = sche._save
            
            local creator = _creator(sche._name)
            widget = creator:create(save, nil)
            
            sche._instance = widget
            
            scene:addChild(widget:getWidget(), sche._zOrder)
        else
            widget = sche._instance
            widget:getWidget():setVisible(true)
        end
        
        if widget.onResume then
            widget:onResume()
        end
    end
end

function replaceWidget(name, opt)
    
end

--清空所有的面板
function clearAllWidget()
    --[[
    while 1 do
        local sche = table.remove(_ScheList) 
        if sche then
            if sche._type == SCHE_WIDGET then --控件
                local scene = _getLastScene()
                scene:_popWidget()
                if sche._instance then
                    sche._instance:unsubscribeAll()
                    local widget = sche._instance:getWidget()
                    widget:setVisible(false)
                    cleanWidget(widget, scene)
                    sche._instance = nil
                end
            elseif sche._type == SCHE_SCENE then --场景
                if sche._instance then
                    sche._instance:unsubscribeAll()
                    sche._instance = nil
                end    
            end
        else
            cc.Director:getInstance():popScene()
            break
        end
    end
    --]]
end
