
--[[
*        英雄装备界面  
*
]]

local t_item=require("config/t_item")
local t_skill=require("config/t_skill")
local t_lv=require("src/config/t_lv")
local t_str=require("src/config/t_str")
local t_endow=require("src/config/t_endow")
local t_endow_price=require("src/config/t_endow_price")

local BaseWidget = require('widget.BaseWidget')

local HeroEquipWidget = class("HeroEquipWidget", function()
    return BaseWidget:new()
end)

function HeroEquipWidget:create(save, opt)
    return HeroEquipWidget.new(save, opt)
end

function HeroEquipWidget:getWidget()
    return self._widget
end

function HeroEquipWidget:ctor(save, type)
    self:setScene(save._scene)

    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIlead_equip.csb")
    widgetUtil.widgetReader(self._widget)
    
    self:createEquipTab()
    self:createEquipHouse()
    
    self._position=1           --当前阵位
    self._widget["btn_hero"..self._position]:setEnabled(false)
    self._widget["btn_hero"..self._position]:setBright(false)
    self._equipFoldType=Const.EQUIP_TYPE.HERALDRY      --当前装备栏类型(纹章)
    self._widget["btn_equip"..self._equipFoldType-4]:setEnabled(false)
    self._widget["btn_equip"..self._equipFoldType-4]:setBright(false)
    self:updateFolds() 
    self._equipUniqueID=Hero.getCurEquipUid(self._position,self._equipFoldType)      --当前装备唯一Id
    if self._equipUniqueID==0 then
        self:updateEquipList()
    else  
        self:createEquipUp()
    end
    

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
            self:onBack()
        end
    end)
    
    --英雄装备库按钮
    self._widget.btn_lead_equip:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then           
            self:updateEquipList()
        end
    end)
    
    --英雄/阵位  按钮
    for i=1, 4 do
        self._widget["btn_hero"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                sender:setBright(false)
                sender:setEnabled(false)
                self._widget["btn_hero"..self._position]:setBright(true)
                self._widget["btn_hero"..self._position]:setEnabled(true)
                self._widget["btn_equip"..self._equipFoldType-4]:setBright(true)
                self._widget["btn_equip"..self._equipFoldType-4]:setEnabled(true)
                
                self._position=i
                self:updateFolds()
                self._equipFoldType=Const.EQUIP_TYPE.HERALDRY 
                self._widget["btn_equip"..self._equipFoldType-4]:setBright(false)
                self._widget["btn_equip"..self._equipFoldType-4]:setEnabled(false)
                self._equipUniqueID=Hero.getCurEquipUid(self._position,self._equipFoldType)
                if self._equipUniqueID==0 then
                    self:updateEquipList()
                else  
                    self:createEquipUp() 
                end        
            end
        end)
    end
    
    --装备栏按钮
    for j=1, 4 do
        self._widget["btn_equip"..j]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                sender:setBright(false)
                sender:setEnabled(false)
                self._widget["btn_equip"..self._equipFoldType-4]:setBright(true)
                self._widget["btn_equip"..self._equipFoldType-4]:setEnabled(true)
                
                self._equipFoldType=j+4
                self._equipUniqueID=Hero.getCurEquipUid(self._position,self._equipFoldType)
                if self._equipUniqueID==0 then
                    self:updateEquipList()
                else  
                    self:createEquipUp() 
                end   
            end
        end)
    end
    
end

--创建强化和附魔背景界面-----------------------------------------------------------------------------
function HeroEquipWidget:createEquipTab()
    self._widgetEquipTab = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIequip_tab.csb")   
    self._widget.image_tab:addChild(self._widgetEquipTab, 1)   
    widgetUtil.widgetReader(self._widgetEquipTab)
    
    --强化按钮    
    self._widgetEquipTab.btn_equip_lv:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            sender:setBright(false)
            sender:setEnabled(false)
            self._widgetEquipTab.btn_equip_enchant:setBright(true)
            self._widgetEquipTab.btn_equip_enchant:setEnabled(true)
            
            if self._widgetEndow then
                self._widgetEndow:removeFromParent(true)
                --self._widgetEndow:runAction(cc.RemoveSelf:create()) 
                self._widgetEndow=nil
            end
            self._widgetEquipUp:setVisible(true)
            self:updateAttr()
        end
    end)

    --附魔按钮    
    self._widgetEquipTab.btn_equip_enchant:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            sender:setBright(false)
            sender:setEnabled(false)
            self._widgetEquipTab.btn_equip_lv:setBright(true)
            self._widgetEquipTab.btn_equip_lv:setEnabled(true)
            
            self._widgetEquipUp:setVisible(false)
            self:createEquipEndow()
        end
    end)   
    self._widgetEquipTab:setVisible(false)
