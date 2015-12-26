--[[
*战斗场景
*
]]

require "Cocos2d"
require "Cocos2dConstants"
require "json"
require("battle/buff/BattleBuffMgr")

local skill_config=require("config/t_skill")            --技能表
local fuben_config=require("config/t_chapter_fuben")    --副本表
local team_config=require("config/t_team")              --副本怪物组表
local monster_config=require("config/t_team_monster")   --怪物表
local t_hero=require("src/config/t_hero")               --英雄表
local lvgrow_config=require("config/t_lv")              --等级成长表
local stargrow_config=require("config/t_xlv")           --星级成长表
local t_parameter=require("config/t_parameter")         --公共配置表

local BaseScene = require("scene/BaseScene")
local BattleHero=require("battle/BattleHero")
local BattleSettlement=require("battle/BattleSettlement")

--***********************************************

local _battleBalls={}       --战斗珠子
local _battlelog={}         --战报记录
local _nRound=0         --战斗轮数
local _ourHero=nil
local _enemyHero=nil
local _layer=nil      --战斗场景层
local _uiLayer=nil
local _formatType       --阵型类型
local _battleType       --战斗类型
local _chapterId=0      --当前章节ID
local _copyId=0         --当前副本ID
local _battleMode=1     --战斗模式，{精英,副本}
local _battleStartTime=0
local _isWin=false          --是否战斗胜利
local _isReplay=false
local _isStart=false

local BattleScene = class("BattleScene",function()
    return BaseScene:new()
end)

--[[
local opt = {}
opt["type"] 副本/活动/竞技
opt["chapter"] 章节
opt["mode"] 精英/普通
opt["id"] 副本编号
--]]
function BattleScene:create(save, opt)
    
    _formatType = opt["format_type"]
    _battleType= opt["battle_type"]
    self._opt=opt
    local scene = BattleScene.new(save)
    scene:addChild(scene:createLayer())
    
    if opt["isReplay"] then
        _battlelog=json.decode(opt.battlelog)
        scene:initReplay()
    else
    
        if opt["isPvp"] then
            scene:initPVP()
        else
            scene:initPVE(opt["chapter"], opt["mode"], opt["id"])
        end
    end
    
    return scene
end

function BattleScene:ctor()
    self._buffs={}          --buff列表
    _ourHero=nil
    _enemyHero=nil
end
-----------------------
--@function 根据星级计算攻击力和HP
function BattleScene:calcValue(level,starLevel,hp,atk)

    local level=level-1
    local starLevel=starLevel-1
    local finalHp=hp
    local finalAtk=atk

    if level>0 then
        local hp_ratio_lv=lvgrow_config[level].hero_up_hp/Const.DENOMINATOR               --HP等级对应成长系数
        local atk_ratio_lv=lvgrow_config[level].hero_up_atk/Const.DENOMINATOR             --ATK等级对应成长系数
        finalHp=hp+hp*hp_ratio_lv
        finalAtk=atk+atk*atk_ratio_lv
    end

    if starLevel>0 then
        local hp_ratio_starlv=stargrow_config[starLevel].hero_skill_hp/Const.DENOMINATOR     --HP星级对应成长系数
        local atk_ratio_starlv=stargrow_config[starLevel].hero_skill_atk/Const.DENOMINATOR   --ATK星级对应成长系数
        finalHp=hp+hp*hp_ratio_starlv
        finalAtk=atk+atk*atk_ratio_starlv
    end

    return math.ceil(finalHp),math.ceil(finalAtk)
end

--初始化PVE场景
--@param chapterId 章节ID
--@param copyId 副本ID
--@param mode 模式，1：普通，2：精英
function BattleScene:initPVE(chapterId,mode,copyId)
    _isReplay=false
    _battlelog={}
    _battlelog.ourAngerSkills={}
    _battlelog.enemyAngerSkills={}
    local config=fuben_config[chapterId][copyId]
    self:createBg(config.battle_bg)
    self:playGroundMusic(config.sound)
    _chapterId=chapterId
    _copyId=copyId
    _battleMode=mode
    --初始化玩家英雄
    self:createOur()
    --初始化敌方
    local team_config=team_config[config.battle_team]
    self:createMonsters(team_config)
    local runDuration=0.1
    performWithDelay(self,function()
        self:startBattle()
    end,runDuration)
    
