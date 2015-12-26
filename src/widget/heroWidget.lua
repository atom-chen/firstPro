--[[
*           英雄信息界面
*
]]
--module require
local BaseWidget = require('widget.BaseWidget')
local t_skill=require('config/t_skill')
local t_lv =require('config/t_lv')
local t_item=require('config/t_item')
local t_talent=require('config/t_talent')
local t_xlv=require('config/t_xlv')
local t_chapter=require('config/t_chapter')
local t_hero_equip=require('config/t_hero_equip')
local t_chapter_fuben=require('config/t_chapter_fuben')
local equipDescWidgetTag=100
local equipCraftedWidgetTag=101
local moveX=225

local HeroWidget = class("HeroWidget", function()
    return BaseWidget:new()
end)

function HeroWidget:create(save, opt)
    return HeroWidget.new(save, opt)
end

function HeroWidget:getWidget()
    return self._widget
end

function HeroWidget:onSave()
    local save = {}
    save["id"] = self.heroInList._heroID
    return save
end

function HeroWidget:ctor(save, id)
    self:setScene(save._scene)
    
    if save._save then
        id = save._save["id"]
    end   
    
    self.heroInList=Hero.getHeroByHeroID(id)   --获得已招募列表里的英雄
    self.tHero = Hero.getTHeroByKey(self.heroInList._heroID)  --获得配置里的英雄
    
    self._widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero.csb")
    widgetUtil.widgetReader(self._widget)

    self._widget:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    
    --遮罩层
    self._widget.coverLayer:setVisible(false)
    self._widget.coverLayer:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self._widget.coverLayer:setVisible(false)
            self._widget.coverLayer:removeAllChildren()
        end
    end)
    
    self._widget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:back()
        end
    end)
    
    --装备
    self._widget.btn_equip:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curState=Const.HERO_SELECT_STATE.EQUIP
            self:changeBtnState()
        end
    end)
    --技能
    self._widget.btn_skill:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curState=Const.HERO_SELECT_STATE.SKILL
            self:changeBtnState()
        end
    end)
    --羁绊
    self._widget.btn_fate:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self.curState=Const.HERO_SELECT_STATE.FATE
            self:changeBtnState()
        end
    end)
    
    self.curEquipCraftedN=0   --装备组合界面显示上面第几个装备的装备组合
    self.equipPos=1            --4个装备哪个要装备上 
    self.btnState=nil         --装备信息界面按钮状态
    
    self.curState=Const.HERO_SELECT_STATE.EQUIP     --装备，技能，羁绊 状态
    self._widgetEquip = nil     --装备
    self._widgetSkill = nil     --技能
    self._widgetFate = nil      --羁绊
    self.descWin = nil          --技能、羁绊描述窗口
    self.equip_lv_item2 = nil   --武器炼化后属性描述item
    
    self:leftInfo()
    self:changeBtnState()  
end

--左边信息
function HeroWidget:leftInfo()
    local widget=self._widget
    --左边信息
    local bg_hero_img = string.format('img/%d.png',self.tHero.img)
    if cc.FileUtils:getInstance():isFileExist(bg_hero_img) then
        widget.image_hero:loadTexture(bg_hero_img)  --大图
    end
    widget.btn_hero:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            UIManager.pushWidget('heroInfoWidget',self.heroInList._heroID, true)
        end
    end)

    widget.label_name1:setString(self.tHero.name) 
    widget.label_name2:setString(self.tHero.name) 
    --星级
    self:updateHeroStar(widget, self.heroInList._star)
end

--更新按键状态
function HeroWidget:changeBtnState()

    local isEquip=self.curState == Const.HERO_SELECT_STATE.EQUIP
    local isSkill=self.curState == Const.HERO_SELECT_STATE.SKILL
    local isFate=self.curState == Const.HERO_SELECT_STATE.FATE

    self._widget.btn_equip:setEnabled(not isEquip)
    self._widget.btn_equip:setBright(not isEquip)
    self._widget.btn_skill:setEnabled(not isSkill)
    self._widget.btn_skill:setBright(not isSkill)        
    self._widget.btn_fate:setEnabled(not isFate)
    self._widget.btn_fate:setBright(not isFate)
    
    self:changeWidget()
end

--更换界面
function HeroWidget:changeWidget()
    if Const.HERO_SELECT_STATE.EQUIP == self.curState then
        if self._widgetEquip == nil then
            self:creatHeroEquip()
        end

        self._widgetEquip:setVisible(true)          
  
        if nil~=self._widgetSkill then
            self._widgetSkill:setVisible(false)
        end
        if nil~=self._widgetFate then
            self._widgetFate:setVisible(false)
        end
    elseif Const.HERO_SELECT_STATE.SKILL == self.curState then
        if self._widgetSkill == nil then
            self:creatHeroSkill()
        end        

        self._widgetSkill:setVisible(true)
        self:updateSkillWidget()           

        if nil~=self._widgetEquip then
            self._widgetEquip:setVisible(false)
        end
        if nil~=self._widgetFate then
            self._widgetFate:setVisible(false)
        end
    elseif Const.HERO_SELECT_STATE.FATE == self.curState then
        if self._widgetFate == nil then
            self:creatHeroFate()
        end

        self._widgetFate:setVisible(true)          

        if nil~=self._widgetEquip then
            self._widgetEquip:setVisible(false)
        end
        if nil~=self._widgetSkill then
            self._widgetSkill:setVisible(false)
        end
    end
end

-- 英雄装备---------------------------------------------------------------------------------------