end


--创建装备库界面-----------------------------------------------------------------------------
function HeroEquipWidget:createEquipHouse()
    self._widgetChange = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIequip_change.csb")
    self._widget.image_change:addChild(self._widgetChange, 1)
    widgetUtil.widgetReader(self._widgetChange)  

    local equipItem= ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIequip_change_item.csb") 
    self._widgetChange.list_item:setItemModel(equipItem)

    self._widgetChange:setVisible(false)
end


--更新装备栏
function HeroEquipWidget:updateFolds()
    local widget = self._widget
    widgetUtil.widgetReader(widget)

    local equipsUId=Hero.getEquipsIdByPos(self._position)

    for i=1,4 do           
        local equip=Character.getEquipByUniqueID(equipsUId[i])
        local image_icon_grade=widget["image_equip"..i.."_icon_grade"]
        local image_icon=widget["image_equip"..i.."_icon"]
        image_icon_grade:removeAllChildren()
        image_icon:removeAllChildren()
        
        local equipFold=Hero.getCurEquipFold(self._position,i+4)
        widget["label_equip"..i.."_lv"]:setString(tostring(equipFold._level))
        
        if equip then
            local equipConfig=t_item[equip._itemID]
            widgetUtil.createIconToWidget(equipConfig.grade,image_icon_grade)
            widgetUtil.createIconToWidget(equipConfig.icon,image_icon)    
            widget["bg_equip"..i.."_icon_min"]:setVisible(true)
            widget["label_equip"..i.."_lv"]:setVisible(true)
        else
            widget["bg_equip"..i.."_icon_min"]:setVisible(false)
            widget["label_equip"..i.."_lv"]:setVisible(false)
        end          
    end    
end

--更新装备栏等级
function HeroEquipWidget:updateFoldsLv()
    local widget = self._widget
    local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)
    
    widget["label_equip"..(self._equipFoldType-4).."_lv"]:setString(tostring(equipFold._level))
end


--强化--------------------------------------------------------------------------------------

--创建装备强化界面
function HeroEquipWidget:createEquipUp()
    self._widgetEquipTab:setVisible(true)
    self._widgetChange:setVisible(false)
    widgetUtil.widgetReader(self._widgetEquipTab)
    self._widgetEquipTab.btn_equip_lv:setBright(false)
    self._widgetEquipTab.btn_equip_lv:setEnabled(false)
    self._widgetEquipTab.btn_equip_enchant:setBright(true)
    self._widgetEquipTab.btn_equip_enchant:setEnabled(true)
    
    if self._widgetEquipUp then
    	self._widgetEquipUp:removeFromParent(true)
        --self._widgetEquipUp:runAction(cc.RemoveSelf:create()) 
    	self._widgetEquipUp=nil
    end
    if self._widgetEndow then
        self._widgetEndow:removeFromParent(true)
        --self._widgetEndow:runAction(cc.RemoveSelf:create()) 
        self._widgetEndow=nil
    end
    
    local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIequip_lv.csb")
    self._widgetEquipTab.image_lv:addChild(widget, 1)
    self._widgetEquipUp=widget
    widgetUtil.widgetReader(widget)  
    
    local equip=Character.getEquipByUniqueID(self._equipUniqueID)   --获得装备       
    if equip==nil then
    	return
    end

    --local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)   
    
    local typeStr=commonUtil.split(Str.EQUIP_TYPE,"|")
    widget.label_type:setString(typeStr[self._equipFoldType-4])              --装备类型：武器,盾牌,铠甲，宝具
    widget.label_name:setString(t_item[equip._itemID].name)                            --装备名字
    
    self:updateStar(widget,equip._quality)                                   --装备品质/星级标识
    
    local attrConfigs=equip:getAttrConfigs()                                 --装备四个属性
    for i=1,#attrConfigs do
        local attBg=equip:getAttBg(attrConfigs[i].grade)
        widgetUtil.createIconToWidget(attBg,widget["bg_attri"..i])
        widget["label_attri"..i]:setString(attrConfigs[i].name)
    end

    local equip_stone=equip:getEquipStone(self._equipFoldType)
    widgetUtil.createIconToWidget(equip_stone,widget.image_lv_stone_icon)    --装备强化石图标
    
    --强化按钮
    widget.btn_lv:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:equipUpRequest()  
        end
    end)
   
    self:updateLv()
