local BaseScene = require "scene/BaseScene"
local t_parameter=require('config/t_parameter')
local t_music=require("config/t_music")

local MainScene = class("MainScene", function()
    return BaseScene:new()
end)

function MainScene:create(save, opt)
    return MainScene.new(save, opt)
end

function MainScene:ctor()
    self:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
end

function MainScene:onEnter()

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImain.csb")
    widgetUtil.widgetReader(self._widget)
    
    self.chatList={}
    self.count=0
    
    particleUtil.createParticleToWidget("particle/star_white.plist",self._widget.bg_diamond_text)
    
    --主角按钮
    self._widget.btn_lead_infor:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_lead_click")
        end
    end)

    --聊天按钮
    self._widget.btn_chat:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_chat_click")
        end
    end)
    
    --金币购买按钮
    self._widget.btn_gold_buy:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_gold_click")
        end
    end)
    
    --钻石购买按钮
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_diamond_click")
        end
    end)
    
    --体力购买按钮
    self._widget.btn_tili_buy:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_tili_click")
        end
    end)
    
    --签到按钮
    self._widget.btn_sign:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_sign_click")
        end
    end)
    
    
    --邮件按钮
    self._widget.btn_mail:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_mail_click")
        end
    end)
    
    --商店按钮
    self._widget.btn_shop:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_shop_click")
        end
    end)
    
      
    --英雄按钮
    self._widget.btn_hero:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_hero_click")
        end
    end)
    
    --训练按钮
    self._widget.btn_train:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_train_click")
        end
    end)
    
    --招募按钮
    self._widget.btn_card_reward:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_card_click")
        end
    end)
    
    
    --活动宣传图按钮
    self._widget.btn_activity:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_activity_click")
        end
    end)
    
    --世界征服按钮（章节）
    self._widget.btn_chapter:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_chapter_click")
        end
    end)
    
    --文明探索按钮
    self._widget.btn_probe:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_probe_click")
        end
    end)
    
    --罗马竞技按钮
    self._widget.btn_arena:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_arena_click")
        end
    end)
    
    --圣杯战争按钮
    self._widget.btn_sangreal:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_sangreal_click")
        end
    end)
    
    --联合国按钮
    self._widget.btn_guild:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_mainScene_on_guild_click")
        end
    end)
    
    --Boss章节
    self._widget.btn_fuben_boss:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_chapterWidget_on_boss_click")
        end
    end)
    
    --活动章节
    self._widget.btn_fuben_activity:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_chapterWidget_on_activity_click")
        end
    end)
    
    --打开弹窗按钮
    self._widget.panel_menu_open:setVisible(false)
    self._widget.btn_menu_open:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            self._widget.btn_menu_open:setEnabled(false)
                  
            ccs.ActionManagerEx:getInstance():playActionByName("UImain.csb","Animation_open",cc.CallFunc:create(function()
                self._widget.btn_menu_open:setEnabled(true)
                self._widget.panel_menu_open:setVisible(false)
                self._widget.panel_menu_close:setVisible(true)
                
                self._widget.bg_menu1:setEnabled(true)
                self._widget.bg_menu2:setEnabled(true)
            end))
        end
    end)
    
    --关闭弹窗按钮
    self._widget.btn_menu_close:addTouchEventListener(function(sender, eventType) 
        if eventType == ccui.TouchEventType.ended then
            self._widget.btn_menu_close:setEnabled(false)
            
            self._widget.bg_menu1:setEnabled(false)
            self._widget.bg_menu2:setEnabled(false)

            ccs.ActionManagerEx:getInstance():playActionByName("UImain.csb","Animation_close",cc.CallFunc:create(function()
                self._widget.btn_menu_close:setEnabled(true)
                
                self._widget.panel_menu_open:setVisible(true)
                self._widget.panel_menu_close:setVisible(false)
            end))
        end
    end)
    --]]
    
    self:updateInfo()
    self:updateStrength()

    self:addChild(self._widget)

    --监听新邮件
    self:subscribe(Const.EVENT.MAIL, function (mailItem)
        self:newMailCallBack(mailItem)
    end)
    
    --监听用户信息
    self:subscribe(Const.EVENT.USER, function ()
        self:updateInfo()
    end)
    
    --监听体力
    self:subscribe(Const.EVENT.STRENGTH, function ()
        self:updateStrength()
    end)
    
    --监听充值信息
    self:subscribe(Const.EVENT.CHARGE, function (diamond)
        self:showTip("充值".. diamond .. "钻石")
    end)
    
    eventUtil.addCustom(self._widget,"ui_mainScene_on_lead_click",function(event)MainScene.showPlayerWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_chat_click",function(event)MainScene.showChatWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_gold_click",function(event)MainScene.showGoldBuyWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_diamond_click",function(event)MainScene.showDiamondBuyWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_tili_click",function(event)MainScene.showTiLiBuyWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_sign_click",function(event)MainScene.showSignWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_mail_click",function(event)MainScene.showMailWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_shop_click",function(event)MainScene.showShopWidget(self, event)end)
    
    eventUtil.addCustom(self._widget,"ui_mainScene_on_hero_click",function(event)MainScene.showHeroSelectWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_train_click",function(event)MainScene.showHeroTrainWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_card_click",function(event)MainScene.showCardWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_activity_click",function(event)MainScene.showActivityWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_chapter_click",function(event)MainScene.chapterRequest(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_probe_click",function(event)MainScene.showProbeWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_arena_click",function(event)MainScene.showArenaWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_sangreal_click",function(event)MainScene.showSangrealWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_mainScene_on_guild_click",function(event)MainScene.showGuildWidget(self, event)end)
    eventUtil.addCustom(self._widget,"ui_chapterWidget_on_boss_click",function(event)MainScene.onBoss(self,event)end)
    eventUtil.addCustom(self._widget,"ui_chapterWidget_on_activity_click",function(event)MainScene.onActivity(self,event)end)
    
    --监听新聊天
    eventUtil.addCustom(self._widget,"ui_ChatWidget_new_chat_receive",function(event)MainScene.newChat(self, event)end)
    
    self:scheduleUpdateWithPriorityLua(function(dt) self:updateChat(dt) end, 1)
    
    --签到自动弹窗
    if Sign.isFirst() then
        eventUtil.dispatchCustom("ui_mainScene_on_sign_click")
    end
    
    commonUtil.playBakGroundMusic(1001)
end

function MainScene:onResume()
    commonUtil.playBakGroundMusic(1001)
end

--监听新聊天
function MainScene:newChat(event)
    table.insert(self.chatList,event.param)
    if #self.chatList>15 then
        table.remove(self.chatList,1)
    end
end
--刷新聊天信息
function MainScene:updateChat(dt)
    self.count=self.count+dt
    if self.count > 2 then
    	self.count=0
        local widget=self._widget

        local masg=self.chatList[1]
        if masg then

            widget.label_chat_vip:setString("VIP"..(masg.param.vip))
            widget.label_chat_name:setString(tostring(masg.param.nick))
            local str=commonUtil.clipString(masg.param.msg,12,true)           
            widget.label_chat:setString(str)   
            table.remove(self.chatList,1)        
        end
    end
end

--更新主界面信息
function MainScene:updateInfo()
    local widget=self._widget
    
    --玩家icon
    local icon=string.format("res/story_icon/%d.png",Character.fashionID)
    if cc.FileUtils:getInstance():isFileExist(icon) then
        widget.image_icon:loadTexture(icon)  
    end
       
    local bg=string.format("res/img/%d.png",Character.fashionID)
    if cc.FileUtils:getInstance():isFileExist(bg) then
        widget.image_hero:loadTexture(bg) 
    end  
    
    --vip等级
    local lableVip=string.format("VIP%d", Character.vipLevel)
    widget.label_vip:setString(lableVip)    
    --等级
    widget.label_lv:setString(tostring(Character.level))    
    --金币
    widget.label_gold:setString(tostring(Character.gold))
    --砖石
    widget.label_diamond:setString(tostring(Character.diamond))
end

--更新体力
function MainScene:updateStrength()
    --体力
    local max=t_parameter.strength_max.var
    local tili=string.format("%d/%d",Character.strength,max)
    self._widget.label_tili:setString(tili)  
end

function MainScene:onExit()
    eventUtil.removeCustom(self._widget)
end

--主角界面
function MainScene:showPlayerWidget()
    UIManager.pushWidget('characterWidget')
end

--聊天
function MainScene:showChatWidget()
    UIManager.pushWidget('chatWidget')
end

--金币购买
function MainScene:showGoldBuyWidget()
    UIManager.pushWidget('goldBuyWidget')
end
--钻石购买
function MainScene:showDiamondBuyWidget()
    UIManager.pushWidget('rechargeWidget')
end
--体力购买
function MainScene:showTiLiBuyWidget()
    UIManager.pushWidget('tiliBuyWidget', nil, true)
end
--签到
function MainScene:showSignWidget()
    UIManager.pushWidget('signWidget')
end

--邮件
function MainScene:showMailWidget()
    local mailList = Mail.getMailList()
    local have = false
    for i,v in pairs(mailList) do
        have = true
        break
    end

    if have then
        UIManager.pushWidget('mailWidget')
        self._widget.btn_mail:stopAllActions()
    else
        self:request('mail.mailHandler.mail', {}, function(msg)
            if msg['code'] == 200 then
                UIManager.pushWidget('mailWidget')
                self._widget.btn_mail:stopAllActions()
            end
        end)
    end
end


--新邮件回调
function MainScene:newMailCallBack(mailItem)
    self:showTip("新邮件:"..mailItem["id"])
    self._widget.btn_mail:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(0.4,1.15),cc.ScaleTo:create(0.4,0.98))))
