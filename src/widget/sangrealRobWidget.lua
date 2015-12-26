local BaseWidget = require('widget.BaseWidget')

local t_item=require('config/t_item')
local t_parameter=require('config/t_parameter')
local SangrealRobWidget = class("SangrealRobWidget", function()
    return BaseWidget:new()
end)

function SangrealRobWidget:create(save, opt)
    return SangrealRobWidget.new(save, opt)
end

function SangrealRobWidget:getWidget()
    return self._widget
end

function SangrealRobWidget:ctor(save, pieceId)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIsangreal_grad.csb")

    widgetUtil.widgetReader(self._widget)
    
    self._pieceId=pieceId

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    local chatItem= ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIsangreal_grad_chat.csb")  
    local playerItem=ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIsangreal_item2.csb")
         
    self.chatList=self._widget.list_chat   --@return ccui.ListView
    self.playerList=self._widget.list_item 
    
    self.chatList:setItemModel(chatItem)   
    self.playerList:setItemModel(playerItem) 
       
    --返回按钮
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:back()
        end
    end)
    
    --鼓舞按钮
    self._widget.btn_inspire:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onInspire()
        end
    end)
    
    --普通和宿敌按钮
    self._widget.label_enemy:setString("普通")
    self._widget.btn_enemy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onEnemy()
        end
    end)
    
    self:updatePieceInfo()
    self:updateMessageList()
    self:updateEnemyList()
end

--点击鼓舞按钮
function SangrealRobWidget:onInspire()
    local cost=t_parameter["sangreal_inspire_cost"]["var"]
    if Character.diamond>=cost then
        --鼓舞请求
        local request = {}
        self:request("sangreal.sangrealHandler.inspire", request, function(msg)
            if msg['code'] == 200 then           
            end
        end)
    else
        --弹窗提示砖石不足，是否充值
    end
end

--点击普通或宿敌按钮
function SangrealRobWidget:onEnemy()
    local widget=self._widget
    
    if widget.label_enemy:getString()=="宿敌" then
        widget.label_enemy:setString("普通") 
        self:updateEnemyList()
    elseif widget.label_enemy:getString()=="普通" then    
        widget.label_enemy:setString("宿敌") 
       --普通请求
        local request={}
        request["ftype"]=self._pieceId
        self:request("sangreal.sangrealHandler.reflesh", request, function(msg)
            if msg['code'] == 200 then
                self:updatePlayerList()              
            end
        end)
    end
end

--刷新碎片相关数值
function SangrealRobWidget:updatePieceInfo()
    local widget=self._widget
    
    local pieceIcon=t_item[self._pieceId]["icon"]
    --widgetUtil.createIconToWidget(pieceIcon,widget.image_piece_icon)
    local num = Sangreal.getFragmentNum(self._pieceId)
    widget.label_piece_number:setString(tostring(num))
    
    local robTimes=Sangreal.getRobTimes()
    widget.label_number1:setString(tostring(robTimes))
    local robMax=t_parameter["sangreal_rob_max"]["var"]
    robMax=string.format("/%d",robMax)
    widget.label_number1_max:setString(robMax)
    
    local robbedTimes=Sangreal.getRobbedTimes()
    widget.label_number2:setString(tostring(robbedTimes))
    local robbedMax=t_parameter["sangreal_robbed_max"]["var"]
    robbedMax=string.format("/%d",robbedMax)
    widget.label_number2_max:setString(robbedMax)
      
end

--刷新消息列表
function SangrealRobWidget:updateMessageList()    
    self.chatList:removeAllItems()
    local msg=Sangreal.getMsg()
    
    for i=1, #msg do
        self.chatList:pushBackDefaultItem()   	
        local item=self.chatList:getItem(i-1)

        local label_chat=item:getChildByName("label_chat")
        label_chat:setString(msg[i]["_msg"])
                
        local label_time=item:getChildByName("label_time")
        label_time:setString(msg[i]["_time"])
        
        if msg[i]["_type"]==1 then
            label_chat:setColor(cc.c3b(255,0,0))
            label_time:setColor(cc.c3b(255,0,0))
        else
            label_chat:setColor(cc.c3b(0,255,0))
            label_time:setColor(cc.c3b(0,255,0))
        end
    end   
    
           
