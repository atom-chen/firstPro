--Module require

local fuben_config=require("config/t_chapter_fuben")    --副本表
local team_config=require("config/t_team")              --副本怪物组表
local monster_config=require("config/t_team_monster")   --怪物表

local t_hero=require("src/config/t_hero")

local BaseWidget = require('widget.BaseWidget')

local _touchOrigin      --触摸原始点
local _touchPanel       --当前触摸面板
local _panelOrigin      --触摸面板移动前的坐标
local _bigPanel         --大触摸板

local _panelArray={}        --触摸面板数组

local FormatWidget = class("FormatWidget", function()
    return BaseWidget:new()
end)

function FormatWidget:create(save, opt)
    return FormatWidget.new(save, opt)
end

function FormatWidget:getWidget()
    return self._widget
end

--[[
local opt = {}
opt["format_type"] 攻击/防御
opt["battle_type"] 布阵类型为攻击时，表示战斗类型
opt["chapter"] 章节
opt["id"] 副本编号
--]]
function FormatWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._formatType = opt["format_type"]    --阵型类别，见 Const.FORMATION_TYPE
    self._opt = opt
    self._format = clone(Hero.getFormatByType(self._formatType))    --阵型配置，使用拷贝避免对原值就行修改
    self._curAttr = Const.HERO_ATTR_TYPE.NONE --当前选中什么类型的英雄
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfomation.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    widgetUtil.widgetReader(self._widget)
    
    _bigPanel=self._widget.Panel_3
    self._widget.Panel_3:addTouchEventListener(function(sender, eventType)
        self:onTouchEvent(sender,eventType)
    end)
    
    --上阵英雄模版
    self._formatItemWidget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfomation_item_1.csb")
    self._formatItemWidget:retain()

    --返回
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_close_click", {})
        end
    end)
    
    --确定
    self._widget.btn_ok:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_ok_click", {})
            eventUtil.dispatchCustom("ui_arena_record_def_fight_num", {})
        end
    end)
    
    --开始战斗
    self._widget.btn_fight:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_fight_click", {})
        end
    end)
    
    --所有类型按钮
    self._widget.btn_all:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_all_click", {})
        end
    end)
    
    --水英雄
    self._widget.btn_water:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_water_click", {})
        end
    end)
    
    --火英雄
    self._widget.btn_fire:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_fire_click", {})
        end
    end)
    
    --木英雄
    self._widget.btn_wood:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_format_on_wood_click", {})
        end
    end)
    
    if self._formatType == Const.FORMATION_TYPE.DEFENSE then    --防守
        self._widget.btn_ok:setVisible(true)
        self._widget.btn_fight:setVisible(false)
    elseif self._formatType == Const.FORMATION_TYPE.ATTACK then --攻击
        self._widget.btn_ok:setVisible(false)
        self._widget.btn_fight:setVisible(true)
        
        if opt["battle_type"] == Const.BATTLE_TYPE.PVE then --副本
          
        elseif opt["battle_type"] == Const.BATTLE_TYPE.ROB_HOLLY_CUP then   --掠夺圣杯
        
        elseif opt["battle_type"] == Const.BATTLE_TYPE.ARENA     then         --竞技场
            self.pos = opt["pos"]
        end
    end

    --英雄列表
    local formation_item_widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfomation_item.csb")
    self._list_item = self._widget.list_item
    self._list_item:setItemModel(formation_item_widget)
    --创建英雄列表
    self:updateHeroList()    
    
    for i=1,Const.BATTLE_OBJ_SUM do
        _panelArray[i]=self._widget["panel_formation"..tostring(i)]
        _panelArray[i].pos=i
    end
    
    self:updateFormat()
    self:updateSelfFightNum()  --自己战力
    
    self:selectButton()

end

function FormatWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_format_on_ok_click",function(event)FormatWidget.okClick(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_fight_click",function(event)FormatWidget.startFight(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_close_click",function(event)FormatWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_all_click",function(event)FormatWidget.onAll(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_water_click",function(event)FormatWidget.onWater(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_fire_click",function(event)FormatWidget.onFire(self,event)end)
    eventUtil.addCustom(self._widget,"ui_format_on_wood_click",function(event)FormatWidget.onWood(self,event)end)
end

function FormatWidget:onExit()
    self._formatItemWidget:release()
    eventUtil.removeCustom(self._widget)
end

--退出
function FormatWidget:onClose()
    UIManager.popWidget()
end

--全部属性
function FormatWidget:onAll()
    if self._curAttr ~= Const.HERO_ATTR_TYPE.NONE then
        self._curAttr = Const.HERO_ATTR_TYPE.NONE
        self:updateHeroList()
        self:selectButton()
    end
end

--水属性
function FormatWidget:onWater()
    if self._curAttr ~= Const.HERO_ATTR_TYPE.SHUI then
        self._curAttr = Const.HERO_ATTR_TYPE.SHUI
        self:updateHeroList()
        self:selectButton()
    end
end

--火属性
function FormatWidget:onFire()
    if self._curAttr ~= Const.HERO_ATTR_TYPE.HUO then
        self._curAttr = Const.HERO_ATTR_TYPE.HUO
        self:updateHeroList()
        self:selectButton()
    end
end

--木属性
function FormatWidget:onWood()
    if self._curAttr ~= Const.HERO_ATTR_TYPE.MU then
        self._curAttr = Const.HERO_ATTR_TYPE.MU
        self:updateHeroList()
        self:selectButton()
    end
end

--确定按钮
function FormatWidget:okClick(event)
    self:request("main.formatHandler.arena", {format = self._format}, function(msg)
        if msg['code'] == 200 then
            UIManager.popWidget()
        end
    end)
end

--开始战斗
function FormatWidget:startFight()
    if not self:isHaveFormat() then
        self:showTip("请先布阵！")
        return
    end
    
    local request = clone(self._opt)
    request["format"] = self._format
    
    if self._opt["battle_type"] == Const.BATTLE_TYPE.ARENA then --竞技场
        local user = Arena.getUsersList()
        local userInfo = user[self.pos]
        self:request('arena.arenaHandler.challenge', {uid = userInfo.id, rank = userInfo.rank, format = self._format}, function(msg)
            if msg['code'] ~= 200 then
                if msg['code'] == Const.NET_WORK_ERROR_CODE.ARENA_RANK_CHANGED then --玩家名次已变更，请重新选择
                    widgetUtil.showConfirmBox(Str.RANK_CHANGED, function(msg)
                    eventUtil.dispatchCustom("ui_arena_on_reflesh_fight_click", {})
                    UIManager.popWidget()
                    end)
                end
            else
                UIManager.popWidget(true)
                
                request["token"] = Pvp.getToken()
                request["isPvp"] = true
                UIManager.pushScene('BattleScene', request)
            end
        end)
    elseif self._opt["battle_type"] == Const.BATTLE_TYPE.PVE then --副本
        self:request("copy.copyHandler.challenge", request, function(msg)
            if msg['code'] == 200 then
                UIManager.popWidget(true)
                
                request["token"] = Copy.getToken()
                UIManager.pushScene('BattleScene', request)
            end
        end)
    elseif self._opt["battle_type"] == Const.BATTLE_TYPE.ROB_HOLLY_CUP then --掠夺圣杯
        request["ftype"]= self._pieceId
        request["uid"]= self.uid
        request["isPvp"] = true
        
        self:request("sangreal.sangrealHandler.rob", request, function(msg)
            if msg['code'] == 200 then
                UIManager.popWidget(true)
                
                request["token"] = Pvp.getToken()
                UIManager.pushScene('BattleScene', request)
            end
        end)
    end

end

--阵型
function FormatWidget:updateFormat()
    if self._format == nil then
    	return
    end
    
    for pos=1, Const.BATTLE_OBJ_SUM do
        local heroID = self._format[pos]
        if heroID >= 0 then
            self:updateFormatItem(pos, heroID)
        end
    end
end

--
function FormatWidget:updateFormatItem(pos, heroID)
    local panel = self:getPanelByPos(pos)
    local widget = panel:getChildByName("head")
    if not widget then
        if heroID > 0 then
            widget = self._formatItemWidget:clone()
        else
            widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfomation_item_1.csb")
        end
        widget:setAnchorPoint(cc.p(0.5, 0.5))
        
        widget:setName("head")
        
        local size=panel:getContentSize()
        widget:setPosition(size.width/2,size.height/2)
        
        panel:addChild(widget, 1, 1)
    end

    local item = widget:getChildByName('item')
    
    --创建英雄头像
    local hero = Hero.getHeroByHeroID(heroID)
    self:updateHeroItem(item, hero)
    
end

function FormatWidget:getPosByHeroID(heroID)
    local pos = 0
    for i=1, Const.BATTLE_OBJ_SUM do
        if self._format[i] == heroID then
            pos = i
            break
        end
    end
    assert(pos>0, 'hero not found')

    return pos
end

function FormatWidget:getPanelByHeroID(heroID)
    local pos = self:getPosByHeroID(heroID)
    
    return self:getPanelByPos(pos)
end

function FormatWidget:getPanelByPos(pos)
    
    for _,panel in pairs(_panelArray) do
        if panel.pos==pos then
            return panel
        end
    end
    return nil
end

--更新英雄列表
function FormatWidget:updateHeroList()
    self._list_item:removeAllItems()
    
    local heroList = Hero.getHeroByAttr(self._curAttr)
    
    local row = math.ceil(#heroList / 4)
    for i=1, row do
        self._list_item:pushBackDefaultItem()
    end
    for i=1, row do
        local index = 4 * (i-1)
        local item_widget = self._list_item:getItem(i-1)
        widgetUtil.widgetReader(item_widget)
        
        self:updateHeroItem(item_widget.item_1, heroList[index+1], item_widget.image_battle1, item_widget.image_retreat1)
        self:updateHeroItem(item_widget.item_2, heroList[index+2], item_widget.image_battle2, item_widget.image_retreat2)
        self:updateHeroItem(item_widget.item_3, heroList[index+3], item_widget.image_battle3, item_widget.image_retreat3)
        self:updateHeroItem(item_widget.item_4, heroList[index+4], item_widget.image_battle4, item_widget.image_retreat4)
    end
end

function FormatWidget:updateHeroItem(item, hero, battle, retreat)
    if nil == hero then
        item:setVisible(false)
        if battle and retreat then
            retreat:setVisible(false)
            battle:setVisible(false)
        end
    else
        widgetUtil.widgetReader(item)
        
        widgetUtil.getHeroWeaponQuality(hero._armsLv, item.image_icon_grade, item.image_icon_grade_mark)--品质
        local icon_name = string.format('res/icon/%d.png',hero._heroID)
        item.image_icon:loadTexture(icon_name)     --头像   
        item.label_lv:setString(tostring(hero._lv))--等级

        --星级
        local image_star1 = item.image_star1
        if hero._star <= 1 then
            image_star1:setVisible(true)
        elseif hero._star > 1 then
            image_star1:setVisible(false)
        end
        local image_star2 = item.image_star2
        if hero._star == 2 then
            image_star2:setVisible(true)
        else
            image_star2:setVisible(false)
        end
        local image_star3 = item.image_star3
        if hero._star == 3 then
            image_star3:setVisible(true)
        else
            image_star3:setVisible(false)
        end
        local image_star4 = item.image_star4
        if hero._star == 4 then
            image_star4:setVisible(true)
        else
            image_star4:setVisible(false)
        end
        local image_star5 = item.image_star5
        if hero._star == 5 then
            image_star5:setVisible(true)
        else
            image_star5:setVisible(false)
        end

        --如在阵中，勾选
        local check_box = item.checkbox_item
        if check_box then
            --英雄编号作为标识
            check_box:setTag(hero._heroID)

            local atFormat = self:isAtFormat(hero._heroID)
            if atFormat then
                check_box:setSelectedState(true)
                --check_box:setEnabled(false)
            end
                
            if battle and retreat then
                if atFormat then
                    battle:setVisible(true)
                    retreat:setVisible(false)
                else
                    battle:setVisible(false)
                    retreat:setVisible(true)
                end
            end
            
            local function selectedEvent(sender,eventType)
                if eventType == ccui.CheckBoxEventType.selected then
                    self:goQueue(sender)
                    --sender:setEnabled(false)
                    
                    local heroID = sender:getTag()
                    local atFormat = self:isAtFormat(heroID)
                    if atFormat then
                        retreat:setVisible(false)
                        battle:setVisible(true)
                    end
                elseif eventType == ccui.CheckBoxEventType.unselected then
                    local heroID = sender:getTag()
                    local pos = self:getPosByHeroID(heroID)
                    if pos > 0 then
                        self._format[pos] = -1
                        self:updateSelfFightNum()
                        
                        local panelHero = self:getPanelByPos(pos)
                        panelHero:removeChildByName("head",true)

                        retreat:setVisible(true)
                        battle:setVisible(false)
                    end
                end
            end            
            check_box:addEventListener(selectedEvent)
        else
            local panel = item:getParent()
            --英雄编号作为标识
            panel:setTag(hero._heroID)
           
            local onTouchBegin = function(touch, event)
               return self:onTouchBegin(touch, event)
            end
            
            local onTouchMove = function(touch, event)
                self:onTouchMove(touch, event)
            end
            
            local onTouchEnd = function(touch, event)
                self:onTouchEnd(touch,event)
            end
            
        end
        
    end
end

function FormatWidget:isAtFormat(heroID)
    for i=1, #self._format do
        if heroID == self._format[i] then
            return true
        end
    end    
    return false
end

function FormatWidget:onTouchEvent(sender ,eventType)
    if eventType==ccui.TouchEventType.began then
    
        _touchPanel=nil
        
        self._touchMoved=false
        local pt=_bigPanel:convertToNodeSpace(sender:getTouchBeganPosition())
        for _,panel in pairs(_panelArray) do
            if panel:getChildrenCount()>0 and cc.rectContainsPoint(panel:getBoundingBox(),pt) then
                _touchPanel=panel
                _touchOrigin=pt
                _panelOrigin=cc.p(_touchPanel:getPosition())
                
                _bigPanel:reorderChild(panel,4)
            end
        end
        
    elseif eventType==ccui.TouchEventType.moved then
    
        if _touchPanel then
            local pt=_bigPanel:convertToNodeSpace(sender:getTouchMovePosition())
            if math.abs(cc.pDistanceSQ(pt,_touchOrigin))>1 then
            
                local ptDelta=cc.pSub(pt,_touchOrigin)
                
                _touchPanel:setPosition(cc.pAdd(cc.p(_touchPanel:getPosition()),ptDelta))
                _touchOrigin=pt
                self._touchMoved=true
                
            end
        end
    
    elseif eventType==ccui.TouchEventType.ended then
    
        if _touchPanel==nil then return end
        
        if not self._touchMoved then
        
            if self._format[_touchPanel.pos] == 0 then
                self:showTip(Str.PLAYER_CANNOT_DOWN)
            else
                self._format[_touchPanel.pos]=-1
                _touchPanel:removeChildByName("head",true)
                
                self:updateHeroList()
                self:updateSelfFightNum()
            end
            
            return
        end
        
        local pt=_bigPanel:convertToNodeSpace(sender:getTouchEndPosition())
        local isOutPanel=true
        for _,panel in pairs(_panelArray) do
            if panel~=_touchPanel and cc.rectContainsPoint(panel:getBoundingBox(),cc.pAdd(cc.p(_touchPanel:getPosition()),cc.p(50,50))) then
            
                local newPt=cc.p(panel:getPosition())
                panel:setPosition(_panelOrigin)
                _touchPanel:setPosition(newPt)
                
                self._format[panel.pos],self._format[_touchPanel.pos] = self._format[_touchPanel.pos],self._format[panel.pos]
                
                panel.pos,_touchPanel.pos=_touchPanel.pos,panel.pos
                
                _bigPanel:reorderChild(_touchPanel,3)
                _bigPanel:reorderChild(panel,3)
                
                
                
                isOutPanel=false
                break
            end
        end
        
        if isOutPanel then
            
            _touchPanel:setPosition(_panelOrigin)
            _touchPanel=nil
        end
        
    elseif eventType==ccui.TouchEventType.canceled then
    
        if _touchPanel then
            _touchPanel:setPosition(_panelOrigin)
            _bigPanel:reorderChild(_touchPanel,3)
        end
        
    end
    
end

--英雄上阵
function FormatWidget:goQueue(sender)
    local pos = 0
    for i=1,Const.BATTLE_OBJ_SUM do
        if self._format[i] < 0 then
            pos = i
            break
        end
    end
    --英雄编号
    local heroID = sender:getTag()
    
    if pos == 0 then
        --没有位置
        sender:setSelectedState(false)
    else
        self:updateFormatItem(pos, heroID)
        
        self._format[pos] = heroID
        self:updateSelfFightNum()
    end
end

--更新玩家自己的战斗力
function FormatWidget:updateSelfFightNum()
    local num = 0
    for i=1,Const.BATTLE_OBJ_SUM do
        local heroId = self._format[i]
        if heroId > 0 then
            num = num + Hero.getHeroPower(heroId)
        end
    end
    
    num = num + Character.power
    
    self._widget.label_power:setString(tostring(num))
end

--查询玩家当前有布阵信息,true：有
function FormatWidget:isHaveFormat()
    local format = self._format
    for i=1, #format do
        if format[i] ~= -1 then
            return true
        end
    end
    
    return false
end

--设置当前选中按钮
function FormatWidget:selectButton()
    self._widget.btn_water:setEnabled(true)
    self._widget.btn_water:setBright(true)
    self._widget.btn_fire:setEnabled(true)
    self._widget.btn_fire:setBright(true)
    self._widget.btn_wood:setEnabled(true)
    self._widget.btn_wood:setBright(true)
    self._widget.btn_all:setEnabled(true)
    self._widget.btn_all:setBright(true)
    
    if self._curAttr == Const.HERO_ATTR_TYPE.NONE then
        self._widget.btn_all:setEnabled(false)
        self._widget.btn_all:setBright(false)
    elseif self._curAttr == Const.HERO_ATTR_TYPE.SHUI then
        self._widget.btn_water:setEnabled(false)
        self._widget.btn_water:setBright(false)
    elseif self._curAttr == Const.HERO_ATTR_TYPE.HUO then
        self._widget.btn_fire:setEnabled(false)
        self._widget.btn_fire:setBright(false)
    elseif self._curAttr == Const.HERO_ATTR_TYPE.MU then
        self._widget.btn_wood:setEnabled(false)
        self._widget.btn_wood:setBright(false)
    end
end

return FormatWidget