--创建英雄装备界面
function HeroWidget:creatHeroEquip()
    if self._widgetEquip == nil then
        self._widgetEquip = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_equip.csb")         
        self._widget.image_equip:addChild(self._widgetEquip)
    end
    widgetUtil.widgetReader(self._widgetEquip)

    
    --魂石按钮，弹出界面，显示魂石获得途径
    self._widgetEquip.btn_soul:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then    
            self:createGetSoulWidget(self.heroInList._heroID)
        end
    end)  
    --进阶按钮
    self._widgetEquip.btn_xlv:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then    
            self:heroUpStarRequest()
        end
    end)  
    --炼化按钮
    self._widgetEquip.btn_equip_lv:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then   
            self:upArmsLvRequest()
        end
    end)  
    
    for i=1, 4 do
    	self._widgetEquip["btn_equip"..i]:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then  
                self.equipPos=i
                self:createEquipDescWidget()  
            end
        end)  
    end 
    self:heroInfo()
end

--英雄界面英雄信息
function HeroWidget:heroInfo()
    local widget = self._widgetEquip
    
    local anim=commonUtil.getAnim(self.heroInList._heroID)
    if anim then
        local size=widget.image_hero:getContentSize()
        anim:setPosition(size.width/2,size.height/2) 
        anim:PlaySection("s5", true)
        widget.image_hero:addChild(anim)
    end
    
    local image_attr = Hero.getAttrIcon(self.heroInList._attr)
    --属性图标
    widget.image_ball:loadTexture(image_attr)     

    --英雄姓名和称呼
    widget.label_title:setString(self.tHero.title)
    widget.label_name:setString(self.tHero.name)    

    --等级和等级进度条 
    local lvText=string.format("%d/%d",self.heroInList._lv,Const.MAX_LEVEL)
    widget.label_lv:setString(lvText) 
    
    local max = t_lv[self.heroInList._lv]["hero_up_exp"]
    local expLable=string.format("%d/%d",self.heroInList._exp,max)
    widget.label_exp:setString(expLable)  
    

    --描述
    widget.label_desc:setString(self.tHero.desc2) 

    self:updateStar()

    --武器名和品质等级
    widget.label_arms_name:setString(self.tHero.equip_name) 
    
    self:updateEquipFold()
end

--更新装备栏信息
function HeroWidget:updateEquipFold()
    local widget = self._widgetEquip
    self.heroInList=Hero.getHeroByHeroID(self.heroInList._heroID)
    
    local armsLv=string.format("+%d", self.heroInList._armsLv)
    widget.label_arms_lv:setString(armsLv) 
    
    if self.heroInList._armsLv == Const.MAX_ARMS_LV then
        widget.btn_equip_lv:setVisible(false)
    end
    
    local curEquip=self.heroInList._curEquip   --当前装备栏上的装备情况
    local needEquip=self.tHero["equip"..self.heroInList._armsLv]
    for i=1, 4 do
        if t_item[needEquip[i]] then
            widgetUtil.createIconToWidget(t_item[needEquip[i]].grade,widget["image_equip"..i.."_bottom"])  -- 底框
            widgetUtil.createIconToWidget(t_item[needEquip[i]].icon,widget["image_equip"..i])  --图标 
            widgetUtil.createIconToWidget(t_item[needEquip[i]].grade+10,widget["image_equip"..i.."_grade"])  -- 品质框
        end
        local equipNum=Item.getNum(needEquip[i])
        
        if curEquip[i]==0 then
            local icon = widget["image_equip"..i]:getChildByTag(0x100)
            if icon then
                widgetUtil.greySprite(icon)
            end
            widgetUtil.createIconToWidget(9,widget["image_equip"..i.."_bottom"])  -- 底框
            widgetUtil.createIconToWidget(19,widget["image_equip"..i.."_grade"])  -- 品质框
            if equipNum==0 then
                widget["image_hint"..i]:setVisible(false)
            else
                widget["image_hint"..i]:setVisible(true)
            end
        else
            widget["image_hint"..i]:setVisible(false)
        end
    end
end

--更新星级进阶后的值
function HeroWidget:updateStar()
    local widget = self._widgetEquip
    self.heroInList=Hero.getHeroByHeroID(self.heroInList._heroID)

    --星级
    self:updateHeroStar(self._widget, self.heroInList._star)
    --战斗力
    local power =Hero.getHeroPower(self.heroInList._heroID)
    widget.label_power:setString(tostring(power)) 

    --魂石数和提升下星级所需魂石数
    local soulId=Hero.getHeroSoulStoneItemID(self.heroInList._heroID)
    local soulStoneNum=Item.getNum(soulId)
    if self.heroInList._star == Const.MAX_STAR then
        widget.label_soul_number:setString(tostring(soulStoneNum))
        widget.progress_soul:setPercent(100)
        widget.btn_xlv:setVisible(false)
    else
        local soulN= string.format("soul%d",self.heroInList._star)
        local max =self.tHero[soulN] 
        local percent = soulStoneNum / max * 100

        if percent>100 then
            widget.progress_soul:setPercent(100)
        else
            widget.progress_soul:setPercent(percent) 
        end

        local next_text=string.format("%d/%d",soulStoneNum,max)
        widget.label_soul_number:setString(tostring(next_text)) 
    end  
end

--进阶请求
function HeroWidget:heroUpStarRequest()
    local request = {}
    request["heroID"] = self.heroInList._heroID

    self:request("main.heroHandler.starup", request, function(msg)
        if msg['code'] == 200 then 
            self:updateStar()
            self:createUpStarWidget() 
        end
    end)
end