end

--初始化PVP场景
function BattleScene:initPVP()
    self:createBg(1001)
    self:playGroundMusic(1602)
    _isReplay=false
    self._isPvp=true
    _battlelog={}
    _battlelog.ourAngerSkills={}
    _battlelog.enemyAngerSkills={}
    --初始化玩家英雄
    self:createOur()
    --初始化敌方
    self:createPvpEnemy()
    local runDuration=0.1
    performWithDelay(self,function()
        self:startBattle()
    end,runDuration)
end
--初始化重播
function BattleScene:initReplay()
    self:createBg(1001)
    self:playGroundMusic(1602)
    _isReplay=true
    _ourHero=nil
    local head
    for pos,data in pairs(_battlelog.ourHeroDatas) do
        local hero=BattleHero.new(self,Const.BATTLE_OBJ_OUR,data.pos,data)
        if _ourHero==nil then
            _ourHero=hero
            head=hero
        else
            _ourHero._next=hero
            _ourHero=hero
        end
    end
    _ourHero=head
    for pos,data in pairs(_battlelog.enemyHeroDatas) do
        local hero=BattleHero.new(self,Const.BATTLE_OBJ_ENEMY,pos,data)
        if _enemyHero==nil then
            _enemyHero=hero
            head=hero
        else
            _enemyHero._next=hero
            _enemyHero=hero
        end
    end
    _enemyHero=head
    local runDuration=0.1
    performWithDelay(self,function()
        self:startBattle()
    end,runDuration)
end
---------------------------
--创建己方
function BattleScene:createOur()
    --读取阵型
    local formations=Hero.getFormatByType(_formatType)     --阵型
    local heroDatas={}
    for i=1,Const.BATTLE_OBJ_SUM do
        if formations[i]>0 then
            local info=Hero.getHeroByHeroID(formations[i])
            local data={}
            data.pos=i
            local config=t_hero[info._heroID]
            local ability=Hero.getHeroAbility(info._heroID)
            data.name=config.name
            data.soldierId=config.solider_id
            data.img=config.img
            data.icon=config.icon
            data.elementType=config.type
            data.atk = ability.atk
            data.hp = ability.hp
            data.water = ability.water
            data.fire = ability.fire
            data.wood = ability.wood
            data.critRate = ability.critRate
            data.critrdRate = ability.critrdRate
            data.dodgeRate = ability.dodgeRate
            data.hitRate = ability.hitRate
            data.crit = ability.crit
            data.cure = ability.cure
            data.cate = 1
            data.skillNormal={config.skill1,1}
            data.skillAnger={config.skill2,1}
            data.skillStar3={config.skill3,info._skill3 or 0}
            data.skillStar5={config.skill4,info._skill5 or 0}
            data.skillStar7={config.skill5,info._skill7 or 0}
            data.level=info._lv
            data.starLevel=info._star
            data.quality=info._armsLv
            
            heroDatas[i]=data
        end
    end
    _battlelog.ourHeroDatas=heroDatas
    local head=nil
    for pos,data in pairs(heroDatas) do
        local hero=BattleHero.new(self,Const.BATTLE_OBJ_OUR,pos,data)
        if _ourHero==nil then
            _ourHero=hero
            head=hero
        else
            _ourHero._next=hero
            _ourHero=hero
        end
    end
    _ourHero=head
end

