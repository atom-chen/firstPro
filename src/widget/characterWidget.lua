
--[[
*           主角信息界面
*
]]

--module require

require('mime')
require('json')

local BaseWidget = require('widget.BaseWidget')
local t_lv = require('config/t_lv')
local t_hero = require('config/t_hero')
local t_lead_name = require('config/t_lead_name')
local t_parameter = require('config/t_parameter')
local windowTag=100


local CharacterWidget = class("CharacterWidget", function()
    return BaseWidget:new()
end)

function CharacterWidget:create(save, opt)
    return CharacterWidget.new(save, opt)
end

function CharacterWidget:getWidget()
    return self._widget
end

function CharacterWidget:ctor(save, id)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlead_info.csb")
    widgetUtil.widgetReader(self._widget)

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)


    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:back()
        end
    end)
    
    --更改昵称按钮
    self._widget.btn_change_name:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:changeName()
        end
    end)
    
    --更改头像按钮
    self._widget.btn_change_icon:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:changeIcon()
        end
    end)

    --vip按钮
    self._widget.btn_vip:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:createVipPrivilegeWidget()
        end
    end)

    --系统设置按钮
    self._widget.btn_set:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:showTip(Str.FUNCTION_NOT_OPEN)
        end
    end)

    self:characterInfo()
end

--主角界面主角信息
function CharacterWidget:characterInfo()
    local widget = self._widget

    --玩家头像
    local icon=string.format("res/story_icon/%d.png",Character.fashionID)
    if cc.FileUtils:getInstance():isFileExist(icon) then
        widget.Image_player:loadTexture(icon)  
    end
    
    --主角称呼
    widget.label_name:setString(Character.name)
    --等级
    widget.label_lv:setString(tostring(Character.level)) 
    --当前经验
    local curExp=Character.exp
    local maxExp=t_lv[Character.level].lead_up_exp
    local lableExp=string.format("%d/%d",curExp,maxExp)
    widget.label_exp:setString(lableExp)
    --拥有英雄
    local heroNum=Hero.getHeroNum()
    local lableNum=string.format("%d/%d",heroNum,table.maxn(t_hero)-1000)
    widget.label_hero_number:setString(lableNum)
    --玩家Id
    widget.label_id:setString(tostring(Character.id))
    --工会名字
    widget.label_guild:setString("工会名字")
   
    --手动创建输入框            国家宣言
    local sizeEdit = widget.label_desc:getContentSize()
    self.edit = cc.EditBox:create(sizeEdit, cc.Scale9Sprite:create('ui/common_transparent.png'))
    self.edit:setPosition(cc.p(sizeEdit.width/2, sizeEdit.height/2))
    self.edit:setPlaceHolder("")
    self.edit:setMaxLength(t_parameter.greeting_max_words.var)
    self.edit:setFont(widget.label_desc:getFontName(),widget.label_desc:getFontSize())
    self.edit:setFontColor(cc.c3b(0,117,169))
    widget.label_desc:setString(Character.greetings)
    
    widget.label_desc:addChild(self.edit)
    
    local preStr=""
    self.edit:registerScriptEditBoxHandler(function(event)      
        if event == "began" then
            preStr = widget.label_desc:getString()
            local plat=cc.Application:getInstance():getTargetPlatform()
            if plat == cc.PLATFORM_OS_IPHONE then
                widget.label_desc:setString("")
            end
            self.edit:setText(preStr)
        elseif event == "return" then
            local greeting = self.edit:getText()
            self.edit:setText("")                

            local afterFilter=KeyWordFilter.filterKeyWord(greeting)
            local afterClip,flag=commonUtil.clipString(afterFilter,t_parameter.greeting_max_words.var,false)             
            widget.label_desc:setString(afterClip)
            
            if afterClip==preStr then
            	return
            end

            if flag then                
                self:showTip(Str.GREETING_TOO_LONG)
            else
                Character.greetings= afterClip
                local request = {}
                request["greeting"] = mime.b64(afterClip)
                self:notify("main.userHandler.greeting", request, function(msg)end)
            end
        end
    end)
end


