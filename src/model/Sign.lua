module("Sign", package.seeall)

local time=0   --月份值*100
local mark=1   -- 1为每天第一次登入
local signs={}  --签到情况，大小为这个月天数，》0表示有签到
local rewards={}  --放31个物品


--签到解析
function parseSign(sign)
	time=sign["time"]
	mark=sign["mark"]    --0已经签到
	signs=sign["signs"]
    rewards=sign["rewards"]  --[{itemID:1,num:1,vip:1(没有就不传)}]
end

--获得月份
function getMonth()
    return time%100
end
--获得这个月天数
function getMonthDays()
    return #signs
end

function isFirst()
	return mark~=0
end

function setSignAlready()
	mark=0
end

--获得这个月已签到的天数
function getSignDays()
    local days=0
    for i=1, #signs do
    	if signs[i]>0 then
    		days=days+1
        else
            break		
    	end
    end
    return days
end

--获取签到物品表
function getSignItems()
    return rewards
end