--创建PVE敌方怪物
--@param #t_team.lua team_config
function BattleScene:createMonsters(team_config)
    local monsterIds=team_config.monster
    local heroDatas={}
    for i=1,#monsterIds do
        if monsterIds[i]>0 then
            local data={}
            local config=monster_config[monsterIds[i]]
            local level=team_config.monster_lv[i]
            local starLevel=team_config.monster_xlv[i]
            data.name=config.name
            data.soldierId=config.solider_id
            data.img=config.img
            data.icon=config.icon
            data.elementType=config.type
            data.hp,data.atk=self:calcValue(level,starLevel,config.hp,config.atk)
            data.water = config.w_def
            data.fire = config.f_def
            data.wood = config.m_def
            data.critRate = config.crit_rate
            data.critrdRate = config.critrd_rate
            data.dodgeRate = config.dodge_rate
            data.hitRate = config.hit_rate
            data.crit = config.crit
            data.cure = config.cure
            data.cate = config.cate
            data.skillNormal={config.skill1,1}
            data.skillAnger={config.skill2,1}
            data.skillStar3={config.skill3,team_config.monster_slv[1]}
            data.skillStar5={config.skill4,team_config.monster_slv[2]}
            data.skillStar7={config.skill5,team_config.monster_slv[3]}
            data.level=level
            data.starLevel=starLevel
            data.quality=1
            heroDatas[i]=data
        end
    end
    _battlelog.enemyHeroDatas=heroDatas
    local head=nil
    for pos,data in pairs(heroDatas) do
        local hero=BattleHero.new(self,Const.BATTLE_OBJ_ENEMY,pos,data)
        if _enemyHero==nil then
            _enemyHero=hero
            head=hero
        else
            _enemyHero._next=hero
            _enemyHero=hero
        end
    end
    _enemyHero=head
end

--创建PVP敌方
function BattleScene:createPvpEnemy()

    local heros=Pvp._heros
    local heroDatas={}
    for key,heroData in pairs(heros) do
        if key~=-1 then
            local config=t_hero[heroData._categoryId]
            local data={}
            data.name=config.name
            data.soldierId=config.solider_id
            data.img=config.img
            data.icon=config.icon
            data.elementType=config.type
            data.atk = heroData._atk
            data.hp = heroData._hp
            data.water = heroData._water
            data.fire = heroData._fire
            data.wood = heroData._wood
            data.critRate = heroData._critp
            data.critrdRate = heroData._critrdp
            data.dodgeRate = heroData._dodgep
            data.hitRate = heroData._hitp
            data.crit = heroData._crit
            data.cure = heroData._cure
            data.cate = 1
            data.skillNormal={config.skill1,1}
            data.skillAnger={config.skill2,1}
            data.skillStar3={config.skill3,heroData._skillLevel3 or 0}
            data.skillStar5={config.skill4,heroData._skillLevel4 or 0}
            data.skillStar7={config.skill5,heroData._skillLevel5 or 0}
            data.level=heroData._lv
            data.starLevel=heroData._star
            data.quality=heroData._armsLv or 0
            data.pos=heroData._pos
            heroDatas[heroData._pos]=data
        end
    end
    _battlelog.enemyHeroDatas=heroDatas
    local head=nil
    for pos,data in pairs(heroDatas) do
        local hero=BattleHero.new(self,Const.BATTLE_OBJ_ENEMY,data.pos,data)
        if _enemyHero==nil then
            _enemyHero=hero
            head=hero
        else
            _enemyHero._next=hero
            _enemyHero=hero
        end
    end
    _enemyHero=head
end

-----------------------------
--@function 创建地图背景
function BattleScene:createBg(bgId)
    local winSize = cc.Director:getInstance():getWinSize()
    local sprBg=cc.Sprite:create(string.format("pic/battle_bg/%d.png",bgId))
    _uiLayer.panel_bg:addChild(sprBg)
end

function BattleScene:onEnter()
    _isStart=false
    self._updateID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(dt) self:update(dt) end,0,false)
    eventUtil.addCustom(self,"ui_battle_on_suspend_click",function(event)BattleScene.onSuspend(self,event)end)
    eventUtil.addCustom(self,"ui_battle_on_next_battle",function(event)BattleScene.onNextBattle(self,event)end)
    eventUtil.addCustom(self,"ui_battle_on_update_ball_ui",function(event)BattleScene.onUpdateBallUI(self,event)end)
