
module("widgetUtil",package.seeall)


--把widget上的所有控件赋值给widget
function widgetReader(widget)

    local function readWid(wid)
        local childrens=wid:getChildren()
    
        for _,obj in pairs(childrens) do
    
            local name=obj:getName()
            if name then
                widget[name]=obj
                readWid(obj)
            end
        end
    end
    
    readWid(widget)
	
end

--弹窗适应分辨率
--adpIpad是否适应ipad
function widgetAdpter(widget,adpIpad)
    local winSize = cc.Director:getInstance():getWinSize()
    local scale=1.0
    if adpIpad and winSize.width/winSize.height <1.4 then
        scale=0.86
        widget:setScale(scale)
    end
    local size=widget:getContentSize()
    
    widget:setPositionX(winSize.width-size.width*scale)
    
end

--获取英雄属性的珠子
function createElementBall(type)
    return cc.Sprite:create(string.format("common/common_ball_img%d.png",type))
end

---------------------------
--@return #Sprite ICON精灵
function createIcon(path)
    --local path=string.format("icon/%d.png",iconID)
    local result= cc.Sprite:create(path)
    if result == nil then
        result=cc.Sprite:create("icon/99999.png")
    end
    return result
end
-------------------------
--@function 添加一个Icon到node
function createIconToWidget(iconID, widget)
    local icon = widget:getChildByTag(0x100)
    if icon then
        widget:removeChildByTag(0x100,true)
    end
    
    local path=string.format("icon/%d.png",iconID)
    local sprIcon=createIcon(path)
    widget:addChild(sprIcon,1,0x100)
    local size=widget:getContentSize()
    sprIcon:setPosition(size.width/2,size.height/2)
end
-------------------------
--@function 添加一个CG立绘到node
function createCGToWidget(CGID,widget,scale)
    widget:removeChildByTag(0x100,true)
    local sprCG=cc.Sprite:create(string.format("img/%d.png",CGID))
    if sprCG==nil then return end
    
    if scale then
        sprCG:setScale(scale)
    end
    
    local size=widget:getContentSize()
    sprCG:setPosition(size.width/2,size.height/2)
    widget:addChild(sprCG,1,0x100)

end

--更换ImageView的贴图
function changeTexture(img,path,resType)
    
    img:loadTexture(path,resType or ccui.TextureResType.localType)
    
end

--显示TIP提示
function showTip(content)
	
	local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UITip.csb")
	
	local label=widget:getChildByName("lbl_content")
	
	label:setString(content)
	
	local size=widget:getContentSize()
	
    size.width=label:getContentSize().width+20
	
    widget:setContentSize(size.width,size.height)
	
	local winSize=cc.Director:getInstance():getWinSize()
    
    widget:setPosition(winSize.width/2-size.width/2,winSize.height/2-size.height/2)
	
	widget:runAction(cc.Sequence:create(
	   cc.DelayTime:create(1),
	   cc.MoveBy:create(0.5,cc.p(0,50)),
	   cc.RemoveSelf:create()))
	
	cc.Director:getInstance():getRunningScene():addChild(widget,0xFFFFF)
	
end

--显示消息确认框
--@param content 消息内容
--@param cbYes 点击yes回调
--@param cbNo  点击no回调
function showConfirmBox(content,cbYes,cbNo)
    
    local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UImessage_box2.csb")
    widgetReader(widget)
    
    widget.label_message:setString(content)
    
    local winSize=cc.Director:getInstance():getWinSize()
    widget:setPosition(winSize.width/2-568,0)
    
    widget.btn_yes:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            
            if cbYes then
                cbYes()
            end
            widget:runAction(cc.RemoveSelf:create())
            
        end
    end)
    
    
    
    widget.btn_no:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
        
            if cbNo then
                cbNo()
            end
            widget:runAction(cc.RemoveSelf:create())

        end
    end)
    
    cc.Director:getInstance():getRunningScene():addChild(widget,0xFFFFF)
    
    widget.bg_message:setScale(0.5)
    widget.bg_message:runAction(cc.EaseBounceOut:create(cc.ScaleTo:create(0.4,1)))
    
--    local action=ccs.ActionManagerEx:getInstance():getActionByName("UImessage_box2.csb","show")
--    if action then
--        action:play()
--        performWithDelay(widget,function() 
--            --ccs.ActionManagerEx:getInstance():releaseActionByName("UImessage_box2.csb")
--        end,action:getTotalTime())
--    end
    
    
end

--显示网络等待
function showWaitingNet()

    if waitingNetWidget then
        return
    end
	
    waitingNetWidget=ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIWaitingNet.csb")
    
    local anim=sa.SuperAnimNode:create("effect/animation/8001/8001.sam", 0, nil)
    
    anim:PlaySection("s1", true)
    waitingNetWidget:getChildByName("Panel_3"):addChild(anim)
    
    cc.Director:getInstance():getRunningScene():addChild(waitingNetWidget,0xFFFF)
    
end