--进阶成功弹窗
function HeroWidget:createUpStarWidget()
    local widget=self._widget
    local upStarWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_equip_xlv.csb")
    widget:addChild(upStarWidget)
    widgetUtil.widgetReader(upStarWidget)
    
    upStarWidget:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            upStarWidget:runAction(cc.RemoveSelf:create())
            upStarWidget=nil
        end
    end)
    
    self.heroInList=Hero.getHeroByHeroID(self.heroInList._heroID)
    local abilityLastStar=Hero.getHeroLastStarAbility(self.heroInList._heroID)
    local curAbility=Hero.getHeroAbility(self.heroInList._heroID)
    
    widgetUtil.createIconToWidget(self.tHero.icon,upStarWidget.image_icon1)  --图标 
    widgetUtil.createIconToWidget(self.tHero.type,upStarWidget.image_icon_bottom1)  -- 底框
    widgetUtil.createIconToWidget(self.tHero.type+10,upStarWidget.image_icon_grade1)  -- 品质框
    for i=1, Const.MAX_STAR do
        if i==self.heroInList._star-1 then
            upStarWidget["image_left_star"..i]:setVisible(true)
        else
            upStarWidget["image_left_star"..i]:setVisible(false)
        end
    end
    
    widgetUtil.createIconToWidget(self.tHero.icon,upStarWidget.image_icon2)  --图标 
    widgetUtil.createIconToWidget(self.tHero.type,upStarWidget.image_icon_bottom2)  -- 底框
    widgetUtil.createIconToWidget(self.tHero.type+10,upStarWidget.image_icon_grade2)  -- 品质框
    for j=1, Const.MAX_STAR do
        if j==self.heroInList._star then
            upStarWidget["image_right_star"..j]:setVisible(true)
        else
            upStarWidget["image_right_star"..j]:setVisible(false)
        end
    end
    
    self:updateHeroStar(upStarWidget.bg_star, self.heroInList._star)
    
    upStarWidget.label_power_befor:setString(tostring(0))
    upStarWidget.label_power_cur:setString(tostring(1))
    upStarWidget.label_atk_befor:setString(tostring(abilityLastStar.atk))
    upStarWidget.label_atk_cur:setString(tostring(curAbility.atk))
    upStarWidget.label_hp_befor:setString(tostring(abilityLastStar.hp))
    upStarWidget.label_hp_cur:setString(tostring(curAbility.hp))
end

--炼化请求
function HeroWidget:upArmsLvRequest()
    local request = {}
    request["heroID"] = self.heroInList._heroID

    self:request("main.equipHandler.raise", request, function(msg)
        if msg['code'] == 200 then 
            self:updateEquipFold()
            self:createUpArmsLvWidget() 
        end
    end)
end

--炼化成功弹窗
function HeroWidget:createUpArmsLvWidget()
    local widget=self._widget
    local upArmsLvWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_equip_lv.csb")
    widget:addChild(upArmsLvWidget)
    widgetUtil.widgetReader(upArmsLvWidget)
    
    upArmsLvWidget:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            upArmsLvWidget:runAction(cc.RemoveSelf:create())
            upArmsLvWidget=nil
        end
    end)
    
    self.heroInList=Hero.getHeroByHeroID(self.heroInList._heroID)
    local desc=Hero.getUpEquipDesc(self.heroInList)
    
    widgetUtil.createIconToWidget(self.tHero.icon,upArmsLvWidget.image_icon1)  --图标 
    widgetUtil.createIconToWidget(self.tHero.icon,upArmsLvWidget.image_icon2)  --图标 
    widgetUtil.createIconToWidget(self.tHero.type,upArmsLvWidget.image_icon_bottom1)  -- 底框
    widgetUtil.createIconToWidget(self.tHero.type+10,upArmsLvWidget.image_icon_grade1)  -- 品质框
    widgetUtil.createIconToWidget(self.tHero.type,upArmsLvWidget.image_icon_bottom2)  -- 底框
    widgetUtil.createIconToWidget(self.tHero.type+10,upArmsLvWidget.image_icon_grade2)  -- 品质框
    upArmsLvWidget.list_item:removeAllItems()
    upArmsLvWidget.list_item:setBounceEnabled(true)
    
    if self.heroInList._armsLv==1 or self.heroInList._armsLv==3 or self.heroInList._armsLv==5 then
        local item1=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_equip_lv_item1.csb")
        widgetUtil.widgetReader(item1)
        
        local n=(self.heroInList._armsLv+5)/2
        local skillId=self.tHero["skill"..n]
        local skill=t_skill[skillId]
        
        if skill then
            widgetUtil.createIconToWidget(skill.icon,item1.image_skill)  --图标 
            widgetUtil.createIconToWidget(5,item1.image_skill_bottom)  -- 底框
            widgetUtil.createIconToWidget(15,item1.image_skill_grade)  -- 品质框

            item1.label_skill_name:setString(skill.name)

            local num= self.heroInList._armsLv+2
            local _skillNum=string.format("_skill%d",num)   
            local values=Hero.getSkillDescAllValue(skillId,self.heroInList[_skillNum],false)
            if skill['desc']~="" then
                local rich=Hero.getSkillRich(skill['desc'],values)
                self:addRichText(item1.label_skill_desc,rich)
            end

            upArmsLvWidget.list_item:pushBackCustomItem(item1)
        end
    end
    for i=1, #desc/3 do
        if nil == self.equip_lv_item2 then
            self.equip_lv_item2 = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_equip_lv_item2.csb")
            self.equip_lv_item2:retain()
        end
        local item2= self.equip_lv_item2:clone()
        
        local label_attri_text=ccui.Helper:seekWidgetByName(item2,"label_attri_text")
        label_attri_text:setString(desc[3*i-2])
        local label_attri_befor=ccui.Helper:seekWidgetByName(item2,"label_attri_befor")
        label_attri_befor:setString(tostring( desc[3*i-1]))
        local label_attri_cur=ccui.Helper:seekWidgetByName(item2,"label_attri_cur")
        label_attri_cur:setString(tostring( desc[3*i]))
        
        upArmsLvWidget.list_item:pushBackCustomItem(item2)
    end
end