--    self:initBall()
end

function BattleScene:onExit()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateID)
    eventUtil.removeCustom(self)
end

function BattleScene:update(dt)
    if not _isStart then return end
    if _isReplay then
        local deltaTime=os.time()-_battleStartTime
        if _battlelog.ourAngerSkills and #_battlelog.ourAngerSkills>1 then
            if _battlelog.ourAngerSkills[1][1]<=deltaTime then
                table.remove(_battlelog.ourAngerSkills,1)
                eventUtil.dispatchCustom(string.format("on_fire_anger_skill_%d_%d",1,_battlelog.ourAngerSkills[1][2]))
            end
        end
        if _battlelog.enemyAngerSkills and #_battlelog.enemyAngerSkills>1 then
            if _battlelog.enemyAngerSkills[1][1]<=deltaTime then
                table.remove(_battlelog.enemyAngerSkills,1)
                eventUtil.dispatchCustom(string.format("on_fire_anger_skill_%d_%d",2,_battlelog.enemyAngerSkills[1][2]))
            end
        end
    end

end

--暂停战斗
function BattleScene:onSuspend(event)
--    performWithDelay(self,function()
--        UIManager.popScene()
--    end,0)
--    self:playBallAnimation(1,false)
end

function BattleScene:createLayer()
    _layer = cc.Layer:create()
    --创建控制器
    _layer:addChild(require("battle/WeatherController"):create(self))
    _layer:addChild(require("battle/AudioController"):create(self))
    _layer:addChild(require("battle/SceneController"):create(self))
    
    _layer:registerScriptHandler(function(event)
        if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end)
    --    读取UI文件
    local winSize = _layer:getContentSize()
    _uiLayer=ccs.GUIReader:getInstance():widgetFromBinaryFile("ui/UIBattle.csb")
    widgetUtil.widgetReader(_uiLayer)
--    _uiLayer:setPosition(winSize.width/2-480,0)
    --暂停按钮
    _uiLayer.btn_suspend:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            eventUtil.dispatchCustom("ui_battle_on_suspend_click")
        end
    end)
    
    for i=1,4 do
        local img_skill=_uiLayer["img_skillframe"..tostring(i)]
        img_skill:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                    eventUtil.dispatchCustom("ui_battle_on_skill_click",i)
                end
            end)
    end
    
    self._uiLayer=_uiLayer
    _layer:addChild(_uiLayer,2)
    return _layer
end
---------------------------
--@function 显示战斗结算
function BattleScene:showSettlement(battleResult)
    --如果消逝时间没有超过3秒那么等待
    local elapseSec=os.difftime(os.time(),self._reportTime)
    local delay=2-elapseSec
    if not _isWin or delay<0 then
        delay=0
    end
    performWithDelay(_uiLayer,function()
        local param={}
        param.isWin=_isWin
        param.rate=self._rate
        param.items=battleResult.items or {}
        param.exp=battleResult.exp or 0
        param.gold=battleResult.gold or 0
        param.heroExp=battleResult.heroExp or 0
        _layer:addChild(BattleSettlement.create(param),3)
    end,delay)