end


--刷新宿敌玩家列表
function SangrealRobWidget:updateEnemyList()
    self.playerList:removeAllItems()
    
    local enemy=Sangreal.getEnemy()
    table.sort(enemy,Sangreal.sortEnemyByTime)
    
    for i=1, #enemy do
        self.playerList:pushBackDefaultItem()     
        local enemyItem=self.playerList:getItem(i-1)
        widgetUtil.widgetReader(enemyItem)
        
        widgetUtil.createIconToWidget(enemy[i]._fashionID,enemyItem.image_player)
        enemyItem.label_name:setString(enemy[i]._nick)
        enemyItem.label_lv:setString(tonumber(enemy[i]._lv))
        enemyItem.label_piece_number:setString(tonumber(enemy[i]._num))                                                       
                      
        if enemy[i]._hate==1 then       
        	enemyItem.check_enemy:setSelectedState(true)
        end
        
        --仇敌复选框
        enemyItem.check_enemy:addEventListener(function(sender,eventType)
            if eventType == ccui.CheckBoxEventType.selected then
                sender:setSelectedState(false)
                self:hateRequest(enemy[i]._playerId,sender)
                              
            elseif eventType == ccui.CheckBoxEventType.unselected then
                sender:setSelectedState(true)
                self:hateRequest(enemy[i]._playerId,sender)
                                                
            end
        end)
        
        enemyItem.btn_item:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:robRequest(enemy[i]._playerId)                  
            end
        end)        
    end 
end

--仇敌请求
function SangrealRobWidget:hateRequest(uid,sender)
    local request = {}
    request["ftype"]=self._pieceId
    request["uid"]=uid
    self:request("sangreal.sangrealHandler.hate", request, function(msg)
        if msg['code'] == 200 then
            if sender:getSelectedState() then
                sender:setSelectedState(false)
            else
                sender:setSelectedState(true)
            end                        
        end
    end)
end


--刷新普通玩家列表
function SangrealRobWidget:updatePlayerList()
    self.playerList:removeAllItems()
    
    local player=Sangreal.getFragpvp()
    
    for i=1, #player do
        self.playerList:pushBackDefaultItem()     
        local playerItem=self.playerList:getItem(i-1)
        widgetUtil.widgetReader(playerItem)
        
        widgetUtil.createIconToWidget(player[i]._fashionID,playerItem.image_player)
        playerItem.label_name:setString(player[i]._nick)
        playerItem.label_lv:setString(tonumber(player[i]._lv))
        playerItem.label_piece_number:setString(tonumber(player[i]._num))                                        
      
        playerItem.check_enemy:setVisible(false)
        
        playerItem.btn_item:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:robRequest(player[i]._playerId)    
            end
        end)   
    end
end

--抢夺请求
function SangrealRobWidget:robRequest(uid)
    local request = {}
    request["ftype"]=self._pieceId
    request["uid"]=uid
    request["battle_type"]=Const.BATTLE_TYPE.ROB_HOLLY_CUP
    request["format_type"] = Const.FORMATION_TYPE.ATTACK
    UIManager.pushWidget("formatWidget", request)
end

function SangrealRobWidget:showFormatWidget()

end


function SangrealRobWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()

    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_sangrealRob_on_back_click",function(event) SangrealRobWidget.back(self, event) end), 1)
        
    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_sangrealRob_on_inspire_click",function(event) SangrealRobWidget.onInspire(self, event) end), 1)
        
    eventDispatcher:addEventListenerWithFixedPriority(
        cc.EventListenerCustom:create("ui_sangrealRob_on_enemy_click",function(event) SangrealRobWidget.onEnemy(self, event) end), 1)

    --eventUtil.addCustom(self._widget,"ui_lead_on_equip_click",function(event)CharacterWidget.onEquipClick(self,event.param)end)
end
function SangrealRobWidget:onExit()
end
--退出当前界面
function SangrealRobWidget:back()

    UIManager.popWidget() 
end
return SangrealRobWidget