--创建获取魂石弹窗界面
function HeroWidget:createGetSoulWidget(heroId)
    local widget=self._widget
    local getSoulWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIitem_reward.csb")
    local size=widget.coverLayer:getContentSize()
    getSoulWidget:setAnchorPoint(cc.p(0.5,0.5))
    getSoulWidget:setPosition(size.width/2,size.height/2)
    widget.coverLayer:setVisible(true)
    widget.coverLayer:addChild(getSoulWidget)
    widgetUtil.widgetReader(getSoulWidget)

    getSoulWidget.btn_close:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            getSoulWidget:runAction(cc.RemoveSelf:create())
            getSoulWidget=nil
            widget.coverLayer:setVisible(false)
        end
    end)
    
    local tHero = Hero.getTHeroByKey(heroId)  --获得配置里的英雄
    
    getSoulWidget.label_item_name:setString(tHero.name)   
    --魂石图标    label_chapter_num
    local soulId=Hero.getHeroSoulStoneItemID(heroId)
    if t_item[soulId] then
        widgetUtil.createIconToWidget(t_item[soulId].grade,getSoulWidget.image_item_bottom)   --底框
        widgetUtil.createIconToWidget(t_item[soulId].icon,getSoulWidget.image_item_icon)       
        widgetUtil.createIconToWidget(t_item[soulId].grade+10,getSoulWidget.image_item_grade)   --品质框
    end
    
    local heroInList=Hero.getHeroByHeroID(heroId)   --获得已招募列表里的英雄
    local soulN="soul0"
    local numLab=""
    local soulStoneNum=Item.getNum(soulId)
    if heroInList then
        if self.heroInList._star == Const.MAX_STAR then
            numLab=string.format("(%d)",soulStoneNum)
        else
            soulN= string.format("soul%d",self.heroInList._star)
            local max =tHero[soulN] 
            numLab=string.format("(%d/%d)",soulStoneNum,max)
        end
    else
        local max =tHero[soulN] 
        numLab=string.format("(%d/%d)",soulStoneNum,max)   
    end
    getSoulWidget.label_item_num:setString(numLab)    --魂石数量情况  
    
    for i=1, 3 do   
        local root=tHero["soul_fuben"..i]
        local chapterId=root[1]
        local fuId=root[2]
        
        getSoulWidget["btn_reward"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:openCopyRequest(chapterId,fuId)
            end
        end)
        
        if t_chapter[chapterId] then
            local bg="chapter_icon/"..(t_chapter[chapterId].bg)..".png"
            if cc.FileUtils:getInstance():isFileExist(bg) then
                getSoulWidget["image_chapter_icon"..i]:loadTexture(bg)  
            end
            
            getSoulWidget["label_chapter_num"..i]:setString(tostring(t_chapter[chapterId].name3))   --章节名
        end
        if t_chapter_fuben[chapterId][fuId] then
            getSoulWidget["label_chapter"..i]:setString(tostring(t_chapter_fuben[chapterId][fuId].name))   --副本名
        end
        
        local lastChapterId=Copy.getPreCharterID(chapterId)
        local charpter = Copy.isClearance(lastChapterId)
        if charpter then
            getSoulWidget["label_lock"..i]:setVisible(false)
        end
    end
end


--创建装备信息界面
function HeroWidget:createEquipDescWidget()
    local widget=self._widget
    local equipDescWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIequip_desc.csb")
    local size=widget.coverLayer:getContentSize()
    equipDescWidget:setAnchorPoint(cc.p(0.5,0.5))
    equipDescWidget:setPosition(size.width/2,size.height/2)
    widget.coverLayer:setVisible(true)
    equipDescWidget:setTag(equipDescWidgetTag)
    widget.coverLayer:addChild(equipDescWidget)
    widgetUtil.widgetReader(equipDescWidget)

    self.curEquipCraftedN=0
    
    local equipId = self.tHero["equip"..self.heroInList._armsLv][self.equipPos]
    if t_item[equipId] then
        widgetUtil.createIconToWidget(t_item[equipId].grade,equipDescWidget.image_equip_bottom)  --底框
        widgetUtil.createIconToWidget(t_item[equipId].icon,equipDescWidget.image_equip_icon)  --图标
        widgetUtil.createIconToWidget(t_item[equipId].grade+10,equipDescWidget.image_equip_grade)  --品质
    end
    equipDescWidget.label_equip_name:setString(t_hero_equip[equipId].name)    --装备名称
    equipDescWidget.label_desc2:setString(t_hero_equip[equipId].desc)         --装备描述
    equipDescWidget.label_lv:setString(tostring(t_hero_equip[equipId].lv_limit))         --等级限制

    local curEquip=self.heroInList._curEquip
    local equipNum=Item.getNum(equipId)
    equipDescWidget.label_equip_num:setString(tostring(equipNum))             --装备数量
    
    --装备属性加成
    local ability=Hero.getEquipAdd(equipId)
    local desc=Hero.getEquipDesc(ability)
    for i=1, 4 do
        if desc[i*2-1] then
            equipDescWidget["label_attri"..i.."_text"]:setString(desc[i*2-1])
            equipDescWidget["label_attri"..i]:setString(desc[i*2])
        else
            equipDescWidget["label_attri"..i.."_text"]:setVisible(false)
            equipDescWidget["label_attri"..i]:setVisible(false)
        end
    end
    
    if curEquip[self.equipPos]~=0 then
        self.btnState=Const.HERO_EQUIP_INFO_SURE
    else
        if equipNum~=0 then
            self.btnState=Const.HERO_EQUIP_INFO_PUTON
        else
            if #t_hero_equip[equipId].compose~=0 then
                self.btnState=Const.HERO_EQUIP_INFO_FORMULA
            else
                self.btnState=Const.HERO_EQUIP_INFO_WAY
            end
        end    
    end
    equipDescWidget.bg_btn:loadTexture(self.btnState)
    
    equipDescWidget.btn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then   
            if self.btnState==Const.HERO_EQUIP_INFO_SURE then
                equipDescWidget:runAction( cc.Sequence:create(cc.RemoveSelf:create(),cc.CallFunc:create(function()
                    widget.coverLayer:removeAllChildren()
                    widget.coverLayer:setVisible(false)
                end)))
            elseif self.btnState==Const.HERO_EQUIP_INFO_PUTON then
                --发送装上装备请求
                self:equipRequest()
                
            elseif self.btnState==Const.HERO_EQUIP_INFO_FORMULA then
                sender:setEnabled(false)
                equipDescWidget:runAction( cc.Sequence:create(cc.MoveBy:create(0.3,cc.p(-moveX,0)),cc.CallFunc:create(function()
                    self:createEquipCrafted(equipId)
                    self.btnState=Const.HERO_EQUIP_INFO_SURE
                    equipDescWidget.bg_btn:loadTexture(self.btnState)
                    sender:setEnabled(true)
                end)))
            elseif self.btnState==Const.HERO_EQUIP_INFO_WAY then
                sender:setEnabled(false)
                equipDescWidget:runAction( cc.Sequence:create(cc.MoveBy:create(0.3,cc.p(-moveX,0)),cc.CallFunc:create(function()
                    self:createEquipRewardWidget(equipId)
                    self.btnState=Const.HERO_EQUIP_INFO_SURE
                    equipDescWidget.bg_btn:loadTexture(self.btnState)
                    sender:setEnabled(true)
                end))) 
            end
        end
    end)  