--移除网络等待界面
function removeWaitingNet()

    if waitingNetWidget then
        waitingNetWidget:removeFromParent()
    end

    waitingNetWidget=nil

end
------------------------
--@function 精灵变灰
function greySprite(sp)
    local pg = cc.GLProgram:createWithFilenames("res/shader/gray.vsh", "res/shader/gray.fsh")
    pg:bindAttribLocation("a_position", 0)
    pg:bindAttribLocation("a_color", 1)
    pg:bindAttribLocation("a_texCoord", 2)
    pg:link()
    pg:updateUniforms()
    sp:setGLProgram(pg)
    
end
------------------------
--@function 变灰的精灵变回原色
function restoreGreySprite(sp)
    local pg = cc.GLProgram:createWithFilenames("res/shader/normal.vsh", "res/shader/normal.fsh")
    pg:bindAttribLocation("a_position", 0)
    pg:bindAttribLocation("a_color", 1)
    pg:bindAttribLocation("a_texCoord", 2)
    pg:link()
    pg:updateUniforms()
    sp:setGLProgram(pg)
end
------------------------
--@function 精灵变暗
function darkSprite(sp)
    sp:setColor(cc.c3b(100, 100, 100))
end
------------------------
--@function 恢复变暗的精灵
function recoverDarkSprite(sp)
    sp:setColor(cc.c3b(255, 255, 255))
end
------------------------
--@function 设置普通物品/英雄物品信息
--param:node(物品的位置)
--param:quality(无品质传0)
--param:icon(图标ID)
--param:num(数量)
--param:type(物品类型)
--param:starLv(品质0~14)
--param:item_tpl(物品信息面板)
function setItemInfo(node, quality, icon, num, type, starLv, item_tpl)
    local item = node:getChildByTag(0x100)
    if nil == item then
        if item_tpl then
            item = item_tpl:clone()
        else
            item = ccs.GUIReader:getInstance():widgetFromBinaryFile("res/ui/UIitem_icon.csb")
        end        
        widgetReader(item)
        local size = node:getContentSize()
        item:setPosition(size.width, size.height)
        node:addChild(item,1,0x100)
    end
    
    for i=1, 5 do
        item["image_star"..i]:setVisible(false)
    end
    
    if type == Const.ITEM_TYPE.HERO then --英雄物品
        local star = item["image_star"..starLv]
        if nil ~= star then
            star:setVisible(true)
        end
        
        getHeroWeaponQuality(quality, item["image_item_bottom"], item["image_item_grade"])
    else
        getItemQuality(quality, item["image_item_bottom"], item["image_item_grade"])
    end

    createIconToWidget(icon, item["image_item"])
    if num > 1 then
        item["bg_item_num"]:setVisible(true)
        item["label_item_num"]:setString(tostring(num))
    else
        item["bg_item_num"]:setVisible(false)
    end
end
------------------------
--@function 英雄武器品质图片
--param:quality(品质0~14)
--param:qBack(品质背景)
--param:qFront(品质前景)
function getHeroWeaponQuality(quality, qBack, qFront)
    if not quality or quality < 0 or quality > 14 then
    	return
    end
    
    local icon = {
        {0, 10},    --品质0
        {1, 11},    --品质1
        {1, 51},    --品质2
        {2, 12},    --品质3
        {2, 52},    --品质4
        {2, 62},    --品质5
        {3, 13},    --品质6
        {3, 53},    --品质7
        {3, 63},    --品质8
        {3, 73},    --品质9
        {4, 14},    --品质10
        {4, 54},    --品质11
        {4, 64},    --品质12
        {4, 74},    --品质13
        {5, 15}     --品质14
    }
    
    local back = icon[quality+1][1]
    local front = icon[quality+1][2]
    createIconToWidget(back, qBack)
    createIconToWidget(front, qFront)
end
------------------------
--@function 物品品质图片
--param:quality(品质0~5), -1获得没有物品时的品质图片
--param:qBack(品质背景)
--param:qFront(品质前景)
function getItemQuality(quality, qBack, qFront)
    if quality > 5 then
        return
    end
    
    local back = 0
    local front = 0
    
    if -1 == quality then
        back = 9
        front = 19
    else
        local icon = {
            {0, 10},    --品质0
            {1, 11},    --品质1
            {2, 12},    --品质2
            {3, 13},    --品质3
            {4, 14},    --品质4
            {5, 15}     --品质5
        }
        
        back = icon[quality+1][1]
        front = icon[quality+1][2]
    end

    createIconToWidget(back, qBack)
    createIconToWidget(front, qFront)
end
------------------------
--@function 读取csb文件
--param:file(csb文件，不包含扩展名)
--return:widget(文件对象)
function registCsbPanel(file)
    local filePath = "res/ui/"..file..".csb"
    local widget = ccs.GUIReader:getInstance():widgetFromBinaryFile(filePath)
    widgetReader(widget)
    
    GameGuide.dispatchEvent(Const.GAME_GUIDE_TYPE.REGIST, widget, file)  --新手指引用

    return widget
end
