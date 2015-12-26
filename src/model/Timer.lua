module("Timer", package.seeall)

local t_parameter = require("config/t_parameter")
local t_train_lv = require('src/config/t_train_lv')
local t_lv =require('config/t_lv')

local strengthTimer = nil

local heroExpTimer = nil --英雄训练经验增长定时器

--体力增长定时器
function startStrengthTime()
    if nil ~= strengthTimer then
        return
    end
    
    local scheduler = cc.Director:getInstance():getScheduler()
    local timer = function(dt)
        local max = t_parameter["strength_max"]["var"]
        local refleshTime = t_parameter["strength_reflesh_time"]["var"]
        
        local now = Game.time()
        local last = Character.strthTime
        
        local change = false
        
        while(Character.strength<max and (last+refleshTime)<=now) do
            Character.strength = Character.strength + 1
            Character.strthTime = Character.strthTime + refleshTime
            last = Character.strthTime
            change = true
        end
        
        if change then
            Event.notify(Const.EVENT.STRENGTH)
        end
    end
    strengthTimer = scheduler:scheduleScriptFunc(timer, 0.5, false)
end

function stopStrengthTime()
    if nil == strengthTimer then
        return
    end
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:unscheduleScriptEntry(strengthTimer)
    strengthTimer = nil
end

--英雄训练经验增长定时器
function startHeroExpTimer()
    if nil ~= heroExpTimer then
        return
    end

    local scheduler = cc.Director:getInstance():getScheduler()
    local Exptimer = function(dt)
        local now = Game.time()
        local change = false
        
        local posLvs = Hero.getHeroPos()
        local heroList = Hero.getHeroList() --英雄列表
        for i=1, #heroList do
            local hero = heroList[i]
            if hero._pos > 0 then --在训练
                local posLv = posLvs[hero._pos]  --格子的等级
                local expMin = t_train_lv[posLv]["exp"] --每分钟增长多少经验
                local timeGo = now - hero._time
                if timeGo > 0 then
                    if hero._lvTmp < Character.level then --小于玩家等级
                        local expUp = math.ceil(timeGo/60 * expMin) --增加的经验
                        
                        local lv = hero._lvTmp
                        local exp = hero._expTmp
                        while expUp > 0 do
                            if lv >= Character.level then
                                break
                            end

                            local max = t_lv[lv]["hero_up_exp"]
                            if exp + expUp >= max then
                                lv = lv + 1
                                exp = 0

                                expUp = expUp - (max - exp)
                            else
                                exp = exp + expUp
                                expUp = 0
                            end
                        end

                        if hero._lv ~= lv or hero._exp ~= exp then
                            hero._lv = lv
                            hero._exp = exp

                            change = true
                        end
                    end                    
                end
            end
        end

        if change then
            Event.notify(Const.EVENT.HERO_EXP)
        end
    end
    
    heroExpTimer = scheduler:scheduleScriptFunc(Exptimer, 1.0, false)
end

function stopHeroExpTime()
    if nil == heroExpTimer then
        return
    end
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:unscheduleScriptEntry(heroExpTimer)
    heroExpTimer = nil
end
