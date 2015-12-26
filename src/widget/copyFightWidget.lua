local t_item = require('config/t_item')
local t_chapter = require('config/t_chapter')
local t_chapter_fuben = require('config/t_chapter_fuben')
local team_config=require("config/t_team")              --副本怪物组表
local monster_config=require("config/t_team_monster")   --怪物表

local BaseWidget = require('widget.BaseWidget')

local copyFightWidget = class("copyFightWidget", function()
    return BaseWidget:new()
end)

function copyFightWidget:create(save, opt)
    return copyFightWidget.new(save, opt)
end

function copyFightWidget:getWidget()
    return self._widget
end

function copyFightWidget:onSave()
    local save = {}
    save["chapterID"] = self._ChapterID
    save["copyID"] = self._CopyID
    return save
end

function copyFightWidget:ctor(save, opt)
    self:setScene(save._scene)
    
    if save._save then
        self._ChapterID = save._save["chapterID"]
        self._CopyID = save._save["copyID"]
    else
        self._ChapterID = opt["chapterID"]
        self._CopyID = opt["copyID"]
    end

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIfuben_fight.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)

    widgetUtil.widgetReader(self._widget)

    --退出按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copyFightWidget_on_close_click")
        end
    end)

    --战斗按钮
    self._widget.btn_fight:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copyFightWidget_on_fight_click")
        end
    end)
    
    --快速战斗按钮
    self._widget.btn_sweep:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_copyFightWidget_on_sweep_click")
        end
    end)
    
    local chapter = t_chapter[self._ChapterID]

    local cfg = t_chapter_fuben[self._ChapterID][self._CopyID]
    if cfg then
        self._widget.label_chapter:setString(cfg["name"])--章节名
        self._widget.label_desc:setString(cfg["desc"])--描述信息
    end

    
    --设置几个星通关
    self:setStartNum()
    
    --敌方怪物
    self:showEnemyInfo()
    
    --更新掉落的物品
    self:updateItemInfo()
    
    --通关券
    self._widget.label_point_num:setString(tostring(Item.getNum(Const.ITEM.COPY_PERMIT)))
end

function copyFightWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_copyFightWidget_on_close_click",function(event)copyFightWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copyFightWidget_on_fight_click",function(event)copyFightWidget.onFight(self,event)end)
    eventUtil.addCustom(self._widget,"ui_copyFightWidget_on_sweep_click",function(event)copyFightWidget.onSweep(self,event)end)
end

function copyFightWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function copyFightWidget:onClose(event)
    UIManager.popWidget()
end

--战斗按钮
function copyFightWidget:onFight(event)
    UIManager.popWidget(true)

    local opt = {}
    opt["format_type"] = Const.FORMATION_TYPE.ATTACK
    opt["battle_type"] = Const.BATTLE_TYPE.PVE
    opt["chapter"] = self._ChapterID
    opt["id"] = self._CopyID
    opt["token"] = Copy.getToken()

    UIManager.pushWidget("formatWidget", opt)
    
    --[[
    local data={}
    data.chapter = self._ChapterID
    data.id = self._CopyID
    data.star=3
    data.token=""
    data.report=""
    self:request("copy.copyHandler.report",data,function(msg)
        if msg['code'] == 200 then
            self:showTip("成功")
        end
    end)
    ]] 
end