--创建更改昵称界面
function CharacterWidget:changeName() 
    local widget= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlead_name.csb")
    self._widget:addChild(widget,0xFF,windowTag)
    widgetUtil.widgetReader(widget)
    
    --骰子
    widget.btn_random:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:setRandomName(widget.label_name)
        end
    end)
    --取消
    widget.btn_no:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            widget:runAction(cc.RemoveSelf:create())
        end
    end)
    --确定
    widget.btn_yes:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local str=widget.label_name:getString()
            if str~=Character.name then
                local s=commonUtil.split(str," ")
                if #s>1 then
                	self:showTip("昵称中不能含有空格哦！")
                else
                    local lable=string.format(Str.CHANGE_PLAYER_NAME,t_parameter.lead_name_pay.var,str)
                    widgetUtil.showConfirmBox(lable, 
                        function()
                            self:changeNameRequest(str)
                        end)
                end
            else
                self:showTip("亲，还没输入新昵称！")
            end
        end
    end)
    
    local sizeEdit = widget.label_name:getContentSize()
    self.editName = cc.EditBox:create(sizeEdit, cc.Scale9Sprite:create('ui/common_transparent.png'))
    self.editName:setPosition(cc.p(sizeEdit.width/2, sizeEdit.height/2))
    self.editName:setPlaceHolder("")
    self.editName:setMaxLength(t_parameter.lead_name_width.var)
    self.editName:setFont(widget.label_name:getFontName(),widget.label_name:getFontSize())
    self.editName:setFontColor(cc.c3b(255,243,34))
    widget.label_name:setString(Character.name)
    widget.label_name:addChild(self.editName)
    
    local preStr=""
    self.editName:registerScriptEditBoxHandler(function(event)        
        if event=="began" then
            preStr = widget.label_name:getString()
            local plat=cc.Application:getInstance():getTargetPlatform()
            if plat == cc.PLATFORM_OS_IPHONE then
                widget.label_name:setString("")
            end
            self.editName:setText(preStr)
            
        elseif event == "return" then
            local blank = {0x1680,0x180E,0x2002,0x2003,0x2004,0x2005,0x2006,0x2007,0x2008,0x2009,0x200A,0x200B,0x200C,0x200D,0x202F,0x205F,0x2060,0x3000,0xFEFF}
            local str = self.editName:getText()
            self.editName:setText("")    
            
            local str32 = KeyWordFilter.toutf32(str)  
            local begin=1
            for i=1, #str32 do  --得到第一个非空字符位置
                if str32[i]<128 and str32[i]>=33 and str32[i]<=127 then
                    begin = i
                    break
                else
                    local find = false
                    for j=1,#blank do
                        if str32[i] == blank[j] then
                            find = true
                            break
                        end
                    end
                    if not find then
                        begin = i
                        break
                    end
                end
            end

            local ed = #str32
            for i=#str32, begin, -1 do  --得到最后一个非空字符位置
                if str32[i]<128 and str32[i]>=33 and str32[i]<=127 then
                    ed = i
                    break
                else
                    local find = false
                    for j=1,#blank do
                        if str32[i] == blank[j] then
                            find = true
                            break
                        end
                    end
                    if not find then
                        ed = i
                        break
                    end
                end
            end

            local s = {}
            for i=begin, ed do
                table.insert(s, str32[i])
            end
            str = KeyWordFilter.toutf8(s)

            local afterFilter=KeyWordFilter.filterKeyWord(str)
            local afterClip,flag=commonUtil.clipString(afterFilter,t_parameter.lead_name_width.var,false) 

            if ""==str then
                self:showTip("亲，昵称不能为空哦！")
                widget.label_name:setString(preStr)
            else
                widget.label_name:setString(afterClip)
            end

            if flag then
                self:showTip("亲，你的昵称太长了！")
            end
        end
    end)
end
--随机昵称
function CharacterWidget:setRandomName(lable) 
    local max=table.maxn(t_lead_name)
    local ran1=math.random(1,max)
    local ran2=math.random(1,max)
    
    local name1=t_lead_name[ran1].name1
    local name2=t_lead_name[ran2].name2
    
    if lable then
        lable:setText(name1..name2)
    end  
end

--更换昵称请求
function CharacterWidget:changeNameRequest(text) 
    local request = {}  
    request["nick"] =mime.b64(text) 
    self:request("main.userHandler.changeNick", request, function(msg)
        if msg['code'] == 200 then
            self._widget.label_name:setString(Character.name)
            local child=self._widget:getChildByTag(windowTag)
            if child then
                child:removeFromParent(true)
            end
            
        end
    end)
end

--更换头像弹窗
function CharacterWidget:changeIcon() 
    local widget= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlead_icon.csb")
    self._widget:addChild(widget,0xFF,windowTag)
    widgetUtil.widgetReader(widget)
    
    widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            widget:runAction(cc.RemoveSelf:create())
        end
    end)
    
    self:updateList(widget.list_item)   
end