end
---------------------------
--@function 向服务器发送结果
function BattleScene:reportResult()
    self._reportTime=os.time()
    if _isReplay then
        self:showSettlement({})
        return
    end
    local nWin=2
    if _isWin then nWin=1 end
    self._rate=0
    if _isWin then
        if _nRound<=t_parameter.three_star.var then
            self._rate=3
        elseif _nRound<=t_parameter.two_star.var then
            self._rate=2
        else
            self._rate=1
        end
       
    end
    
    if _battleType==Const.BATTLE_TYPE.PVE then
        local data={}
        data.chapter=_chapterId
        data.mode=_battleMode
        data.id=_copyId
        data.star=self._rate
        data.token=self._opt.token
        data.report=""
        self:request("copy.copyHandler.report",data,function(msg)
            if msg['code'] == 200 then
                self:showSettlement(msg["result"]["fight"])
            end
        end)
    elseif _battleType==Const.BATTLE_TYPE.ARENA then
        local data={}
        data.star=self._rate
        data.token=self._opt.token
        data.report=_battlelog

        self:request("arena.arenaHandler.report",data,function(msg)
            if msg['code'] == 200 then
                self:showSettlement(msg["result"]["fight"])
            end
        end)
    elseif _battleType==Const.BATTLE_TYPE.ROB_HOLLY_CUP then
        local data={}
        data.star=self._rate
        data.token=self._opt.token
        data.report=""

        self:request("sangreal.sangrealHandler.robResult",data,function(msg)
            if msg['code'] == 200 then
                self:showSettlement(msg["result"]["fight"])
            end
        end)    
        
    end
end

--珠子飞向英雄的动画
function BattleScene:playBallAnimation(e,isOur)
    local function createAction(delay,panel)
        local endX
        if isOur then
            endX=60
        else
            endX=350
        end
        local endPt=cc.p(math.random(100)+endX-panel:getPositionX(),math.random(150)-400)
        local bezier = {
            cc.p(100,-100),
            cc.p(300-math.random(1,600),-200),
            endPt,
        }
        
        return cc.Sequence:create(cc.DelayTime:create(delay),
            cc.BezierTo:create(0.2,bezier),
            cc.CallFunc:create(function()
                local animBomb=commonUtil.getAnim(3008)
                animBomb:PlaySection("s1",false)
                animBomb:setSpeedFactor(20/24)
                animBomb:setScale(1.6)
                animBomb:setPosition(endPt.x, endPt.y)
                panel:addChild(animBomb,1)
            end),
            cc.ScaleTo:create(0.1,0),
            cc.RemoveSelf:create()
        )
    end
    local delay=0
    for pos,v in pairs(_battleBalls) do
        local panel=_uiLayer["panel_ball_"..pos]
        if v.e==e then
            local size = panel:getContentSize()
            
            performWithDelay(panel,function()
                local animBomb=commonUtil.getAnim(3007)
                animBomb:PlaySection("s1",false)
                animBomb:setSpeedFactor(16/24)
                animBomb:setScale(1.4)
                animBomb:setPosition(size.width/2, size.height/2)
                panel:addChild(animBomb,3)
            end,delay)
            local iconBg=cc.Sprite:create("common/battle_ball_bg.png")
            local icon=cc.Sprite:create(string.format("ui/common_ball%d.png",v.e))
            icon:setScale(0.8)
            local bgSize=iconBg:getContentSize()
            icon:setPosition(bgSize.width/2, bgSize.height/2)
            iconBg:addChild(icon)
            
            iconBg:setPosition(size.width/2, size.height/2)
            iconBg:runAction(createAction(delay,panel))
            delay=delay+0.2
            panel:addChild(iconBg,2,0x100)
        end
    end
end

function BattleScene:getBallAmount(e)
    local res=0
    for i=1,6 do
        if _battleBalls[i] and _battleBalls[i].e==e then
            res=res+1
        end
    end
    return res
