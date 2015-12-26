local BaseWidget = require('widget.BaseWidget')

local t_item=require('config/t_item')
local t_sangreal=require('config/t_sangreal')
local t_sangreal_up=require('config/t_sangreal_up')

local SangrealWidget = class("SangrealWidget", function()
    return BaseWidget:new()
end)

function SangrealWidget:create(save, opt)
    return SangrealWidget.new(save, opt)
end

function SangrealWidget:getWidget()
    return self._widget
end

function SangrealWidget:ctor(save)
    self:setScene(save._scene)
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIsangreal_infomation.csb")
    widgetUtil.widgetReader(self._widget)

    --self.curId=sangrealId
    self.curId=Sangreal.getCurSangrealId()
    
    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    --返回按钮
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:back()
        end
    end)
    --向左按钮
    self._widget.btn_left:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onLeft()
        end
    end)
    --向右按钮
    self._widget.btn_right:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onRight()
        end
    end)
    --保护按钮
    self._widget.btn_piece_protect:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onProtect()
        end
    end)
    --强化按钮
    self._widget.btn_piece_up:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onUpRequest()
        end
    end)
    
    self:updatePiece()
    self:updateSangreal(self.curId)
end

function SangrealWidget:updatePiece()

    local widget=self._widget   
    
    --碎片一
    local piece1Icon=t_item[Const.SANGREAL_PIECE.ONE_ID]["icon"]
    --widgetUtil.createIconToWidget(piece1Icon,widget.bg_piece1_icon)
    local num1 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.ONE_ID)
    widget.label_piece1_number:setString(tostring(num1))
    
--    schedule(widget.label_piece1_number,function ()
--        local ti=tonumber(widget.label_piece1_number:getString())
--        if ti<0 then
--            widget.label_piece1_number:stopAllActions()
--        else
--            widget.label_piece1_number:setString(tostring(ti-1))
--        end     
--    end,1)

    widget.btn_piece1:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.ONE_ID)
        end
    end)
    
    --碎片二
    local piece2Icon=t_item[Const.SANGREAL_PIECE.TWO_ID]["icon"]
    --widgetUtil.createIconToWidget(piece2Icon,widget.bg_piece2_icon)
    local num2 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.TWO_ID)
    widget.label_piece2_number:setString(tostring(num2))
    widget.btn_piece2:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.TWO_ID)
        end
    end)
    
    --碎片三
    local piece3Icon=t_item[Const.SANGREAL_PIECE.THREE_ID]["icon"]
    --widgetUtil.createIconToWidget(piece3Icon,widget.bg_piece3_icon)
    local num3 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.THREE_ID)
    widget.label_piece3_number:setString(tostring(num3))
    widget.btn_piece3:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.THREE_ID)
        end
    end)
    
    --碎片四
    local piece4Icon=t_item[Const.SANGREAL_PIECE.FOUR_ID]["icon"]
    --widgetUtil.createIconToWidget(piece4Icon,widget.bg_piece4_icon)
    local num4 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.FOUR_ID)
    widget.label_piece4_number:setString(tostring(num4))
    widget.btn_piece4:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.FOUR_ID)
        end
    end)
    
    --碎片五
    local piece5Icon=t_item[Const.SANGREAL_PIECE.FIVE_ID]["icon"]
    --widgetUtil.createIconToWidget(piece5Icon,widget.bg_piece5_icon)
    local num5 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.FIVE_ID)
    widget.label_piece5_number:setString(tostring(num5))
    widget.btn_piece5:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.FIVE_ID)
        end
    end)
    
    --碎片六
    local piece6Icon=t_item[Const.SANGREAL_PIECE.SIX_ID]["icon"]
    --widgetUtil.createIconToWidget(piece6Icon,widget.bg_piece6_icon)
    local num6 = Sangreal.getFragmentNum(Const.SANGREAL_PIECE.SIX_ID)
    widget.label_piece6_number:setString(tostring(num6))
    widget.btn_piece6:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:pieceRequest(Const.SANGREAL_PIECE.SIX_ID)
        end
    end)
    
    
    --保护
    local protect_number=Sangreal.getProtectCard()
    widget.label_protect_number:setString(tostring(protect_number))
        
