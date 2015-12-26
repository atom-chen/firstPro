

--[[
*          充值界面
*
]]

local BaseWidget = require('widget.BaseWidget')
local t_vip_privilege = require('config/t_vip_privilege')
local t_vip_recharge = require('config/t_vip_recharge')

local RechargeWidget = class("RechargeWidget", function()
    return BaseWidget:new()
end)

function RechargeWidget:create(save, opt)
    return RechargeWidget.new(save, opt)
end

function RechargeWidget:getWidget()
    return self._widget
end

function RechargeWidget:ctor(save)
    self:setScene(save._scene)    
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIvip_recharge.csb")
    widgetUtil.widgetReader(self._widget)

    local vipItem= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIvip_recharge_item.csb") 
    self._widget.list_item:setItemModel(vipItem)  
    self._widget.list_item:setBounceEnabled(true)

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
    
    self._widget.btn_privilege:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local res = self:getScene():hasWidget('vipPrivilegeWidget')
            if res then
                UIManager.popWidget()
            else
                UIManager.pushWidget('vipPrivilegeWidget')
            end
        end
    end)
    
    local imgVipCur=string.format("vip/%d.png",Character.vipLevel)
    if cc.FileUtils:getInstance():isFileExist(imgVipCur) then
        self._widget.image_vip_player:loadTexture(imgVipCur) 
    end

    if Character.vipLevel==Character.getMaxVip() then
        --隐藏后面
        self._widget.progress_recharge:setPercent(100)
        self._widget.label_progress_number:setVisible(false)
        self._widget.Panel_26:setVisible(false)
    else
        local diamondNeed=t_vip_privilege[Character.vipLevel].diamond
        self._widget.label_recharge_number:setString(tostring(diamondNeed))

        local pro=string.format("%d/%d",Character.vipExp,diamondNeed)
        self._widget.label_progress_number:setString(pro)
        local percent=math.floor(Character.vipExp/diamondNeed*100)
        self._widget.progress_recharge:setPercent(percent)

        local imgVip=string.format("vip/%d.png",Character.vipLevel+1)
        if cc.FileUtils:getInstance():isFileExist(imgVip) then
            self._widget.image_vip_next:loadTexture(imgVip) 
        end
    end

    self:createList()
end

--排序
local function sortRecharge(a,b)
    if a.recommend == b.recommend then
        if a.rmb == b.rmb then
            return a.send > b.send
        else
            return a.rmb < b.rmb
        end
    else
        return a.recommend > b.recommend  
    end
end

--更新列表
function RechargeWidget:createList()
    local widget=self._widget
       
    table.sort(t_vip_recharge,sortRecharge)
    
    local row = math.ceil(#t_vip_recharge / 2)
    for i=1, row do
        widget.list_item:pushBackDefaultItem()
        local item=widget.list_item:getItem(i-1) 
        local index = (i-1) * 2
        self:updateItemInfo(item:getChildByName('bg_item1'), t_vip_recharge[index+1])
        self:updateItemInfo(item:getChildByName('bg_item2'), t_vip_recharge[index+2])
    end
end

--更新列表里选项的信息
function RechargeWidget:updateItemInfo(item,recharge)
    if nil == recharge then
        item:setVisible(false)
    else   
        widgetUtil.widgetReader(item)
        
        --按钮
        item.btn_item:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local lable=string.format(Str.RECHARGE_DIAMOND,recharge.rmb,recharge.name)
                widgetUtil.showConfirmBox(lable, 
                    function()
                        self:yesBtnClick()
                    end)
            end
        end)
        
        widgetUtil.createIconToWidget(recharge.icon ,item.image_icon)      --充值图标
        widgetUtil.createIconToWidget(15,item.image_icon_grade)      --充值图标品质
        widgetUtil.createIconToWidget(5,item.image_icon_bottom)      --充值图标底框

        item.label_name:setString(recharge.name)       --充值名字
        item.label_rmb:setString(tostring(recharge.rmb))   --充值需要人民币
        item.label_send_desc:setString(recharge.send_desc)  --充值额外赠送描述
        
        if recharge.recommend==1 then
        	item.image_recommend:setVisible(true)
    	else
            item.image_recommend:setVisible(false)
        end
    end
end

function RechargeWidget:yesBtnClick()

end

function RechargeWidget:onEnter()
    
end

function RechargeWidget:onExit()

end

--退出当前界面
function RechargeWidget:back()
    UIManager.popWidget()
end

return RechargeWidget