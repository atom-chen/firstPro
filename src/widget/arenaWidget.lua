local tParameter = require('src/config/t_parameter')
local t_music=require("config/t_music")

local BaseWidget = require('widget.BaseWidget')

local ArenaWidget = class("ArenaWidget", function()
    return BaseWidget:new()
end)

function ArenaWidget:create(save, opt)
    return ArenaWidget.new(save, opt)
end

function ArenaWidget:getWidget()
    return self._widget
end

function ArenaWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIarena.csb")
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    widgetUtil.widgetReader(self._widget)

    --退出竞技场按钮
    self._widget.btn_close:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_close_click")
        end
    end)
    
    --倒计时处理
    self._widget.label_time:setString(" ")
    self._widget.bg_time_text:setVisible(false)
    
    --第一名玩家
    local firstPlayerWhere = ' '
    local firstPlayerName = ' '
    local firstPlayer = Arena.getFristRankPlayer()
    local server_last = Login.getLastLoginServer()
    
    if nil ~= firstPlayer then
        firstPlayerWhere = server_last['_name']
        firstPlayerName = firstPlayer.nick
        local path = string.format("res/img/%d.png", firstPlayer.fashionID) -- 第一名玩家形象
        if cc.FileUtils:getInstance():isFileExist(path) then
            self._widget.image_hero:loadTexture(path)
        end
    end
    
    self._widget.label_sever_name:setString(firstPlayerWhere)
    self._widget.label_name:setString(firstPlayerName)
    
    --玩家防守阵容按钮
    self._widget.btn_formation:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_formation_click")
        end
    end)
    
    --排行榜按钮
    self._widget.btn_rank:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_rank_click")
        end
    end)
    
    --战斗记录按钮
    self._widget.btn_record:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_record_click")
        end
    end)
    
    --积分兑换按钮
    self._widget.btn_point:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_point_click")
        end
    end)
    
    --换一批排行玩家按钮
    self._widget.btn_change:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_change_click")
        end
    end)
    
    --购买挑战次数
    self._widget.btn_number:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_arena_on_number_click")
        end
    end)
    
    local selfInfo = Arena.getSelfInfoList()

    self._widget.label_rank:setString(tostring(selfInfo.rank)) --玩家排名
    self._widget.label_reward:setString(tostring(selfInfo.reward)) --排名奖励
    self:reflashScore() --积分
    
    --挑战次数
    self:flashFightNum()

    --可挑战的玩家
    self:refleshFightUser()

    --计算玩家防守战力
    self:recordDefFihgtNum()
    
    --用户信息
    self:updateInfo()
    self:subscribe(Const.EVENT.USER, function ()
        self:updateInfo()
    end)
    
    local bable, timeShow = ArenaWidget.showLessTime()
    local event = {}
    event["param"] = {strTime = timeShow, btnEnable = bable}
    self:refleshTime(event)
    
    commonUtil.playBakGroundMusic(1601)
end