--更新头像列表
function CharacterWidget:updateList(list) 
    list:removeAllItems()
    list:setBounceEnabled(true)
    
    local itemTitle=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlead_icon_title.csb")
    local itemTitle1=itemTitle:clone()
    widgetUtil.widgetReader(itemTitle1)
    itemTitle1.label_hero_icon:setVisible(false)
    itemTitle1.label_desc1:setVisible(false)
    itemTitle1.label_color:setVisible(false)
    itemTitle1.label_system_icon:setVisible(true)
    list:pushBackCustomItem(itemTitle1)
    
    local imageView = ccui.ImageView:create()
    imageView:setScale9Enabled(true)
    local ture="common/common_bg28.png"
    if cc.FileUtils:getInstance():isFileExist(ture) then
        imageView:loadTexture(ture)  
    end
    imageView:setCapInsets(cc.rect(10,10,587,72))
    imageView:setContentSize(cc.size(620,120))
    
    local imageView1=imageView:clone()
    list:pushBackCustomItem(imageView1)
    self:addItem(imageView1,true)

    local itemTitle2=itemTitle:clone()
    widgetUtil.widgetReader(itemTitle2)
    itemTitle2.label_hero_icon:setVisible(true)
    itemTitle2.label_system_icon:setVisible(false)
    list:pushBackCustomItem(itemTitle2)
    
    local imageView2=imageView:clone()
    list:pushBackCustomItem(imageView2)
    self:addItem(imageView2,false) 
end

--添加头像选择行
function CharacterWidget:addItem(imageView,free) 
    if self.itemIcon==nil then
        self.itemIcon=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIlead_icon_item.csb")
        self.itemIcon:retain()
    end
     
    local iconIds=t_parameter.lead_icon_free_id.var
    iconIds=json.decode(iconIds,1)
    if not free then
        local heroIds=Hero.getHeroByArmsLv(t_parameter.lead_icon_hero_armsLv.var)
        for i=1, #heroIds do
            for k, v in pairs(iconIds) do
                if heroIds[i]==v then
                    table.remove(heroIds,i)
                end
            end
        end
        iconIds=heroIds
    end 
     
    local n=math.ceil(#iconIds/5)
    if n~=0 then
        imageView:setContentSize(cc.size(620,10+110*n))
    end
    local size=imageView:getContentSize()
    for i=1, n do
        local itemIcon1=self.itemIcon:clone()
        self:setItem(itemIcon1,i,iconIds)
        itemIcon1:setAnchorPoint(cc.p(0.5,0.5))
        itemIcon1:setPosition(cc.p(size.width/2,size.height-110*i+50))
        imageView:addChild(itemIcon1)
    end
end

--设置列表里头像行
function CharacterWidget:setItem(widgt,n,iconIds) 
    if widgt then
        widgetUtil.widgetReader(widgt)
        local begin=5*(n-1)
        
        for i=1, 5 do
            local iconId=iconIds[begin+i]
            if iconId then
                widgt["image_icon_bottom"..i]:setVisible(true)
                widgetUtil.createIconToWidget(iconId,widgt["image_icon"..i])  --图标 
                widgetUtil.createIconToWidget(5,widgt["image_icon_bottom"..i])  -- 底框
                widgetUtil.createIconToWidget(15,widgt["image_icon_grade"..i])  -- 品质框
                
                local check_box = widgt["checkbox_item"..i]
                check_box:setTag(iconId)
                
                if iconId==Character.fashionID then
                	check_box:setSelectedState(true)
                	check_box:setEnabled(false)
                    self.curBox=check_box
                else
                    check_box:setSelectedState(false)
                end
                
                local function selectedEvent(sender,eventType)
                    if eventType == ccui.CheckBoxEventType.selected then
                        sender:setSelectedState(false)
                        local request = {} 
                        request["icon"] = iconId
                        self:request("main.userHandler.changeIcon", request, function(msg)
                            if msg['code'] == 200 then
                                if self.curBox then
                                    self.curBox:setSelectedState(false)
                                    self.curBox:setEnabled(true)
                                end
                                sender:setSelectedState(true)
                                sender:setEnabled(false)
                                self.curBox=sender
                                local icon=string.format("res/story_icon/%d.png",Character.fashionID)
                                if cc.FileUtils:getInstance():isFileExist(icon) then
                                    self._widget.Image_player:loadTexture(icon)  
                                end
                            end
                        end)                    
                    elseif eventType == ccui.CheckBoxEventType.unselected then
                       
                    end
                end            
                check_box:addEventListener(selectedEvent)              
        	else
                widgt["image_icon_bottom"..i]:setVisible(false)
        	end
        end
        
    end
end

--创建vip界面
function CharacterWidget:createVipPrivilegeWidget() 
    UIManager.pushWidget('vipPrivilegeWidget')
end


--创建系统设置界面
function CharacterWidget:createSystemSet()
    local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/.csb")
    self._widget:addChild(widget, 1)
    self._widgetSystemSet=widget
    widgetUtil.widgetReader(widget)


    --关闭按钮
    widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self._widgetVip:runAction(cc.RemoveSelf:create())    
            self._widgetVip = nil
        end
    end)

end



function CharacterWidget:onEnter()
    math.randomseed(os.time())
    local eventDispatcher = self._widget:getEventDispatcher()
end

function CharacterWidget:onExit()
    self.edit:unregisterScriptEditBoxHandler()
    if self.itemIcon then
    	self.itemIcon:release()
    end
end

--退出当前界面
function CharacterWidget:back()
    UIManager.popWidget()
end

return CharacterWidget