end

--装备请求
function HeroWidget:equipRequest()
    local request = {}
    request["heroID"] = self.heroInList._heroID
    request["pos"] =  self.equipPos

    self:request("main.equipHandler.equip", request, function(msg)
        if msg['code'] == 200 then 
           self:updateEquipFold()
           
            local equipDescWidget=self._widget.coverLayer:getChildByTag(equipDescWidgetTag)
            equipDescWidget:runAction( cc.Sequence:create(cc.RemoveSelf:create(),cc.CallFunc:create(function()
                self._widget.coverLayer:removeAllChildren()
                self._widget.coverLayer:setVisible(false)
                self:playEffect()
            end)))
        end
    end)
end

--装备上的效果
function HeroWidget:playEffect()
    local actionNum=self._widgetEquip.image_hero:getNumberOfRunningActions()
    if actionNum>0 then
        self._widgetEquip.image_hero:stopAllActions()
    end
    local equipId = self.tHero["equip"..self.heroInList._armsLv][self.equipPos]
    --装备属性加成
    local ability=Hero.getEquipAdd(equipId)
    local desc=Hero.getEquipDesc(ability)
    
    local posX,posY=self._widgetEquip.image_hero:getPosition()
    local time=0
    
    schedule(self._widgetEquip.image_hero,function ()
        time = time+1
        if desc[time*2-1] then
            local str=string.format("%s  %s",desc[ time*2-1],desc[ time*2])
            local label = cc.LabelTTF:create(str, "fonts/FZZhengHeiS-DB-GB.ttf", 25)
            label:setColor(cc.c3b(0,255,0))
            label:setPosition(cc.p(posX,posY+20))
            self._widgetEquip:addChild(label,10)
            label:runAction( cc.Sequence:create(cc.MoveBy:create(0.8,cc.p(0,60)),cc.RemoveSelf:create()))
        else
            self._widgetEquip.image_hero:stopAllActions()
        end
    end,0.6)      
end

--创建装备合成弹窗界面
function HeroWidget:createEquipCrafted(equipId)
    local widget=self._widget
    local equipCraftedWidget = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIequip_crafted.csb")

    local size=widget.coverLayer:getContentSize()
    equipCraftedWidget:setAnchorPoint(cc.p(0.5,0.5))
    equipCraftedWidget:setPosition(size.width/2+moveX,size.height/2)
    equipCraftedWidget:setTag(equipCraftedWidgetTag)
    widget.coverLayer:addChild(equipCraftedWidget)
    widgetUtil.widgetReader(equipCraftedWidget)
    
    equipCraftedWidget.image_equipUp1_bottom:setVisible(false)
    equipCraftedWidget.image_equipUp2_bottom:setVisible(false)
    equipCraftedWidget.image_equipUp3_bottom:setVisible(false)
    
    self.curEquipCraftedN=0 
    self:addEquip(equipId)
    
    for i=1, 3 do
        equipCraftedWidget["btn_equip"..i]:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then  
                self.curEquipCraftedN=i
                local eId=sender:getTag()
                self:updateCrafted(eId)
                for j=i+1, 3 do
                    equipCraftedWidget["image_equipUp"..j.."_bottom"]:setVisible(false)
                end               
            end
        end) 
    end
    
    for i=1, 3 do
        equipCraftedWidget["btn_crafted"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then  
                local tag=sender:getTag()
                local compose=t_hero_equip[tag].compose
                if #compose~=0 then
                    self:addEquip(tag)
                else
                    self:createEquipRewardWidget(tag)
                end
            end
        end) 
    end
    equipCraftedWidget.btn_crafted:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then  
           self:craftedRequest()
        end
    end) 
end

--装备合成请求
function HeroWidget:craftedRequest()
    local widget= self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)
    local request = {}
    local eid=widget["btn_equip"..self.curEquipCraftedN]:getTag()
    request["eid"] = eid

    self:request("main.equipHandler.compose", request, function(msg)
        if msg['code'] == 200 then 
            local widget=self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)
            if self.curEquipCraftedN>1 then
                self.curEquipCraftedN=self.curEquipCraftedN-1
                local eId=widget["btn_equip"..self.curEquipCraftedN]:getTag()
                self:updateCrafted(eId)
                for j=self.curEquipCraftedN+1, 3 do
                    widget["image_equipUp"..j.."_bottom"]:setVisible(false)
                end
            elseif self.curEquipCraftedN==1 then
                local eId=widget.btn_equip1:getTag()
                self:updateCrafted(eId)
                widget.image_equipUp2_bottom:setVisible(false)
                widget.image_equipUp3_bottom:setVisible(false)
                local equipDescWidget=self._widget.coverLayer:getChildByTag(equipDescWidgetTag)
                local equipNum=Item.getNum(eId)
                equipDescWidget.label_equip_num:setString(tostring(equipNum))             --装备数量
                self.btnState=Const.HERO_EQUIP_INFO_PUTON
                equipDescWidget.bg_btn:loadTexture(self.btnState)
                self:updateEquipFold()
            end 
        end
    end)