end

--装备强化请求
function HeroEquipWidget:equipUpRequest()
    local request = {}
    request["pos"]=self._position
    request["etype"] = self._equipFoldType

    self:request("main.equipHandler.strengthen", request, function(msg)
        if msg['code'] == 200 then
            self:updateLv()
        end
    end)
end  

--装备栏等级强化   需要改变的组件处理
function HeroEquipWidget:updateLv()    
    local widget = self._widgetEquipUp
    
    local equip=Character.getEquipByUniqueID(self._equipUniqueID)   --获得装备    
    
    local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)
    
    widget.label_lv:setString(tostring(equipFold._level))                       --装备栏等级
    widget.label_proba:setString(tostring(t_lv[equipFold._level].equip_up_grow))    --成长率 
    
    local dif=equip:getDifAttr(equipFold._level)

    --widget.label_power_up:setString("+"..tostring(attrValueAddition.atk))
    widget.label_atk_up:setString("+"..tostring(dif.atk))
    widget.label_hp_up:setString("+"..tostring(dif.hp))
    widget.label_def_water_up:setString("+"..tostring(dif.defWater))
    widget.label_der_fire_up:setString("+"..tostring(dif.defFire))
    widget.label_def_wood_up:setString("+"..tostring(dif.defWood))
                      
    local itemID = Item.getItemIDByEquipType(self._equipFoldType) 
    local num = Item.getNum(Const.ITEM.STRENTHEN_STONE_TYPE,itemID)
    widget.label_lv_stone_number:setString(tostring(num))               --强化石数量
    
    local gold_cost=t_lv[equipFold._level].equip_up_cost
    widget.lable_gold_cost:setString(tostring(gold_cost))               --消耗金币数量
    widget.lable_gold_all:setString(tostring(Character.gold))                                     --总金币
    local percent=equipFold._exp/t_lv[equipFold._level].equip_up_exp*100
    widget.progress_lv:setPercent(percent)         --进度条    
    widget.label_progress_number:setString(tostring(math.ceil(percent)))         --进度值
    
    if num<=0 or Character.gold<gold_cost  then     
        widget.btn_lv:setEnabled(false)
        widget.btn_lv:setBright(false)
    end
    
    self:updateFoldsLv()
    self:updateAttr()
end

--更新装备属性值（附魔和等级都会改变）
function HeroEquipWidget:updateAttr()    
    local widget = self._widgetEquipUp
    local equip=Character.getEquipByUniqueID(self._equipUniqueID)   --获得装备    
    local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)
    
    local value=equip:getAttrLastValue(equipFold)                   --装备各属性值

    --widget.label_power:setString(tostring(equip:getFCAddition())) 
    widget.label_atk:setString(tostring(value.atk))   
    widget.label_hp:setString(tostring(value.hp))   
    widget.label_def_water:setString(tostring(value.defWater))   
    widget.label_der_fire:setString(tostring(value.defFire))
    widget.label_def_wood:setString(tostring(value.defWood))
end



--附魔----------------------------------------------------------------------