end
-----------------------------
--@function 战斗开始，初始化珠子
function BattleScene:initBall()
--    for i=1,6 do
--        _battleBalls[i]={e=math.random(1,3),isLock=false}
--    end
--	self:onUpdateBallUI()
end
----------------------------
--@function 更新珠子界面
function BattleScene:onUpdateBallUI()
--    for pos,v in pairs(_battleBalls) do
--        local panel=_uiLayer["panel_ball_"..pos]
--        if panel:getChildByTag(0x100)==nil then
--            local icon=cc.Sprite:create(string.format("ui/common_ball%d.png",v.e))
--            if icon then
--                local size = panel:getContentSize()
--                icon:setPosition(size.width/2, size.height/2)
--                icon:setScale(0.5)
--                icon:runAction(cc.ScaleTo:create(0.1,1))
--                panel:addChild(icon,1,0x100)
--            end
--        end
--    end
end
-----------------------------
--@function 转珠事件
function BattleScene:wheelBall(before,after,amount)
--    self:useBall(before,amount)
--    for i=1,6 do
--        if _battleBalls[i]==nil then
--            _battleBalls[i]={e=after,isLock=false}
--        end
--    end
--    self:onUpdateBallUI()
end
-----------------------------
--@function 生珠事件
function BattleScene:generateBall(e)
--    local nWater,nFire,nWood=0,0,0
--    if e==nil then
--        --如果是晴天，至少生成M颗火珠
--        local buff=BattleBuffMgr.get_buff(3,1036)
--        if buff~=nil then
--            nFire=buff._config.val
--        end
--        buff=BattleBuffMgr.get_buff(3,1037)
--        if buff~=nil then
--            nWater=buff._config.val
--        end
--        buff=BattleBuffMgr.get_buff(3,1047)
--        if buff~=nil then
--            nWood=buff._config.val
--        end
--    end
--    for i=1,6 do
--        if _battleBalls[i]==nil then
--            local ele=0
--            if e then
--                ele=e
--            else
--                if nWater>0 then
--                    nWater=nWater-1
--                    ele=1
--                end
--                if nFire>0 then
--                    nFire=nFire-1
--                    ele=2
--                end
--                if nWood>0 then
--                    nWood=nWood-1
--                    ele=3
--                end
--                if ele==0 then
--                    ele=math.random(1,3)
--                end
--            end
--            _battleBalls[i]={e=ele,isLock=false}
--        end
--    end
--    self:onUpdateBallUI()
end

-- 消珠事件
function BattleScene:useBall(e,amount)
--    local count=0
--    for i=1,6 do
--        if _battleBalls[i].e==e then
--            local panel=_uiLayer["panel_ball_"..i]
--            if panel:getChildByTag(0x100) then
--                panel:removeChildByTag(0x100)
--            end
--            local anim=commonUtil.getAnim(3001)
--            if anim then
--                local size = panel:getContentSize()
--                anim:setPosition(size.width/2, size.height/2)
--                anim:PlaySection("s1",false)
--                panel:addChild(anim,2)
--            end
--            _battleBalls[i]=nil
--            count=count+1
--            if amount then
--                if count>=amount then break end
--            end
--        end
--    end
end

function BattleScene:getOurHero()
    return _ourHero
end

function BattleScene:getEnemyHero()
    return _enemyHero
end

---------------------------
--战斗开始
--@return
function BattleScene:startBattle()
    BattleBuffMgr.init()
    _uiLayer.panel_our_buff:removeAllChildren()
    _uiLayer.panel_enemy_buff:removeAllChildren()
    _uiLayer.panel_our_buff_face:removeAllChildren()
    _uiLayer.panel_enemy_buff_face:removeAllChildren()
    _uiLayer.panel_our_buff._buffIcons={}
    _uiLayer.panel_enemy_buff._buffIcons={}
    _isStart=true
    _nRound=0
    commonUtil.getAnim(3004)
    self._angerSkillList={} --怒气技能释放列表
    if not _isReplay then
        _battlelog.seed=tostring(os.time()):reverse():sub(1, 6)
    end
    math.randomseed(tonumber(_battlelog.seed))
    _battleStartTime=os.time()
    
    _ourHero:toBattle()
    _enemyHero:toBattle()
    
    performWithDelay(_uiLayer,function()
        eventUtil.dispatchCustom("on_random_weather")
        self:increaseRound()
        self:nextBattle()
    end,0.1)
end