end

function SangrealWidget:pieceRequest(pieceId)
    local request = {}
    request["ftype"] = pieceId

    self:request("sangreal.sangrealHandler.entry", request, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('sangrealRobWidget',pieceId)
        end
    end)
end

function SangrealWidget:updateSangreal(sangrealId)
    local widget=self._widget
    
    local sangreal_name=t_sangreal[sangrealId]["name"]             --圣杯名字
    widget.label_sangreal_name:setString(sangreal_name)
    
    local lv=Sangreal.getSangrealLv(sangrealId)                   --圣杯等级
    local _lv=string.format("lv."..lv)
    widget.label_sangreal_lv:setString(_lv)
    
    if not Sangreal.isFragmentEnough(lv) then
        self._widget.btn_piece_up:setEnabled(false)
        self._widget.btn_piece_up:setBright(false)
    else
        self._widget.btn_piece_up:setEnabled(true)
        self._widget.btn_piece_up:setBright(true)
    end
       
    lv=lv+1
    if lv>99 then
        lv=99
    end   
    local piece_cost=t_sangreal_up[lv]["piece_cost"]
    widget.label_piece_cost:setString(tostring(piece_cost))
        
    local sangrealIcon=t_sangreal[sangrealId]["icon"]
    widgetUtil.createIconToWidget(sangrealIcon,widget.image_sangreal_icon)
       
    local values=Sangreal.getSangrealAttAddition(sangrealId)
    
    local sangreal_desc1=t_sangreal[sangrealId]["desc1"]
    sangreal_desc1=string.format(sangreal_desc1,values[1])
    widget.label_sangreal_desc1:setString(sangreal_desc1)
    
    local sangreal_desc2=t_sangreal[sangrealId]["desc2"]
    sangreal_desc2=string.format(sangreal_desc2,values[2])
    widget.label_sangreal_desc2:setString(sangreal_desc2)
    
    local sangreal_desc3=t_sangreal[sangrealId]["desc3"]
    sangreal_desc3=string.format(sangreal_desc3,values[3])
    widget.label_sangreal_desc3:setString(sangreal_desc3)
    
end

function SangrealWidget:onLeft()
    self.curId=self.curId-1
    if self.curId==0 then
    	self.curId=5
    end
    self:updateSangreal(self.curId)
end
function SangrealWidget:onRight()
    self.curId=self.curId+1
    if self.curId==6 then
        self.curId=1
    end
    self:updateSangreal(self.curId)
end
function SangrealWidget:onProtect()
    --弹窗提示是否购买保护卡
    self:showTip("是否购买保护卡")
    if true then
    	--self:onBuyRequest()
    else
    
    end    
end

function SangrealWidget:onBuyRequest()
    local request = {}
    request["num"] = 1

    self:request("sangreal.sangrealHandler.fragBuy", request, function(msg)
        if msg['code'] == 200 then
            local protect_number=Sangreal.getProtectCard()
            self._widget.label_protect_number:setString(tostring(protect_number))
        end
    end)
end

function SangrealWidget:onUpRequest()
    local request = {}
    request["stype"] = self.curId

    self:request("sangreal.sangrealHandler.strength", request, function(msg)
        if msg['code'] == 200 then
            self:updatePiece()
            self:updateSangreal(self.curId)
        end
    end)
end


function SangrealWidget:onEnter()
    local eventDispatcher = self._widget:getEventDispatcher()

end
function SangrealWidget:onExit()
   
end

--退出当前界面
function SangrealWidget:back()
    if self.curId~=Sangreal.getCurSangrealId() then
    	--弹窗是否保存
    	if true then
    		self:saveRequest()
    	else
    	
    	end
    else
        UIManager.popWidget()
    end   
end
function SangrealWidget:saveRequest()
    local request = {}
    request["stype"] = self.curId

    self:request("sangreal.sangrealHandler.save", request, function(msg)
        if msg['code'] == 200 then
            UIManager.popWidget()
        end
    end)
end


return SangrealWidget