end

--商店、兑换界面
function MainScene:showShopWidget()
    UIManager.pushWidget('shopWidget',Const.SHOP_TYPE.COMMON)
end

--英雄选择界面
function MainScene:showHeroSelectWidget()
    UIManager.pushWidget('heroSelectWidget')
end

--英雄训练界面
function MainScene:showHeroTrainWidget()
    UIManager.pushWidget('heroTrainWidget')
end

--招募界面
function MainScene:showCardWidget()
    UIManager.pushWidget('cardRewardWidget')
end

--活动界面
function MainScene:showActivityWidget()
    --UIManager.pushWidget('activityWidget')
    self:showTip(Str.FUNCTION_NOT_OPEN)
end

--获取副本数据
function MainScene:chapterRequest()
    if Copy.isLoadded() then
        self:showChapterWidget()
    else
        self:request('copy.copyHandler.entry', {}, function(msg)
            if msg['code'] == 200 then
                self:showChapterWidget()
            end
        end)
    end    
end

--进入章节界面 
function MainScene:showChapterWidget()
    UIManager.pushScene('ChapterScene')
    UIManager.pushWidget('chapterWidget')
end

--文明探索界面
function MainScene:showProbeWidget()
    if Copy.isLoadded() then
        self:request("copy.copyHandler.activityEntry", {}, function(msg)
            if msg['code'] == 200 then
                UIManager.pushWidget('copyActivityWidget', nil, true)
            end
        end)
    else
        self:request('copy.copyHandler.entry', {}, function(msg)
            if msg['code'] == 200 then
                self:request("copy.copyHandler.activityEntry", {}, function(msg)
                    if msg['code'] == 200 then
                        UIManager.pushWidget('copyActivityWidget', nil, true)
                    end
                end)
            end
        end)
    end 