--创建附魔界面
function HeroEquipWidget:createEquipEndow()
 
    local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIequip_enchant.csb")
    self._widgetEquipTab.image_enchant:addChild(widget, 1)
    self._widgetEndow=widget
    widgetUtil.widgetReader(widget)  

    local equip=Character.getEquipByUniqueID(self._equipUniqueID)   --获得装备       

    local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)   

    local typeStr=commonUtil.split(Str.EQUIP_TYPE,",")
    widget.label_type:setString(typeStr[self._equipFoldType-4])              --装备类型：武器,盾牌,铠甲，宝具
    widget.label_name:setString(t_item[equip._itemID].name)                            --装备名字

    self:updateStar(widget,equip._quality)                                   --装备品质/星级标识

    widget.label_lv:setString(tostring(equipFold._level))                       --装备栏等级
    widget.label_proba:setString(tostring(t_lv[equipFold._level].equip_up_grow))    --成长率 

    widgetUtil.createIconToWidget(Const.ITEM.ENDOW_STONE_ITEM_ID,widget.image_enchant_stone_icon)      --附魔石图标
    
    local endow=equipFold._endow
    local lockNumMag=nil      --更新所需资源函数
    local lockNum=0      --上锁个数
    
    --四个复选框，是否附魔
    for i=1, 4 do
        if endow[i]._lock==1 then       
            widget["checkbox_lock"..i]:setSelectedState(true)
        end
        widget["checkbox_lock"..i]:addEventListener(function(sender,eventType)
            if eventType == ccui.CheckBoxEventType.selected then
                sender:setSelectedState(true)
                endow[i]._lock=1

            elseif eventType == ccui.CheckBoxEventType.unselected then
                sender:setSelectedState(false)
                endow[i]._lock=0
            end
            lockNumMag()
        end)
    end     

    lockNumMag=function()
        lockNum=0
        for key, var in pairs(endow) do   --获得上锁个数
            if var._lock==1 then
                lockNum=lockNum+1
            end
        end

        widget.lable_diamond_cost:setString(t_endow_price[lockNum].diamond)   --需要消耗的附魔石数量
      
    end

    lockNumMag()

    --附魔按钮
    widget.btn_enchant:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:equipEndowRequest(endow)  
        end
    end)

    self:updateEquipEndow()
end

--装备附魔请求
function HeroEquipWidget:equipEndowRequest(endow)
    local request = {}
    local lock={}
    for i, var in pairs(endow) do
        lock[i]=var._lock
    end
    request["pos"]=self._position
    request["etype"] = self._equipFoldType
    request["lock"]=lock
    self:request("main.equipHandler.endow", request, function(msg)
        if msg['code'] == 200 then
            self:updateEquipEndow()
        end
    end)
end  

--更新附魔界面
function HeroEquipWidget:updateEquipEndow()
    local widget = self._widgetEndow
    if nil == self._widgetEndow then
        return
    end
    
    widgetUtil.widgetReader(widget) 
    
    local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)
    local endow=equipFold._endow   

    local colors={Const.COLOR.GREEN,Const.COLOR.BLUE,Const.COLOR.PURPLE,Const.COLOR.RED,Const.COLOR.GOLDEN}  --五种颜色

    --附魔
    for i=1, 4 do
        widget["label_endow"..i.."_text"]:setString(t_endow[endow[i]._id].name)              --附魔属性名
        widget["label_endow"..i.."_text"]:setColor(colors[t_endow[endow[i]._id].grade])
        
        local attValue=string.format("+%d",endow[i]._num)
        widget["label_endow"..i]:setString(attValue)                          --附魔属性值 
        widget["label_endow"..i]:setColor(colors[t_endow[endow[i]._id].grade])
        
        local range=string.format("%d~%d",t_endow[endow[i]._id].var1,t_endow[endow[i]._id].var2)   --附魔属性范围
        widget["label_endow"..i.."_range"]:setString(range)
        widget["label_endow"..i.."_range"]:setColor(colors[t_endow[endow[i]._id].grade])
    end
    
    local num=Item.getNum(Const.ITEM.ENDOW_STONE_TYPE, Const.ITEM.ENDOW_STONE_ITEM_ID)
    widget.label_enchant_stone_number:setString(tostring(num))                                     --现有附魔石
    
    widget.lable_diamond_all:setString(tostring(Character.diamond))                                     --总砖石
    
    if num<1 and Character.diamond<tonumber(widget.lable_diamond_cost:getString()) then
        widget.btn_enchant:setEnabled(false)
        widget.btn_enchant:setBright(false)
    end
    