end

--组合界面上面添加装备
function HeroWidget:addEquip(equipId)
    local widget=self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)
    self.curEquipCraftedN=self.curEquipCraftedN+1
    local n=self.curEquipCraftedN
    
    if widget["image_equipUp"..n.."_bottom"] then
        widget["image_equipUp"..n.."_bottom"]:setVisible(true)

        widgetUtil.createIconToWidget(t_item[equipId].grade,widget["image_equipUp"..n.."_bottom"])  --底框
        widgetUtil.createIconToWidget(t_item[equipId].icon,widget["image_equipUp"..n.."_icon"])  --图标
        widgetUtil.createIconToWidget(t_item[equipId].grade+10,widget["image_equipUp"..n.."_grade"])  --品质
        widget["btn_equip"..n]:setTag(equipId)       

        self:updateCrafted(equipId)
    end
end
--刷新合成
function HeroWidget:updateCrafted(equipId)
    local widget=self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)

    widgetUtil.createIconToWidget(t_item[equipId].grade, widget.image_equip_crafted_bottom)  --底框
    widgetUtil.createIconToWidget(t_item[equipId].icon,widget.image_equip_crafted_icon)  --图标
    widgetUtil.createIconToWidget(t_item[equipId].grade+10, widget.image_equip_crafted_grade)  --品质
    widget.label_equip_name:setString(t_item[equipId].name)
      
    for j=1, 3 do
        if j==self.curEquipCraftedN then
            widget["image_click"..j]:setVisible(true)
        else
            widget["image_click"..j]:setVisible(false)
        end
    end 
    
    local compose=t_hero_equip[equipId].compose
    local n=#compose/2
    if n==1 then
        widget.panel_equip_crafted1:setVisible(true)
        widget.panel_equip_crafted2:setVisible(false)
    elseif n==2 then
        widget.panel_equip_crafted1:setVisible(false)
        widget.panel_equip_crafted2:setVisible(true)
    else
        widget.panel_equip_crafted1:setVisible(true)
        widget.panel_equip_crafted2:setVisible(true)
    end
 
    for i=1, n do
        local eId=compose[2*i-1]
        local m=i
        if n==2 then
        	m=i+1
        end
        widgetUtil.createIconToWidget(t_item[eId].grade,widget["image_equip"..m.."_bottom"])  --品质
        widgetUtil.createIconToWidget(t_item[eId].icon, widget["image_equip"..m.."_icon"])  --图标
        widgetUtil.createIconToWidget(t_item[eId].grade+10,widget["image_equip"..m.."_grade"])  --品质
        widget["btn_crafted"..m]:setTag(eId)
        local needN=compose[2*i]
        local nowN=Item.getNum(eId)
        local lable=string.format("%d/%d",nowN,needN)                --数量
        widget["label_equip"..m.."_num"]:setString(lable)
    end 
end

--创建获取装备路径弹窗界面
function HeroWidget:createEquipRewardWidget(equipId)
    local equipRewardWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIequip_reward.csb")
    equipRewardWidget:setAnchorPoint(cc.p(0.5,0.5))
    local size=self._widget.coverLayer:getContentSize()
    equipRewardWidget:setPosition(size.width/2+moveX,size.height/2)
    self._widget.coverLayer:addChild(equipRewardWidget)
    widgetUtil.widgetReader(equipRewardWidget)
    
    equipRewardWidget.btn_back:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local widget=self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)
            if widget then
                equipRewardWidget:runAction(cc.RemoveSelf:create())
                equipRewardWidget=nil
            else
                equipRewardWidget:runAction( cc.Sequence:create(cc.RemoveSelf:create(),cc.CallFunc:create(function()
                    self._widget.coverLayer:removeAllChildren()
                    self._widget.coverLayer:setVisible(false)
                end)))
            end
        end
    end)
    
    local n=self.curEquipCraftedN
    for i=1,n  do
        local widget=self._widget.coverLayer:getChildByTag(equipCraftedWidgetTag)
        local eId= widget["btn_equip"..i]:getTag()
        widgetUtil.createIconToWidget(t_item[eId].grade,equipRewardWidget["image_equip"..i.."_bottom"])  --底框
        widgetUtil.createIconToWidget(t_item[eId].icon,equipRewardWidget["image_equip"..i.."_icon"])  --图标
        widgetUtil.createIconToWidget(t_item[eId].grade+10,equipRewardWidget["image_equip"..i.."_grade"])  --品质
        equipRewardWidget["image_click"..i]:setVisible(false)
        
        equipRewardWidget["btn_equip"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then  
                self.curEquipCraftedN=i
                self:updateCrafted(eId)
                for j=i+1, 3 do
                    widget["image_equipUp"..j.."_bottom"]:setVisible(false)
                end
                
                equipRewardWidget:runAction(cc.RemoveSelf:create())
                equipRewardWidget=nil
            end
        end) 
    end
    widgetUtil.createIconToWidget(t_item[equipId].grade,equipRewardWidget["image_equip"..(n+1).."_bottom"])  --底框
    widgetUtil.createIconToWidget(t_item[equipId].icon,equipRewardWidget["image_equip"..(n+1).."_icon"])  --图标
    widgetUtil.createIconToWidget(t_item[equipId].grade+10,equipRewardWidget["image_equip"..(n+1).."_grade"])  --品质
    equipRewardWidget["image_click"..n+1]:setVisible(true)
    
    for j=n+2, 4 do
        equipRewardWidget["image_equip"..j.."_bottom"]:setVisible(false)
        equipRewardWidget["image_click"..j]:setVisible(false)
    end
    
    equipRewardWidget.label_equip_name:setString(t_item[equipId].name)    --装备名称
    for i=1, 3 do   
        local root=t_hero_equip[equipId]["reward_fuben"..i]
        local chapterId=root[1]
        local fuId=root[2]
        
        equipRewardWidget["btn_reward"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:openCopyRequest(chapterId,fuId)
            end
        end)
        
        if t_chapter[chapterId] then
            local bg="chapter_icon/"..(t_chapter[chapterId].bg)..".png"
            if cc.FileUtils:getInstance():isFileExist(bg) then
                equipRewardWidget["image_chapter_icon"..i]:loadTexture(bg) 
            end
            
            equipRewardWidget["label_chapter_num"..i]:setString(t_chapter[chapterId].name3)
        end
        if t_chapter_fuben[chapterId][fuId] then
            equipRewardWidget["label_chapter"..i]:setString(t_chapter_fuben[chapterId][fuId].name)
        end

        local lastChapterId=Copy.getPreCharterID(chapterId)
        local charpter = Copy.isClearance(lastChapterId)
        if charpter then
            equipRewardWidget["label_lock"..i]:setVisible(false)
        end
    end
