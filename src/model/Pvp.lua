module("Pvp", package.seeall)

--module require

--variable
abilityProperty = {
    _categoryId=0,  --ID
    _pos=0,         --阵型位置
    
    _atk = 0,   --攻击
    _hp = 0,    --生命
    _water = 0, --水防御
    _fire = 0,  --火防御
    _wood = 0,  --木防御
    
    _critp = 0, --暴击率(万分比)
    _critrdp = 0, --暴击减免率(万分比)
    _dodgep = 0, --闪避率(万分比)
    _hitp = 0, --命中率(万分比)
    _crit = 0, --暴击加成(万分比)
    _cure = 0, --治疗加成(万分比)
    
    _lv = 1, --等级
    _star = 0, --星级
    
    _skill1=1001,  --普攻ID
    _skill2=0,  --怒气ID
    _skill3=0,  --三星ID
    _skill4=0,
    _skill5=0,
    _skillLevel1=1, --普攻技能等级
    _skillLevel2=0, --怒气技能等级
    _skillLevel3=0,
    _skillLevel4=0,
    _skillLevel5=0
}

_format = {}    --阵型
_heros = {}     --英雄
_user = {} --{nick = "", power = 0}
_token = "" --战斗标识

--function
function parsePvp(pvp)
    _user = pvp["user"]
    _format = pvp["format"]
    _token = pvp["token"]
    
    local heros = pvp["heros"]
    if heros then
        for i=1, #heros do
            local item = heros[i]
            local heroID = item["id"]
            
            local hero = clone(abilityProperty)
            hero._atk = item["atk"]
            hero._hp = item["hp"]
            hero._water = item["water"]
            hero._fire = item["fire"]
            hero._wood = item["wood"]
            hero._categoryId = heroID
            
            hero._critp = item["critp"]
            hero._critrdp = item["critrdp"]
            hero._dodgep = item["dodgep"]
            hero._hitp = item["hitp"]
            hero._crit = item["crit"]
            hero._cure = item["cure"]
            
            hero._skillLevel3=item["skill"][1]
            hero._skillLevel4=item["skill"][2]
            hero._skillLevel5=item["skill"][3]
            
            hero._lv = item["lv"]
            hero._star = item["star"]
            
            for i=1,#_format do
                if _format[i]==heroID then
                    hero._pos=i
                    break
                end
            end
    
            _heros[heroID] = hero
        end
    end
end

--获取token
function getToken()
    return _token
end