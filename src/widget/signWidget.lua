
--[[
*           签到界面
*
]]

local BaseWidget = require('widget.BaseWidget')
local t_item = require('config/t_item')

local SignWidget = class("SignWidget", function()
    return BaseWidget:new()
end)

function SignWidget:create(save, opt)
    return SignWidget.new(save, opt)
end

function SignWidget:getWidget()
    return self._widget
end

function SignWidget:ctor(save)
    self:setScene(save._scene)

    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIsign.csb")
    widgetUtil.widgetReader(self._widget)

    self.cell= ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIsign_item.csb") 
    self.cell:retain()

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
    --金币充值按钮
    self._widget.btn_gold_buy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.pushWidget('goldBuyWidget')
        end
    end)

    --砖石充值按钮
    self._widget.btn_diamond_buy:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.pushWidget('rechargeWidget')
        end
    end)
    
    self:updateNum()
    self:createTableView()
    
    if Sign.isFirst() then     
        self:firstAnimation()
    end
end

--上方数值
function SignWidget:updateNum()
    local widget=self._widget
    widget.label_gold:setString(tostring(Character.gold))
    widget.label_diamond:setString(tostring(Character.diamond))
    local month=Sign.getMonth()
    widget.label_month:setString(tostring(month))  --月份
    local signDays=Sign.getSignDays()
    widget.label_sign_number:setString(tostring(signDays))  --签到次数
end

--签到动画
function SignWidget:firstAnimation()
    self.table:setTouchEnabled(false)
    local imageSign=self.imageSign
    local parent=imageSign:getParent()    
    local posX,posY = imageSign:getPosition()           
    local pos=parent:convertToWorldSpace(cc.p(posX,posY)) 
    pos = self._widget.nodePanel:convertToNodeSpace(pos)
    
    local animation=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIsign_item_animation.csb")  --动画
    animation:setAnchorPoint(cc.p(0.5,0.5))
    animation:setPosition(cc.p(pos.x,pos.y)) 
    self._widget.nodePanel:addChild(animation,0xFF)
    
    local img=ccui.Helper:seekWidgetByName(animation,"image_sign")
    img:setVisible(false)
    
    parent:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function()
        img:setVisible(true)
        ccs.ActionManagerEx:getInstance():playActionByName("UIsign_item_animation.csb","Animation0",cc.CallFunc:create(function()
            imageSign:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function()
                imageSign:setVisible(true)
                animation:runAction(cc.RemoveSelf:create())
                self.table:setTouchEnabled(true)
                self:createConfirm()
                Sign.setSignAlready()
            end)))
        end))
    end)))     
end

