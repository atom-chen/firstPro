local BaseWidget = require('widget.BaseWidget')

local t_parameter=require("src/config/t_parameter")

local ChatWidget = class("ChatWidget", function()
    return BaseWidget:new()
end)

function ChatWidget:create(save, opt)
    return ChatWidget.new(save, opt)
end

function ChatWidget:getWidget()
    return self._widget
end

function ChatWidget:ctor(save, opt)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchat.csb")
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
            eventUtil.dispatchCustom("ui_ChatWidget_on_close_click")
        end
    end)

    --发送按钮
    self._widget.btn_send:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_ChatWidget_on_send_click")
        end
    end)

    --世界按钮
    self._widget.btn_world:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_ChatWidget_on_world_click")
        end
    end)

    --公会按钮
    self._widget.btn_guild:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_ChatWidget_on_sociaty_click")
        end
    end)

    --手动创建输入框
    local edit_chat_bg = self._widget.bg_label
    local sizeEditChat = edit_chat_bg:getContentSize()
    self.edit_chat = cc.EditBox:create(sizeEditChat, cc.Scale9Sprite:create('res/ui/chat_bg3.png'))
    self.edit_chat:setPosition(cc.p(sizeEditChat.width/2, sizeEditChat.height/2))
    self.edit_chat:setPlaceHolder(tostring("请输入聊天内容"))
    self.edit_chat:setMaxLength(30)
    edit_chat_bg:addChild(self.edit_chat)
    
    --默认选中世界聊天
    self.selectWorld = true
    self:updateChatPanel(true)
    self:setBtnSelected()
end

function ChatWidget:onEnter()
    eventUtil.addCustom(self._widget,"ui_ChatWidget_on_close_click",function(event)ChatWidget.onClose(self,event)end)
    eventUtil.addCustom(self._widget,"ui_ChatWidget_on_send_click",function(event)ChatWidget.onSend(self,event)end)
    eventUtil.addCustom(self._widget,"ui_ChatWidget_on_world_click",function(event)ChatWidget.onWorld(self,event)end)
    eventUtil.addCustom(self._widget,"ui_ChatWidget_on_sociaty_click",function(event)ChatWidget.onSociaty(self,event)end)
    eventUtil.addCustom(self._widget,"ui_ChatWidget_new_chat_receive",function(event)ChatWidget.newChatReceive(self,event)end)
end

function ChatWidget:onExit()
    eventUtil.removeCustom(self._widget)
end

--关闭按钮
function ChatWidget:onClose(event)
    UIManager.popWidget()
end

--发送
function ChatWidget:onSend(index)
    local chat = self.edit_chat:getText()
    local chatNum = string.len(chat)
    
    if chatNum == 0 then
        self:showTip(Str.INPUT_CHAT_CONTENT)
        return
    end
    
    local targetPlatform = CCApplication:getInstance():getTargetPlatform()
    if (kTargetWindows == targetPlatform) then
        local str,full = commonUtil.clipString(chat, 30)
        if full then
            self:showTip(Str.CHAT_TOO_LONG)
            return
        end
    end
    
    
    local str = KeyWordFilter.filterKeyWord(chat)
    --[[
    if result then
        self:showTip(Str.CHAT_FIRE_WORD..str..Str.CHAT_REINPUT_WORD)
        return
    end
    ]]
    
    self:request('chat.chatHandler.send', {msg = str}, function(msg)
        if msg['code'] == 200 then
            self.edit_chat:setText("")
        end
    end)
end

--刷新聊天面板
function ChatWidget:updateChatPanel(bWorld)
    local chatList
    if bWorld then
        chatList = Chat.getGlobalChatList()
    else
        chatList = Chat.getUnionChatList()
    end
    
    local list = self._widget.list_item
    list:removeAllItems()
    local row = #chatList
    for i=1, row do
        if chatList[i].id == Character.id then                 --自己的聊天
            list:pushBackCustomItem(ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchat_item2.csb"))
        else
            list:pushBackCustomItem(ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchat_item.csb"))   --其他人的聊天
        end

        local item_widget = list:getItem(i-1)
        widgetUtil.widgetReader(item_widget)
        
        local my = true
        if chatList[i].id ~= Character.id then                 --其他人的聊天
            my = false
            item_widget.label_name:setString(chatList[i].nick) --名字
            if bWorld then
                --item_widget.label_guild:setString(tostring(""))
            else
                --item_widget.label_guild:setString(tostring("所在公会")) --所在公会
            end
        end
        item_widget.label_icon_lv:setString(tostring(chatList[i].lv)) --等级

        self:addChatString(item_widget.image_chat, chatList[i].msg, my)

        local chatTime = os.date("%H:%M", chatList[i].time)
        item_widget.label_time:setString(chatTime) --聊天时间
        
        widgetUtil.createIconToWidget(chatList[i].fashionID, item_widget.image_icon)--玩家头像
        widgetUtil.getHeroWeaponQuality(0, item_widget.image_icon_bottom, item_widget.image_icon_grade)
    end

    self._widget:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(ChatWidget.scrollPanel, self)))