end



--装备列表----------------------------------------------------------------------

--更新装备列表
function HeroEquipWidget:updateEquipList()
    self._widgetChange:setVisible(true)
    self._widgetEquipTab:setVisible(false)
    
    local widget = self._widgetChange
    
    --local equipFold=Hero.getCurEquipFold(self._position,self._equipFoldType)   
    
    widget.list_item:removeAllItems()
    local typeEquips=Hero.getUnEquipsIdByType(self._equipFoldType)

    for i=1, #typeEquips do
        widget.list_item:pushBackDefaultItem()     
        local equipItem=widget.list_item:getItem(i-1)
        widgetUtil.widgetReader(equipItem)
        
        widgetUtil.createIconToWidget(t_item[typeEquips[i]._itemID].grade,equipItem.image_icon_grade)     --装备品质对应的颜色图标
        widgetUtil.createIconToWidget(t_item[typeEquips[i]._itemID].icon,equipItem.image_icon)            --装备品质对应的图标
        
        equipItem.label_equip_name:setString(t_item[typeEquips[i]._itemID].name)        --装备名
        equipItem.label_power:setString(tostring(""))                                   --战斗力
        
        --更换按钮
        equipItem.btn_change:addTouchEventListener(function(sender, eventType)         
            if eventType == ccui.TouchEventType.ended then
                self.choosedUniqueID=typeEquips[i]._uniqueID
                self:changeRquest()
            end
        end)
        
        --出售按钮
        equipItem.btn_sell:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self.choosedUniqueID=typeEquips[i]._uniqueID
                self:sellRequest()
            end
        end)   
            
    end   
end

--更换装备请求
function HeroEquipWidget:changeRquest()
    local request = {}
    request["pos"]=self._position
    request["etype"] = self._equipFoldType
    request["eid"] =self.choosedUniqueID 
    self:request("main.equipHandler.change", request, function(msg)
        if msg['code'] == 200 then    
            self._equipUniqueID = self.choosedUniqueID  
            self:updateFolds()
            self:createEquipUp()
        end
    end)
end
--装备出售请求
function HeroEquipWidget:sellRequest()
    local request={}
    request["eid"]=self.choosedUniqueID
    self:request("main.equipHandler.discard", request, function(msg)
        if msg['code'] == 200 then
            Character.removeEquip(self.choosedUniqueID)
            self:updateEquipList() 
        end
    end)
end



--更新星级显示/装备品质
function HeroEquipWidget:updateStar(widget, grade)
    --星级
    local image_star1 = ccui.Helper:seekWidgetByName(widget,"image_star1")
    if grade >= 1 then
        image_star1:setVisible(true)
    else
        image_star1:setVisible(false)
    end
    local image_star2 = ccui.Helper:seekWidgetByName(widget,"image_star2")
    if grade >= 2 then
        image_star2:setVisible(true)
    else
        image_star2:setVisible(false)
    end
    local image_star3 = ccui.Helper:seekWidgetByName(widget,"image_star3")
    if grade >= 3 then
        image_star3:setVisible(true)
    else
        image_star3:setVisible(false)
    end
    local image_star4 = ccui.Helper:seekWidgetByName(widget,"image_star4")
    if grade >= 4 then
        image_star4:setVisible(true)
    else
        image_star4:setVisible(false)
    end
    local image_star5 = ccui.Helper:seekWidgetByName(widget,"image_star5")
    if grade >= 5 then
        image_star5:setVisible(true)
    else
        image_star5:setVisible(false)
    end
end


function HeroEquipWidget:onEnter()

--    eventUtil.addCustom(self._widget,"ui_equip_info_on_show_change_click",function(event)HeroEquipWidget.onShowChangeEquip(self,event.param)end)
end

function HeroEquipWidget:onExit()

    eventUtil.removeCustom(self._widget)
end

--退出当前界面
function HeroEquipWidget:onBack()
    UIManager.popWidget()
end

return HeroEquipWidget