function SignWidget:createTableView()
    local widget=self._widget
    local size=widget.image_list:getContentSize()    
    local tableView=cc.TableView:create(size)
    self.table = tableView
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setDelegate()
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    widget.image_list:addChild(tableView)
    
    tableView:registerScriptHandler(function(t,cell) self:tableCellTouched(t,cell) end, cc.TABLECELL_TOUCHED)  
    tableView:registerScriptHandler(function(t,index) return self:cellSizeForTable(t, index) end, cc.TABLECELL_SIZE_FOR_INDEX)  
    tableView:registerScriptHandler(function(t,index) return self:tableCellAtIndex(t, index) end, cc.TABLECELL_SIZE_AT_INDEX)   
    tableView:registerScriptHandler(function(t) return self:numberOfCellsInTableView(t) end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
    tableView:reloadData() 
    
    local size=self.cell:getContentSize()
    local signDays=Sign.getSignDays()
    local row=math.ceil((signDays/5)-2) 
    if row>0 then
        local move=row-math.ceil(self.cells/2)
        if row+2<self.cells then
            tableView:setContentOffset(cc.p(0, size.height*move))
        else
            tableView:setContentOffset(cc.vertex2F(0, size.height*(move-1)))
        end 
    end
end

function SignWidget:tableCellTouched(table,cell)
    print("touched"..cell:getIdx())
end

function SignWidget:cellSizeForTable(table,index)
    local size=self.cell:getContentSize()
    return size.height,size.width   --148，740
end

function SignWidget:tableCellAtIndex(table,index)
    local rewards=Sign.getSignItems()
    local tableCell = table:dequeueCell()
    local signDays=Sign.getSignDays()
    local monthDays=Sign.getMonthDays()
    local cell=nil
    if nil == tableCell then
        tableCell = cc.TableViewCell:new()

        cell = self.cell:clone()   --层中的东西
        cell:setTag(1)
        for i=1, 5 do   
            if nil==self.item then
                self.item=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIitem_icon.csb")  --物品
                self.item:retain()
            end 
            local item = self.item:clone()  --物品
            item:setTag(i)
            local bgItem=cell:getChildByName("bg_item"..i)
            local cellItem=ccui.Helper:seekWidgetByName(bgItem,"panel_item_icon")
            local size=cellItem:getContentSize()
            item:ignoreAnchorPointForPosition(true)
            item:setPosition(size.width/2,size.height/2)
        
            cellItem:addChild(item)
        end
        tableCell:addChild(cell)
    end

    cell = tableCell:getChildByTag(1)
    if nil~=cell then
        for i=1, 5 do
            local day=index*5+i
            local bgItem=cell:getChildByName("bg_item"..i)
            if day>monthDays then
            	bgItem:setVisible(false)
            else    
                bgItem:setVisible(true)
                local imageSign=ccui.Helper:seekWidgetByName(bgItem,"image_sign")   --签到图标
                if day>signDays then
                    imageSign:setVisible(false)               
                else
                    imageSign:setVisible(true)
                    if day == signDays then
                        self.imageSign=imageSign
                        if Sign.isFirst() then
                            imageSign:setVisible(false) 
                        end
                    end
                end
                
                local imageVip=ccui.Helper:seekWidgetByName(bgItem,"image_vip")   --vip图标
                if rewards[day].vip then
                    imageVip:setVisible(true)
                    local image=string.format("vip/sign_vip%d.png",rewards[day].vip)
                    if cc.FileUtils:getInstance():isFileExist(image) then
                        imageVip:loadTexture(image)
                    end
                else
                    imageVip:setVisible(false)                    
                end

                local cellItem=ccui.Helper:seekWidgetByName(bgItem,"panel_item_icon")
                local item = cellItem:getChildByTag(i)        
                widgetUtil.widgetReader(item)

                local itemId=rewards[day].itemID
                local itemConfig=t_item[itemId] 
                widgetUtil.createIconToWidget(itemConfig.grade+10,item.image_item_grade)  --物品品质
                widgetUtil.createIconToWidget(itemConfig.icon,item.image_item)      --物品图标
                widgetUtil.createIconToWidget(itemConfig.grade,item.image_item_bottom)      --物品底宽
                
                local num=rewards[day].num
                item.label_item_num:setString(tostring(num))                      --物品数量
                
                local xLv=tonumber(itemConfig.xlv) or 0          --星级
                for k=1, Const.MAX_STAR do
                    if xLv == k then
                        item["image_star"..k]:setVisible(true)
                    else
                        item["image_star"..k]:setVisible(false)
                    end
                end
            end
        end 
    end 

    return tableCell
end

function SignWidget:numberOfCellsInTableView(table)
    local monthDays=Sign.getMonthDays()

    if monthDays>30 then
        self.cells=7
    else
        self.cells=6
    end
    
    return self.cells  --层数
end

--签到领取确认
function SignWidget:createConfirm()
    local widget=self._widget
    local confirmWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UImessage_box_6.csb")
    local size=widget:getContentSize()
    confirmWidget:setAnchorPoint(cc.p(0.5,0.5))
    confirmWidget:setPosition(size.width/2,size.height/2)
    widget:addChild(confirmWidget)
    widgetUtil.widgetReader(confirmWidget)
    
    confirmWidget:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            confirmWidget:runAction(cc.RemoveSelf:create())
            confirmWidget=nil
        end
    end)
    
    local items = Item.getRewardItems() --itemID=1001,num=1
    for i=1, 4 do
    	if i==#items then
    		confirmWidget["rewards"..i]:setVisible(true)
            local n=i*(i-1)/2
            for j=1, #items do
                local itemId=items[j].itemID
                local itemConfig=t_item[itemId] 
                local num=items[j].num 
                local idex=n+j
                
                if itemConfig then
                    local itemWidget=self.item:clone()
                    local size=confirmWidget["panel_item"..idex]:getContentSize()
                    itemWidget:ignoreAnchorPointForPosition(true)
                    itemWidget:setPosition(size.width/2,size.height/2)
                    confirmWidget["panel_item"..idex]:addChild(itemWidget)

                    widgetUtil.widgetReader(itemWidget)

                    widgetUtil.createIconToWidget(itemConfig.grade+10,itemWidget.image_item_grade)  --物品品质
                    widgetUtil.createIconToWidget(itemConfig.icon,itemWidget.image_item)      --物品图标 
                    widgetUtil.createIconToWidget(itemConfig.grade,itemWidget.image_item_bottom)  --物品底宽

                    itemWidget.label_item_num:setString(tostring(num))

                    local xLv=tonumber(itemConfig.xlv) or 0
                    for k=1, Const.MAX_STAR do
                        if xLv == k then
                            itemWidget["image_star"..k]:setVisible(true)
                        else
                            itemWidget["image_star"..k]:setVisible(false)
                        end
                    end
                end 
    		end
    	else
            confirmWidget["rewards"..i]:setVisible(false)
    	end
    end   
end

function SignWidget:onEnter()

end

function SignWidget:onExit()
    if self.cell then
        self.cell:release()
    end
    
    if self.item then
        self.item:release()
    end  
end

--退出当前界面
function SignWidget:back()
    UIManager.popWidget()
end

return SignWidget