end

--竞技场界面
function MainScene:showArenaWidget()
    self:request('arena.arenaHandler.entry', {}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('arenaWidget')
        end
    end)
end

--圣杯界面
function MainScene:showSangrealWidget()
    --UIManager.pushWidget('sangrealWidget')
    self:showTip(Str.FUNCTION_NOT_OPEN)
end

--联合国界面
function MainScene:showGuildWidget()
    self:showTip(Str.FUNCTION_NOT_OPEN)
    --UIManager.pushWidget('guildWidget')
end

--好友界面
function MainScene:showFriendWidget()
    self:showTip(Str.FUNCTION_NOT_OPEN)
    --UIManager.pushWidget('friendWidget')
end

--打开弹窗
function MainScene:openWindow() 
    self._widget.btn_menu_open:setVisible(false)
    self._widget.btn_menu_close:setVisible(true)
end
--关闭弹窗
function MainScene:closeWindow()
    self._widget.btn_menu_close:setVisible(false)
    self._widget.btn_menu_open:setVisible(true)
end


--boss章节按钮
function MainScene:onBoss(event)
    --[[if Copy.isLoadded() then
        UIManager.pushWidget('copyBossWidget', nil, true)
    else
        self:request('copy.copyHandler.entry', {}, function(msg)
            if msg['code'] == 200 then
                UIManager.pushWidget('copyBossWidget', nil, true)
            end
        end)
    end ]]
end

--活动副本章节按钮
function MainScene:onActivity(event)
    --[[if Copy.isLoadded() then
        self:request("copy.copyHandler.activityEntry", {}, function(msg)
            if msg['code'] == 200 then
                UIManager.pushWidget('copyActivityWidget', nil, true)
            end
        end)
    else
        self:request('copy.copyHandler.entry', {}, function(msg)
            if msg['code'] == 200 then
                self:request("copy.copyHandler.activityEntry", {}, function(msg)
                    if msg['code'] == 200 then
                        UIManager.pushWidget('copyActivityWidget', nil, true)
                    end
                end)
            end
        end)
    end 
    ]]

end


return MainScene