end

--转到副本
function HeroWidget:openCopyRequest(charpterId,fuId) 
    self:request("copy.copyHandler.chapterEntry", {chapter = charpterId}, function(msg)
        if msg['code'] == 200 then
            UIManager.pushWidget('copyWidget', {chapterID = charpterId, copyID = fuId}, true)  
        end
    end)
end



--英雄技能----------------------------------------------------------------------------------------

--创建英雄技能界面
function HeroWidget:creatHeroSkill()
    if self._widgetSkill == nil then
        self._widgetSkill = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_skill.csb")         
        self._widget.image_skill:addChild(self._widgetSkill)
    end
    widgetUtil.widgetReader(self._widgetSkill)
    
    for i=1, 4 do
        local skillId=self.tHero["skill"..i+1]
        local skill=t_skill[skillId]
         
        --技能品质和图标
        widgetUtil.createIconToWidget(skill.icon,self._widgetSkill["image_skill"..i])
        widgetUtil.createIconToWidget(5,self._widgetSkill["image_skill"..i.."_bottom"])  -- 底框
        widgetUtil.createIconToWidget(15,self._widgetSkill["image_skill"..i.."_grade"])  -- 品质框 
        
        --技能名和等级
        self._widgetSkill["label_skill"..i.."_name"]:setString(skill.name)
        
       
        self._widgetSkill["btn_desc"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.began then  
                if self.descWin then
                    self.descWin:removeFromParent(true)   
                    self.descWin=nil
                end 
                local b= self._widgetSkill["image_skill"..i.."_bottom"]
                local posX,posY= b:getPosition()           --获取底框位置
                local pos=self._widgetSkill["bg_skill"..i]:convertToWorldSpace(cc.p(posX,posY)) 
                pos = self._widget.bg:convertToNodeSpace(pos)
                local param={}
                param.pos=pos
                param.skillId=skillId
                param.num=2*i-1
                
                self:creatDescWindow(param)
            elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then 
               self.descWin:removeFromParent(true)   
               self.descWin=nil
            end
        end)
           
        self._widgetSkill["btn_skill"..i.."_up"]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then   
                local skillN= 2*i-1
                self:upSkillRequest(skillN)
            end
        end)
    end  
    
    self:updateSkillWidget()
end

--更新技能升级后的值
function HeroWidget:updateSkillWidget()
    local widget=self._widgetSkill
    self.heroInList=Hero.getHeroByHeroID(self.heroInList._heroID)
    
    --现有金币
    widget.label_gold_num:setString(tostring(Character.gold))
    
    for i=1, 4 do
        local lv=self.heroInList["_skill"..(2*i-1)]
        widget["label_skill"..i.."_lv"]:setString(tostring(lv))  --技能等级
        
        if lv == MAX_LEVEL then
            widget["label_skill"..i.."_gold_num"]:setVisible(false)
            widget["bg_gold"..i]:setVisible(false)
            widget["btn_skill"..i.."_up"]:setVisible(false)
        else               
            local cost=t_lv[lv+1]["hero_skill_gold_cost"]
            widget["label_skill"..i.."_gold_num"]:setString(tostring(cost))  --消耗金币
        end
        
        local armsLv=self.heroInList._armsLv
        local n=2*i-3
        if armsLv>=n then            
            widget["label_lock"..i]:setVisible(false)
            widget["panel_lock"..i]:setVisible(true)   
        else
            widget["panel_lock"..i]:setVisible(false)
            widget["label_lock"..i]:setVisible(true)
            local lable=string.format("装备品质+%d时升级",n)
            widget["label_lock"..i]:setString(lable)
        end
    end
end

--技能升级请求
function HeroWidget:upSkillRequest(skillN)
    local request = {}
    request["heroID"] = self.heroInList._heroID
    request["skill"] = skillN
    self:request("main.heroHandler.skillup", request, function(msg)
        if msg['code'] == 200 then
            self:updateSkillWidget()
        end
    end)
end

--英雄羁绊------------------------------------------------------------------------------------------