end

--世界
function ChatWidget:onWorld(index)
    if self.selectWorld then
    	return
    end
    
    self.selectWorld = true
    self:updateChatPanel(true)
    self:setBtnSelected()
end

--公会
function ChatWidget:onSociaty(index)
    --未开放功能
    if true then
        self:showTip(Str.FUNCTION_NOT_OPEN)
        return
    end
    --未开放功能
    
    if not self.selectWorld then
        return
    end

    self.selectWorld = false
    self:updateChatPanel(false)
    self:setBtnSelected()
end

--有新的聊天消息的回调
function ChatWidget:newChatReceive(event)
    local chat = event.param.param
    if self.selectWorld and event.param.world then --当前面板选中世界聊天,并且是收到世界聊天信息
    	self:addNewChat(true, chat)
    elseif not self.selectWorld and not event.param.world then
        self:addNewChat(false, chat)
    end
end

function ChatWidget:scrollPanel()
    local list = self.list_item
    list:jumpToPercentVertical(100)
end

--添加新的聊天内容
function ChatWidget:addNewChat(world, chat)
    local list = self._widget.list_item
    if chat.id == Character.id then --自己的聊天
        list:pushBackCustomItem(ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchat_item2.csb"))
    else
        list:pushBackCustomItem(ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIchat_item.csb"))
    end

    local items = list:getItems()
    local count = table.maxn(items)
    local item_widget = list:getItem(count -1)
    widgetUtil.widgetReader(item_widget)

    if world then
        local chatList = Chat.getGlobalChatList()
        local chatNum = #chatList
        if chatNum > t_parameter.chat_store_max.var then
            Chat.delGlobalChat()
            list:removeItem(0)
        end
    else
        local chatList = Chat.getUnionChatList()
        local chatNum = #chatList
        if chatNum > t_parameter.chat_store_max.var then
            Chat.delUnionChat()
            list:removeItem(0)
        end
    end
    
    local my = true
    if chat.id ~= Character.id then --其他人的聊天
        my = false
        
        item_widget.label_name:setString(chat.nick) --名字
        if world then
            --item_widget.label_guild:setString(tostring("")) --所在公会
        else
            --item_widget.label_guild:setString(tostring("嘎达上")) --所在公会
        end
    end
    
    item_widget.label_icon_lv:setString(tostring(chat.lv)) --等级
    
    widgetUtil.createIconToWidget(chat.fashionID, item_widget.image_icon)--玩家头像
    widgetUtil.getHeroWeaponQuality(0, item_widget.image_icon_bottom, item_widget.image_icon_grade)
    --item_widget.label_chat:setString(chat.msg) --聊天内容
    local chatTime = os.date("%H:%M", chat.time)
    item_widget.label_time:setString(chatTime) --聊天时间
    self:addChatString(item_widget.image_chat, chat.msg, my)
    
    self._widget:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(ChatWidget.scrollPanel, self)))

end

--设置按钮选中状态
function ChatWidget:setBtnSelected()
    if self.selectWorld then --选中世界聊天
    	self._widget.btn_world:setEnabled(false)
    	self._widget.btn_world:setBright(false)
    	self._widget.btn_guild:setEnabled(true)
        self._widget.btn_guild:setBright(true)
    else
        self._widget.btn_world:setEnabled(true)
        self._widget.btn_world:setBright(true)
        self._widget.btn_guild:setEnabled(false)
        self._widget.btn_guild:setBright(false)
    end
end

--添加聊天内容
--node:9宫格背景
--str:聊天内容
function ChatWidget:addChatString(node, str, my)
    local richText = ccui.RichText:create()
    local r1 = ccui.RichElementText:create(1, cc.c3b(106,57,6), 255, str, "fonts/FZZhengHeiS-DB-GB.ttf", 20)
    richText:pushBackElement(r1)
    richText:setAnchorPoint(cc.p(0.5,0.5))

    performWithDelay(richText, function() 
        local x, y = node:getPosition()--背景图原始位置
        local nSize = node:getContentSize()--背景图原始宽高
        local twoH = 90 --两行文字的高度
        local oneH = 60 --一行文字的高度
        local richS = richText:getContentSize()--文字的实际宽度
        
        if richS.width > 360 then --分两行
            richText:ignoreContentAdaptWithSize(false)
            richText:setContentSize(cc.size(360, richS.height * 2))
            node:setContentSize(cc.size(360+40, twoH))
        else -- 一行
            local wTemp = richS.width + 40
            if wTemp < nSize.width then --比原始图片小
                wTemp = nSize.width
            end
            node:setContentSize(cc.size(wTemp, oneH))
        end
        
        local nSizeNew = node:getContentSize()--背景图新宽高
        if my then
            x = x - nSizeNew.width/2
            y = y - nSizeNew.height/2
        else
            x = x + nSizeNew.width/2
            y = y - nSizeNew.height/2
        end
        
        richText:setPosition(cc.p(x, y))
    end,0)
    
    node:getParent():addChild(richText, 30)
end

return ChatWidget