function ArenaWidget:onEnter()
    self._updateID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(ArenaWidget.update,1,false)
    eventUtil.addCustom(self._widget,"ui_arena_on_close_click",function(event)ArenaWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_formation_click",function(event)ArenaWidget.onFormation(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_rank_click",function(event)ArenaWidget.onRank(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_record_click",function(event)ArenaWidget.onRecord(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_point_click",function(event)ArenaWidget.onPoint(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_item_info_click",function(event)ArenaWidget.onItemInfo(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_item_info_click_finish",function(event)ArenaWidget.onItemInfoFinish(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_item_fight_click",function(event)ArenaWidget.onItemFight(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_change_click",function(event)ArenaWidget.onChange(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_reflesh_fight_click",function(event)ArenaWidget.refleshFightUser(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_reflesh_time",function(event)ArenaWidget.refleshTime(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_buy_fight_num",function(event)ArenaWidget.onBuyFightNum(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_record_def_fight_num",function(event)ArenaWidget.recordDefFihgtNum(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_reflash_score",function(event)ArenaWidget.reflashScore(self,event)end)
    eventUtil.addCustom(self._widget,"ui_arena_on_number_click",function(event)ArenaWidget.buyNumberClick(self,event)end)
    
    --GameGuide.createGuideLayer()
end

function ArenaWidget:onExit()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateID)
    eventUtil.removeCustom(self._widget)
end

function ArenaWidget:onClose(event)
    commonUtil.playBakGroundMusic(1001)
    UIManager.popWidget()
end

--玩家防守阵容按钮响应
function ArenaWidget:onFormation(event)
    local opt = {}
    opt["format_type"] = Const.FORMATION_TYPE.DEFENSE
    UIManager.pushWidget('formatWidget', opt)

--test
--   Arena.setFightFaildTime(os.time())
--test
end

--排行榜按钮响应
function ArenaWidget:onRank(event)
    self:request('arena.arenaHandler.rank', {}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget("arenaRankWidget", nil, true)
        end
    end)
end

--购买挑战次数
function ArenaWidget:buyNumberClick()
    local pay = tParameter.arena_add_challenge_diamond.var --购买一次的花费
    if Character.diamond < pay then
        widgetUtil.showConfirmBox("钻石数量不足，是否进行充值？", 
            function(msg)
                --购买
                UIManager.pushWidget('rechargeWidget', {}, true)
            end)
    else
        self:request('arena.arenaHandler.addChallenge', {num=1}, function(msg)
            if msg['code'] == 200 then
                --购买成功
                self:flashFightNum()
            end
        end)
    end
end

--战斗记录按钮响应
function ArenaWidget:onRecord(event)
    UIManager.pushWidget("arenaFightLogWidget", nil, true)
end

--积分兑换按钮
function ArenaWidget:onPoint(event)
    UIManager.pushWidget('shopWidget',Const.SHOP_TYPE.SCORE)
end

--显示其它玩家布阵信息按钮
function ArenaWidget:onItemInfo(event)
    local format = event.param.format
    for i=1, #format do
        if format[i] ~= 0 and format[i] ~= -1 then --忽略空和自己的
        else
        end
        print(format[i])
    end    
end

--隐藏其它玩家布阵信息
function ArenaWidget:onItemInfoFinish(event)
    print("隐藏其它玩家")
end

--刷新倒计时
function ArenaWidget:refleshTime(event)
    self._widget.label_time:setString(event.param.strTime)
    local bEnable = event.param.btnEnable
    for i=1, 4 do
        self._widget["btn_fight"..i]:setEnabled(not bEnable)
        self._widget["btn_fight"..i]:setBright(not bEnable)
    end
    
    self._widget.bg_time_text:setVisible(bEnable)
end

--挑战其它玩家按钮
function ArenaWidget:onItemFight(event)
    local pos = event.param.pos
    local selfInfo = Arena.getSelfInfoList()
    local maxNum = tParameter.arena_challenge_max.var
    if selfInfo.challenge >= maxNum then  --挑战次数已满
        widgetUtil.showConfirmBox(Str.FIGHT_NUM_LESS, function(msg)
            --购买次数
            eventUtil.dispatchCustom("ui_arena_on_buy_fight_num", {pos = pos})
        end)
        
        return
    end
    
    self:showFormat(pos)
end

--显示布阵
function ArenaWidget:showFormat(pos)
    local opt = {}
    opt["format_type"] = Const.FORMATION_TYPE.ATTACK
    opt["battle_type"] = Const.BATTLE_TYPE.ARENA
    opt["pos"] = pos
    UIManager.pushWidget('formatWidget', opt)
end

--换一批排行玩家按钮
function ArenaWidget:onChange(event)
    self:request('arena.arenaHandler.reflesh', {}, function(msg)
        if msg['code'] == 200 then
            eventUtil.dispatchCustom("ui_arena_on_reflesh_fight_click", {})
        end
    end)
end

--购买挑战次数
function ArenaWidget:onBuyFightNum(event)
    local pay = tParameter.arena_add_challenge_diamond.var --购买一次的花费
    if Character.diamond < pay then
        widgetUtil.showConfirmBox("钻石数量不足，是否进行充值？", 
            function(msg)
                --购买
                UIManager.pushWidget('rechargeWidget', {}, true)
            end)
    else
        self:request('arena.arenaHandler.addChallenge', {num=1}, function(msg)
            if msg['code'] == 200 then
                --购买成功,直接进入战斗
                self:showFormat(event.param.pos)
            end
        end)
    end
end

--刷新可挑战的玩家列表
function ArenaWidget:refleshFightUser()
    for i=1, 4 do
        local item = self._widget["bg_item"..i]
        local user = Arena.getUsersList()

        if nil ~= user and nil ~= user[i] then --有玩家数据
            item:setVisible(true)

            self._widget["label_name"..i]:setString(user[i]["nick"]) -- 玩家名字
            self._widget["label_power"..i]:setString(user[i]["power"]) --玩家战力
            self._widget["label_rank"..i]:setString(user[i]["rank"]) --玩家排名
            self._widget["label_lv"..i]:setString(user[i]["lv"]) --玩家等级
            widgetUtil.createIconToWidget(user[i]["fashionID"], self._widget["image_icon"..i]) --头像
            widgetUtil.getHeroWeaponQuality(0, self._widget["image_icon_bottom"..i], self._widget["image_icon_grade"..i])

            --查看玩家阵容按钮
            self._widget["btn_item"..i].format = clone(user[i]["format"])
            self._widget["btn_item"..i]:addTouchEventListener(function(sender,eventType)
                if eventType == ccui.TouchEventType.began then
                    eventUtil.dispatchCustom("ui_arena_on_item_info_click", {format = sender.format})
                end

                if eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
                    eventUtil.dispatchCustom("ui_arena_on_item_info_click_finish", {})
                end
            end)

            --挑战按钮
            self._widget["btn_fight"..i].pos = i
            self._widget["btn_fight"..i]:addTouchEventListener(function(sender,eventType)
                if eventType == ccui.TouchEventType.ended then
                    eventUtil.dispatchCustom("ui_arena_on_item_fight_click", {pos = sender.pos})
                end
            end)
        else
            item:setVisible(false)
        end
    end
end

--return: 是否倒计时，具体的时间
function ArenaWidget.showLessTime()
    local bable = false --是否在倒计时
    local timeShow = ""

    local tOld = Arena.getFightFaildTime()
    local tNow = Game.time()
    local t = tNow - tOld
    local totalTime = tParameter.arena_cool_time.var
    if t < totalTime then   --倒计时
       local lessTime = totalTime - t --剩余时间
       local h = math.floor(lessTime / 3600) --小时
       local m = math.floor((lessTime - h * 3600)/60) --分钟
       local s = lessTime % 60 --秒
       timeShow = string.format("%02d:%02d:%02d", h, m, s)
       bable = true
    end
    
    return bable, timeShow
end

function ArenaWidget.update(dt)
    local bable, timeShow = ArenaWidget.showLessTime()
    eventUtil.dispatchCustom("ui_arena_on_reflesh_time", {strTime = timeShow, btnEnable = bable})
end

--计算玩家防守战力--待修改
function ArenaWidget:recordDefFihgtNum(event)
    local formatDef = Hero.getFormatByType(Const.FORMATION_TYPE.DEFENSE)
    local num = 0
    for i=1,Const.BATTLE_OBJ_SUM do
        local heroId = formatDef[i]
        if heroId > 0 then
            num = num + Hero.getHeroPower(heroId)
        end
    end

    num = num + Character.power

    self._widget.label_power:setString(tostring(num))
end

--刷新积分
function ArenaWidget:reflashScore(event)
    local score = Arena.getScore()
    self._widget.label_point:setString(tostring(score)) --积分
end

--刷新用户金钱
function ArenaWidget:updateInfo()
    self._widget.label_diamond:setString(tostring(Character.diamond))    --当前钻币
    self._widget.label_gold:setString(tostring(Character.gold))          --当前金币
end

--刷新挑战次数
function ArenaWidget:flashFightNum()
    local selfInfo = Arena.getSelfInfoList()
    local lessNum = tParameter.arena_challenge_max.var - selfInfo.challenge
    self._widget.label_number:setString(lessNum.."/"..tParameter.arena_challenge_max.var) --当前已挑战次数
end

return ArenaWidget