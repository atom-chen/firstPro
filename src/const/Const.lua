
module("Const",package.seeall)

DENOMINATOR=10000        --各种概率值的分母

HERO_ELEMENT_WATER=1     --水
HERO_ELEMENT_FIRE=2      --火
HERO_ELEMENT_WOOD=3      --木
HERO_ELEMENT_NONE=4      --无属性

--天气枚举
WEATHER=commonUtil.createEnum({
    "NONE",
    "SUNNY",
    "RAIN",
    "FOG"
})

BATTLE_ANGER_SUM=10000   --战斗怒气总点数
BATTLE_OBJ_SUM=4         --战斗上阵英雄总人数
SOLDIER_ROW_SUM=3        --士兵行数
SOLDIER_COL_SUM=3        --士兵排数

BATTLE_OBJ_OUR=1         --己方
BATTLE_OBJ_ENEMY=2       --敌方

SKILL_TYPE_NORMAL=1      --普通攻击
SKILL_TYPE_STAR_3=2      --三星技
SKILL_TYPE_STAR_5=3      --五星技
SKILL_TYPE_STAR_7=4      --七星技
SKILL_TYPE_ANGER=5       --怒气技能

--技能动画类型
SKILL_EFFECT_RAY=1      --射线
SKILL_EFFECT_SINGLE=2   --单体
SKILL_EFFECT_LOCAL=3    --局部
SKILL_EFFECT_WHOLE=4    --整体
SKILL_EFFECT_SCENE1=5   --场景1=黑屏+对象+单体
SKILL_EFFECT_SCENE2=6   --场景2=黑屏+对象+局部
SKILL_EFFECT_SCENE3=7   --场景3=黑屏+对象中央+整体

--BUFF类型
BUFF_TYPE=commonUtil.createEnum({
    "DEEP_HURT",        --重伤
    "SILENT",           --沉默
    "VERTIGO",          --晕眩
    "REFLEX_WATER",     --反射
    "REFLEX_FIRE",      --反射
    "REFLEX_WOOD",      --反射
    "BLOCK",            --格挡
    "USE_BALL_DEC",     --技能消耗珠子时，消耗减少N个
    "USE_BALL_PLUS",    --技能消耗珠子时，消耗增加N个
    "ATK_UP",           --攻击上升
    "ATK_DOWN",         --攻击下降
    "DEF_UP_WATER",     --水防御上升
    "DEF_UP_FIRE",      --火防御上升
    "DEF_UP_WOOD",      --木防御上升
    "DEF_DOWN_WATER",   --防御下降
    "DEF_DOWN_FIRE",    --防御下降
    "DEF_DOWN_WOOD",    --防御下降
    "HP_UP",            --生命上升
    "HP_DOWN"           --生命下降
})

MAX_STRENGTH=120    --最大体力值
MAX_LEVEL=99        --最高等级
MAX_STAR=5          --最高星级
MAX_ARMS_LV=14          --最高武器等级

--兵种类型
SOLDIER_TYPE=commonUtil.createEnum({
    "SPECIAL",      --特殊
    "SOWAR",        --骑兵
    "ARCHER",       --射兵
    "INFANTRY"      --步兵
},-1)

--阵型编组
FORMATION_TYPE = commonUtil.createEnum({
    "ATTACK",        --攻击
    "DEFENSE"        --防守
})

BATTLE_TYPE = commonUtil.createEnum({
    "PVE",            --副本
    "ROB_HOLLY_CUP",  --掠夺圣杯
    "ARENA"           --竞技场
})

--商店类型
SHOP_TYPE =commonUtil.createEnum({
    "COMMON",    --普通
    "SCORE",     --积分兑换
    "BADGE"        --徽章兑换
})

--英雄属性
HERO_ATTR_TYPE = commonUtil.createEnum({
    "NONE",         --不区分属性
    "SHUI",         --水
    "HUO",          --火
    "MU"            --木
}, -1)

--英雄属性图标
HERO_ATTR_BALL_SHUI = 'res/common/common_ball_img1.png'
HERO_ATTR_BALL_HUO = 'res/common/common_ball_img2.png'
HERO_ATTR_BALL_MU = 'res/common/common_ball_img3.png'


