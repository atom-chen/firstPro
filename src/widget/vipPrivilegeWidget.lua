
--[[
*            vip特权界面
*
]]

local BaseWidget = require('widget.BaseWidget')
local t_vip_privilege = require('config/t_vip_privilege')

local vipPrivilegeWidget = class("vipPrivilegeWidget", function()
    return BaseWidget:new()
end)

function vipPrivilegeWidget:create(save, opt)
    return vipPrivilegeWidget.new(save, opt)
end

function vipPrivilegeWidget:getWidget()
    return self._widget
end

function vipPrivilegeWidget:ctor(save)
    self:setScene(save._scene)
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIvip_privilege.csb")
    widgetUtil.widgetReader(self._widget)

    self.page= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIvip_privilege_item.csb") 
    self.page:retain()

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

    --充值按钮
    self._widget.btn_recharge:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local res = self:getScene():hasWidget('rechargeWidget')
            if res then
                UIManager.popWidget()
            else
                UIManager.pushWidget('rechargeWidget')
            end
        end
    end)
    
    --左按钮
    self._widget.btn_left:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pageToLeft()
        end
    end)
    --右按钮
    self._widget.btn_right:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then        
            self:pageToRight()
        end
    end)
    
    local imgVip=string.format("vip/%d.png",Character.vipLevel)
    if cc.FileUtils:getInstance():isFileExist(imgVip) then
        self._widget.image_vip_player:loadTexture(imgVip)  
    end

    if Character.vipLevel==Character.getMaxVip() then
        self.curVip=Character.vipLevel
        --隐藏后面
        self._widget.progress_recharge:setPercent(100)
        self._widget.label_progress_number:setVisible(false)
        self._widget.Panel_25:setVisible(false)
    else
        local diamondNeed=t_vip_privilege[Character.vipLevel].diamond  --消耗砖石数量
        self._widget.label_recharge_number:setString(tostring(diamondNeed))

        local pro=string.format("%d/%d",Character.vipExp,diamondNeed)  --进度条
        self._widget.label_progress_number:setString(pro)
        local percent=math.floor(Character.vipExp/diamondNeed*100)
        self._widget.progress_recharge:setPercent(percent)

        local imgVip=string.format("vip/%d.png",Character.vipLevel+1)  --下级vip等级
        if cc.FileUtils:getInstance():isFileExist(imgVip) then
            self._widget.image_vip_next:loadTexture(imgVip)  
        end

        self.curVip=Character.vipLevel+1
    end
      
    self:createPages()
end

function vipPrivilegeWidget:createPages()
    local widget=self._widget
    self.pageView=ccui.PageView:create()
    self.pageView:setContentSize(widget.page_item:getContentSize())
    widget.page_item:addChild(self.pageView)
    
    self.pageView:addEventListener(function(event,type)     
        if type==ccui.PageViewEventType.turning then    
            local index=self.pageView:getCurPageIndex()
            if index==0 then
            
                self:pageToLeft()
                self.pageView:scrollToPage(1)  
            elseif index==2 then
                self:pageToRight()
                self.pageView:scrollToPage(1)  
            end              
        end
    end)
    
    for i=0, 2 do
        local page= self.page:clone()
        self.pageView:addPage(page)
        self:setPage(i)
    end
    self.pageView:scrollToPage(1)
end

function vipPrivilegeWidget:pageToLeft()
    self.pageView:removePageAtIndex(2)
    self.curVip=self.curVip-1
    if self.curVip<1 then
        self.curVip=Character.getMaxVip()
    end

    local page = self.page:clone()
    self.pageView:insertPage(page,0)
    self:setPage(0)
end
function vipPrivilegeWidget:pageToRight()
    self.pageView:removePageAtIndex(0)
    self.curVip=self.curVip+1
    if self.curVip>Character.getMaxVip() then
        self.curVip=1
    end

    local page= self.page:clone()
    self.pageView:addPage(page)
    self:setPage(2)
end


function vipPrivilegeWidget:setPage(index)
    local page=self.pageView:getPage(index)
    widgetUtil.widgetReader(page)
    
    local vip=self.curVip-1+index
    
    if vip<1 then
        vip=Character.getMaxVip()
    elseif vip>Character.getMaxVip() then
        vip=1
    end
    
    --vip
    local vipLable=string.format("VIP%d",vip)
    page.label_vip_privilege:setString(tostring(vipLable))
    
    local vipCfg=t_vip_privilege[vip]
    if vipCfg then
        for i=1, 8 do
            local lab=vipCfg["privilege"..i]
            if lab~="" then
            	local str=vipCfg["privilege"..i.."_num"]
                local widget=page["label_privilege"..i]
                self:addRichLable(widget,lab,str)
            end
        end
        --vip海报
        local imgBg=string.format("activity/%d.png",vipCfg.bg)
        if cc.FileUtils:getInstance():isFileExist(imgBg) then
            page.image_bg:loadTexture(imgBg) 
        end   
    end
end

function vipPrivilegeWidget:addRichLable(widget,lable,str) 
    local result=commonUtil.split(lable,"d")  --只能有一个d
    local size=widget:getContentSize()
    
    local richText=ccui.RichText:create()
    richText:setAnchorPoint(cc.p(0.5,0.5))
    richText:ignoreContentAdaptWithSize(false)
    richText:setContentSize(size)
    richText:setPosition(size.width/2,size.height/2)    
    
    local r1=ccui.RichElementText:create(1,cc.c3b(123,58,35),255,result[1],"fonts/FZZhengHeiS-DB-GB.ttf",22)
    richText:pushBackElement(r1)

    local r2=ccui.RichElementText:create(2,cc.c3b(0,200,0),255,tostring(str),"fonts/FZZhengHeiS-DB-GB.ttf",22)
    richText:pushBackElement(r2)
    
    local r3=ccui.RichElementText:create(3,cc.c3b(123,58,35),255,result[2] or "" ,"fonts/FZZhengHeiS-DB-GB.ttf",22)
    richText:pushBackElement(r3)
    
    widget:addChild(richText) 
end

function vipPrivilegeWidget:onEnter()
    
end

function vipPrivilegeWidget:onExit()
    if self.page then
        self.page:release()
    end  
end

--退出当前界面
function vipPrivilegeWidget:back()
    UIManager.popWidget()
end

return vipPrivilegeWidget