--快速战斗按钮
function copyFightWidget:onSweep(event)
    local cfg = t_chapter_fuben[self._ChapterID][self._CopyID]
    if cfg["type"] == Const.COPY_TYPE.HP_BOSS  then
        self:showTip("BOSS副本不能进行快速战斗哦！")
        return
    end
    
    if cfg["type"] == Const.COPY_TYPE.SMALL_FIGHT  then
        --self:showTip("只有星级副本才可以进行快速战斗哦！")
        return
    end
    
    local star = Copy.copyItemStars(self._ChapterID, self._CopyID)
    if star >= 3 then
        local num = Item.getNum(Const.ITEM.COPY_PERMIT)
        if num > 0 then
            self:request("copy.copyHandler.sweep", {chapter = self._ChapterID, id = self._CopyID}, function(msg)
                if msg['code'] == 200 then
                    self:showTip("扫荡成功")
                    self:onClose()
                    --弹出奖品对话框
                end
            end)
        else
            widgetUtil.showConfirmBox("通关券不足，充值VIP可以获得通过券，是否进行充值？", 
                function(msg)
                    UIManager.pushWidget('rechargeWidget', {}, true)
                end)
        end
    else
        self:showTip("战斗评级需达到三星才能进行快速战斗。")
    end
end

--更新掉落物品信息
function copyFightWidget:updateItemInfo()
    local cfg = t_chapter_fuben[self._ChapterID][self._CopyID]
    
    --更新物品掉落
    local icon1 = self._widget.image_item_show1
    local back1 = self._widget.image_item_bottom1
    local front1 = self._widget.image_item_grade1
    
    local icon2 = self._widget.image_item_show2
    local back2 = self._widget.image_item_bottom2
    local front2 = self._widget.image_item_grade2
    
    local item_show = cfg["item_show"]
    if #item_show >= 1 and t_item[item_show[1]] then
        local icon = t_item[item_show[1]]["icon"]
        local grade = t_item[item_show[1]]["grade"]
        widgetUtil.getItemQuality(grade, back1, front1)
        widgetUtil.createIconToWidget(icon, icon1)
    end
    
    if #item_show >= 2 and t_item[item_show[2]] then
        local icon = t_item[item_show[2]]["icon"]
        local grade = t_item[item_show[2]]["grade"]
        widgetUtil.getItemQuality(grade, back2, front2)
        widgetUtil.createIconToWidget(icon, icon2)
    end

end

--设置通关的星星
function copyFightWidget:setStartNum()  
    local starBg1 = self._widget.bg_star1
    local starBg2 = self._widget.bg_star2
    local starBg3 = self._widget.bg_star3
    
    local star1 = self._widget.image_star1
    local star2 = self._widget.image_star2
    local star3 = self._widget.image_star3
    
    starBg1:setVisible(false)
    starBg2:setVisible(false)
    starBg3:setVisible(false)
    self._widget.panel_sweep:setVisible(false)
    
    local cfg = t_chapter_fuben[self._ChapterID][self._CopyID]
    if cfg["type"] == Const.COPY_TYPE.BIG_FIGHT  then
        starBg1:setVisible(true)
        starBg2:setVisible(true)
        starBg3:setVisible(true)
        
        local num = Copy.copyItemStars(self._ChapterID, self._CopyID)
        if num == 1 then
            star2:setVisible(false)
            star3:setVisible(false)
        elseif num == 2 then
            star3:setVisible(false)
        elseif num == 3 then
            self._widget.panel_sweep:setVisible(true)
        else
            star1:setVisible(false)
            star2:setVisible(false)
            star3:setVisible(false)
        end
    end
end

--显示怪物信息
function copyFightWidget:showEnemyInfo()
    local config = t_chapter_fuben[self._ChapterID][self._CopyID]
    local team_config = team_config[config.battle_team]
    if not team_config then
        return
    end
    
    local monsterIds = team_config.monster
    for i=1,#monsterIds do
        local monsterID = monsterIds[i]
        if monsterID ~=0 then
            local monsterConfig = monster_config[monsterID] --怪物信息
            if nil ~= monsterConfig then
                local image_icon = self._widget["image_enemy_show"..i]
                local back = self._widget["image_enemy_bottom"..i]
                local front = self._widget["image_enemy_grade"..i] 
                widgetUtil.createIconToWidget(monsterConfig.icon, image_icon)
                widgetUtil.getHeroWeaponQuality(0, back, front)
            end
        end
    end
end

return copyFightWidget