--英雄装备信息界面按钮状态
HERO_EQUIP_INFO_FORMULA='res/common/hero_equip_label1.png'   --合成公式
HERO_EQUIP_INFO_SURE='res/common/common_label6.png'      --确定
HERO_EQUIP_INFO_PUTON='res/common/hero_equip_label3.png'     --装备
HERO_EQUIP_INFO_WAY='res/common/hero_equip_label4.png'       --获取路径

--副本模式
COPY_MODE = commonUtil.createEnum({
    "NORMAL",       --常规模式
    "ELITE"         --精英模式
})

--章节类型
CHAPTER_TYPE = {
    NORMAL = 1,   --普通章节
    BOSS = 2,     --BOSS章节
    ACTIVITY = 3  --活动章节
}

--副本类型
COPY_TYPE = {
    START = 0,        --起始点
    SMALL_FIGHT = 1,  --小战斗
    BIG_FIGHT = 2,    --大战斗
    GOLD = 3,         --金币
    BOX = 4,          --金宝箱
    HP_BOSS = 5,       --boss战斗
    EMPTY = 6       --空格
}

--英雄选择状态
HERO_SELECT_STATE = commonUtil.createEnum({
    "EQUIP",       --强化
    "SKILL",    --技能
    "FATE"      --羁绊
})

EVENT = {
    HEROS   = "heros",  --英雄
    FORMAT  = "format", --阵型
    USER    = "user",   --玩家信息
    PLAYER  = "player",  --主角信息
    ITEM    = "item",    --玩家拥有物品信息
    MAIL    = "mail",    --新邮件
    CHARGE  = "charge",   --用户充值
    GUIDE  = "guide",   --新手引导
    HERO_EXP  = "heroExp",   --训练中的英雄的经验变化
    STRENGTH = "strength"   --体力
}

ITEM = {
    --SKILL_STONE_ITEM_ID=3201,   --技能石物品编号
    COPY_PERMIT = 3601,         --通关券
    BADGE_ITEM_ID = 3701,       --徽章id          
}

SANGREAL_PIECE={   
    ONE_ID=6001,            --碎片一编号
    TWO_ID=6002,            --碎片二编号
    THREE_ID=6003,          --碎片三编号
    FOUR_ID=6004,           --碎片四编号
    FIVE_ID=6005,           --碎片五编号
    SIX_ID=6006,            --碎片六编号
}

SKILL = {
    SKILL_STAR_1= 1,     --怒气技能标识
    SKILL_STAR_3= 3,    --三星技能标识
    SKILL_STAR_5= 5,    --五星技能标识
    SKILL_STAR_7= 7,    --七星技能标识
}

COLOR = {
    GREEN=cc.c4b(0,255,0,255),      --绿色
    BLUE=cc.c4b(0,0,255,255),       --蓝色
    PURPLE=cc.c4b(255,0,255,255),   --紫色
    RED=cc.c4b(255,0,0,255),        --红色
    GOLDEN=cc.c4b(255,255,0,255)    --金色
}

--网络错误代码标识
NET_WORK_ERROR_CODE = {
    ARENA_RANK_CHANGED = 1000   --玩家名次已变更，请重新选择
}

--新手指引触发类型
GAME_GUIDE_TYPE = {
    NORMAL = 0, --打开面板或鼠标点击 
    LEVEL = 1, --满足等级
    REGIST = 99999, --面板注册事件，不对配置表格开放
}

--新手指引参数类型
GAME_GUIDE_PARAM = {
    type = 0,     --GAME_GUIDE_TYPE
    param1 = nil, --参数1
    param2 = nil  --参数2
}

--加经验药水
EXP_POTION={   
    LEV1 = 3001,            --1级药水
    LEV2 = 3002,            --2级药水
    LEV3 = 3003,            --3级药水
    LEV4 = 3004,            --4级药水
}

--物品类型
ITEM_TYPE = {
    HERO = 1,  --英雄
    NORMAL = 2, --普通物品
    RAND = 3,  --随机属性物品（没用）
    RESOURCE = 4, --资源金币，钻石
    GIFT = 5,  --礼包
    PIECE = 6 --圣杯碎片
}