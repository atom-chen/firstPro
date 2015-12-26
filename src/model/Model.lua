module("Model", package.seeall)

--module require
require("src/model/Hero")
require("src/model/Character")
require("src/model/Item")
require("src/model/Copy")
require("src/model/Pvp")
require("src/model/Sangreal")
require("src/model/Arena")
require("src/model/Mail")
require("src/model/Chat")
require("src/model/KeyWordFilter")
require("src/model/Reconnect")
require("src/model/CardReward")
require("src/model/Timer")
require("src/model/Sign")
require("src/model/GameGuide")

--variable

--function
function parse(res)
    if res['lag'] then
        Game.setTimeLag(res['lag'])
    end
    if res['zone'] then
        Game.setTimeZone(res['zone'])
    end
    if res['hero'] then
        Hero.parseHero(res['hero'])
    end
    if res['user'] then
        Character.parseUser(res['user'])
    end
    if res['item'] then
        Item.parseItems(res['item'])
    end
    if res['copy_val'] then
        Copy.parseCopyVal(res['copy_val'])
    end
    if res['copy'] then
        Copy.parseCopy(res['copy'])
    end
    if res['pvp'] then
        Pvp.parsePvp(res['pvp'])
    end
    if res['sangreal'] then
        Sangreal.parseSangreal(res['sangreal'])
    end
    if res['fragment'] then
        Sangreal.parseFragment(res['fragment'])
    end
    if res['enemy'] then
        Sangreal.parseEnemy(res['enemy'])
    end
    if res['fragpvp'] then
        Sangreal.parseFragpvp(res['fragpvp'])
    end
    if res['arena'] then
        Arena.parseArena(res['arena'])
    end
    if res['arenarank'] then
        Arena.parseArenaRank(res['arenarank'])
    end
    if res['challenge'] then
        Arena.parseChallenge(res['challenge'])
    end
    if res['mail'] then
        Mail.parseMail(res['mail'])
    end
    if res['chat'] then
        Chat.parseChat(res['chat'])
    end
    if res['record'] then
        Arena.parseRecord(res['record'])
    end
    if res['recordNew'] then --插入单挑战斗记录
        Arena.parseRecordNew(res['recordNew'])
    end
    if res['report'] then --战报
        Arena.parseReport(res['report'])
    end
    if res['card'] then --抽卡
        CardReward.parseCard(res['card'])
    end
    if res['reward'] then --奖励
        Item.parseRewardItems(res['reward'])
    end
    if res['daily'] then --每日限数
        Character.parseDaily(res['daily'])
    end
    if res['sign'] then    --签到
        Sign.parseSign(res['sign'])
    end
    if res['activity'] then    --活动
        Copy.parseActivity(res['activity'])
    end
    if res['shop'] then    --普通商店
        Item.parseShops(res["shop"])
    end
end

function onEvent(event, msg)
    if event == "onChat" then --全服聊天推送
        Chat.parseWorldChat(msg)
    end
    if event == "onMail" then --邮件推送
        Mail.parseNewMail(msg)
    end
    if event == "onCharge" then --充值推送
        Character.parseCharge(msg)
    end
    
    if event == "disconnect" then --断线
        Reconnect.disconnectEvent()
    end
    
    if event == "onActivity" then --推送活动
        Copy.parseActivity(msg)
    end
end