---------------------------
--@return
function BattleScene:nextBattle()

    if _nRound>t_parameter.one_star.var then
        _isWin=false
        self:reportResult()
        return
    end

    if _ourHero:isDead() and _ourHero._next==nil then
        _ourHero:setDead()
        _enemyHero._anim:setVisible(true)
        _isWin=false
        self:reportResult()
        return
    end
    if _enemyHero:isDead() and _enemyHero._next==nil then
        _ourHero._anim:setVisible(true)
        _ourHero:setVictoryState()
        _enemyHero:setDead()
        _isWin=true
        self:reportResult()
        return
    end
    
    --如果怒气技能列表有英雄
    if #self._angerSkillList>0 then
        local hero=self._angerSkillList[1].hero
        local skill=self._angerSkillList[1].skill
        if hero:isOur() then
            hero._target=_enemyHero
        else
            hero._target=_ourHero
        end
        --如果目标死亡
        if hero._target:isDead() then
            performWithDelay(_uiLayer,function()
                self:onHeroDead(hero._target:isOur())
            end,1)
            return
        end
        if _ourHero:isDead() then
            performWithDelay(_uiLayer,function()
                self:onHeroDead(_ourHero:isOur())
            end,1)
            return
        end
        table.remove(self._angerSkillList,1)
        if skill==Const.SKILL_TYPE_ANGER then
            hero:fireAngerAtk()
        elseif skill==Const.SKILL_TYPE_STAR_3 then
            hero:fire3StarAtk()
        elseif skill==Const.SKILL_TYPE_STAR_5 then
            hero:fire5StarAtk()
        elseif skill==Const.SKILL_TYPE_STAR_7 then
            hero:fire7StarAtk()
        end
        return
    end
    
    if not _ourHero:isDead() then
        _ourHero._anim:setVisible(true)
    end
    if not _enemyHero:isDead() then
        _enemyHero._anim:setVisible(true)
    end
    if _ourHero._attacked then
        if _enemyHero._attacked then
            self:increaseRound()
            self:nextBattle()
        else
            _enemyHero:strike(_ourHero)
        end
    else
        _ourHero:strike(_enemyHero)
    end
    
end
---------------------------
--@function 增加轮数
function BattleScene:increaseRound()
    _nRound=_nRound+1
--    _uiLayer.label_round:setString(tostring(_nRound))
    if _nRound>1 then
        eventUtil.dispatchCustom("on_call_per_round",_nRound)
        BattleBuffMgr.schedule_per_round()
    end
    print("------------第",_nRound,"轮---------------")
    
end

---------------------------
--@return
function BattleScene:onHeroDead(isOur)
    if isOur then
        _uiLayer.panel_our_buff_face:removeAllChildren()
        BattleBuffMgr.clear_hero_buff(1)
        _ourHero:setDead()
        _ourHero=_ourHero._next
        if _ourHero==nil then
            _isWin=false
            self:reportResult()
            return
        end
        _ourHero:toBattle()
    else
        _uiLayer.panel_enemy_buff_face:removeAllChildren()
        BattleBuffMgr.clear_hero_buff(2)
        _enemyHero:setDead()
        _enemyHero=_enemyHero._next
        if _enemyHero==nil then
            _isWin=true
            _ourHero:setVictoryState()
            self:reportResult()
            return
        end
        _enemyHero:toBattle()
    end
    performWithDelay(_uiLayer,function()
        --self:increaseRound()
        self:nextBattle()
    end,1.5)
end

--添加怒气技能战报
function BattleScene:appendAngerSkillLog(bOur,heroPos)
    if _isReplay then return end
    local fireTime=os.time()-_battleStartTime
    if bOur then
        table.insert(_battlelog.ourAngerSkills,{fireTime,heroPos})
    else
        table.insert(_battlelog.enemyAngerSkills,{fireTime,heroPos})
    end
end

function BattleScene:isReplay()
    return _isReplay
end

---------------------------
--播放背景音乐
--@param 音乐ID
function BattleScene:playGroundMusic(id)
    commonUtil.playBakGroundMusic(id)
end

return BattleScene