--创建英雄羁绊界面
function HeroWidget:creatHeroFate()
    if self._widgetFate == nil then
        self._widgetFate = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_fate.csb")         
        self._widget.image_fate:addChild(self._widgetFate)
    end
    widgetUtil.widgetReader(self._widgetFate)
    
    --羁绊
    for i=1, 4 do
        local fateTHero=Hero.getTHeroByKey(self.tHero["love"..i])    --获得配置里的羁绊英雄1
        widgetUtil.createIconToWidget(5,self._widgetFate["image_hero"..i.."_bottom"])  --底框
        widgetUtil.createIconToWidget(fateTHero.icon,self._widgetFate["image_hero"..i])  --图标
        widgetUtil.createIconToWidget(15,self._widgetFate["image_hero"..i.."_grade"])  --品质框
        self._widgetFate["label_talent"..i.."_name"]:setString(t_talent[self.tHero["talent"..i]]["name"])     --羁绊技能名字

        local fateHero=Hero.getHeroByHeroID(self.tHero["love"..i])  --获得已招募列表里的羁绊英雄1
        if nil==fateHero then
            self:updateHeroStar(self._widgetFate["bg_talent"..i],0)
            
            local icon = self._widgetFate["image_hero"..i]:getChildByTag(0x100)
            if icon then
                widgetUtil.greySprite(icon)
            end
            widgetUtil.createIconToWidget(9,self._widgetFate["image_hero"..i.."_bottom"])  -- 底框
            widgetUtil.createIconToWidget(19,self._widgetFate["image_hero"..i.."_grade"])  -- 品质框
        else
            self:updateHeroStar(self._widgetFate["bg_talent"..i],fateHero._star)
        end

        self._widgetFate["btn_desc"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.began then  
                if self.descWin then
                    self.descWin:removeFromParent(true)   
                    self.descWin=nil
                end
                local b= self._widgetFate["image_hero"..i.."_bottom"]
                local posX,posY= b:getPosition()
                local pos=self._widgetFate["bg_talent"..i]:convertToWorldSpace(cc.p(posX,posY)) 
                pos = self._widget.bg:convertToNodeSpace(pos)
                local param={}
                param.pos=pos
                param.num=i
                self:creatDescWindow(param)
            elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then 
                self.descWin:removeFromParent(true)   
                self.descWin=nil
            end
        end)

        self._widgetFate["btn_talent"..i]:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                self:createGetSoulWidget(self.tHero["love"..i])             
            end
        end)
    end
end

--创建描述窗口
function HeroWidget:creatDescWindow(param)
    if self.descWin== nil then
        self.descWin = ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIhero_skill_fate_item.csb")         
    end
    self.descWin:setAnchorPoint(cc.p(1,0.5))
    local pos=param.pos
    self.descWin:setPosition(cc.p(pos.x-30,pos.y))
    self._widget.bg:addChild(self.descWin,100)
    widgetUtil.widgetReader(self.descWin)
    
    local num= param.num
    
    if param.skillId then             --技能描述
	    local skillId= param.skillId
        local _skillNum=string.format("_skill%d",num)   
        local values1=Hero.getSkillDescAllValue(skillId,self.heroInList[_skillNum],false)  --false 为是否是描述字段2
        if t_skill[skillId]['desc']~="" then
            local rich1=Hero.getSkillRich(t_skill[skillId]['desc'],values1)
            self:addRichText(self.descWin.label_desc1,rich1)
        end
        
        local values2=Hero.getSkillDescAllValue(skillId,self.heroInList[_skillNum],true)
        if t_skill[skillId]['desc_next']~="" then
            local rich2=Hero.getSkillRich(t_skill[skillId]['desc_next'],values2)
            self:addRichText(self.descWin.label_desc2,rich2)
        end  
    else                              --羁绊描述
        local richText1=Hero.getTalentRich(t_talent[self.tHero["talent"..num]]['desc'],t_talent[self.tHero["talent"..num]],1)
        self:addRichText(self.descWin.label_desc1,richText1)
        
        local fateHero=Hero.getHeroByHeroID(self.tHero["love"..num])  --获得已招募列表里的羁绊英雄1
        if fateHero then
            if fateHero._star<=4 then
                local var_num=string.format("var%d",fateHero._star)
                local rate=t_talent[self.tHero["talent"..num]][var_num]/Const.DENOMINATOR
                local richText2=Hero.getTalentRich(t_talent[self.tHero["talent"..num]]['desc2'],t_talent[self.tHero["talent"..num]],rate)
                self:addRichText(self.descWin.label_desc2,richText2)
            else
                self.descWin.label_desc2:setVisible(false)
            end
        else
            self.descWin.label_desc2:setVisible(false)
        end
    end                                            
end

function HeroWidget:addRichText(widget,richText)
    local size=widget:getContentSize()
    richText:setAnchorPoint(cc.p(0.5,0.5))
    richText:ignoreContentAdaptWithSize(false)
    richText:setContentSize(size)
    richText:setPosition(size.width/2,size.height/2) 
    widget:addChild(richText)
end

--更新星级显示
function HeroWidget:updateHeroStar(widget, _star)
    --星级
    local image_star1 = ccui.Helper:seekWidgetByName(widget,"image_star1")
    if _star >= 1 then
        image_star1:setVisible(true)
    else
        image_star1:setVisible(false)
    end
    local image_star2 = ccui.Helper:seekWidgetByName(widget,"image_star2")
    if _star >= 2 then
        image_star2:setVisible(true)
    else
        image_star2:setVisible(false)
    end
    local image_star3 = ccui.Helper:seekWidgetByName(widget,"image_star3")
    if _star >= 3 then
        image_star3:setVisible(true)
    else
        image_star3:setVisible(false)
    end
    local image_star4 = ccui.Helper:seekWidgetByName(widget,"image_star4")
    if _star >= 4 then
        image_star4:setVisible(true)
    else
        image_star4:setVisible(false)
    end
    local image_star5 = ccui.Helper:seekWidgetByName(widget,"image_star5")
    if _star >= Const.MAX_STAR then
        image_star5:setVisible(true)
    else
        image_star5:setVisible(false)
    end
end

function HeroWidget:onEnter()    
    local eventDispatcher = self._widget:getEventDispatcher()
end

function HeroWidget:onExit()
    if self.equip_lv_item2 then
        self.equip_lv_item2:release()
    end
end

--退出当前界面
function HeroWidget:back()

    UIManager.popWidget()
end

return HeroWidget

