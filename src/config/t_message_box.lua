local t_message_box = {
[1]={type=2,func=1,message="您的钻石不足，是否进行充值？",desc="钻石不足时",desc_type="通用"},
[2]={type=1,func=0,message="您的金币不足！",desc="金币不足时",desc_type="通用"},
[3]={type=2,func=0,message="是否保存当前圣杯？",desc="切换圣杯，点击【关闭】按钮",desc_type="圣杯"},
[4]={type=3,func=0,message="是否花费20钻石购买一次碎片保护，可防止圣杯碎片被抢夺！",desc="碎片保护【购买】",desc_type="圣杯"},
[5]={type=3,func=0,message="今日抢夺次数不足，是否花费20钻石进行购买?",desc="抢夺其它玩家时，抢夺次数不足时",desc_type="圣杯"},
[6]={type=1,func=0,message="该玩家正在被其他玩家抢夺中，稍等一会再试吧！",desc="抢夺其它玩家时，玩家正在被抢中",desc_type="圣杯"},
[7]={type=1,func=0,message="该玩家今日已被其他玩家抢空了，可怜可怜他吧！",desc="抢夺其它玩家时，玩家被抢次数=3",desc_type="圣杯"},
[8]={type=1,func=0,message="恭喜你，碎片抢夺成功！",desc="抢夺其它玩家成功",desc_type="圣杯"},
[9]={type=1,func=0,message="真遗憾，碎片抢夺失败！",desc="抢夺其它玩家失败",desc_type="圣杯"},
[10]={type=1,func=0,message="真可悲，你抢到了假的碎片！",desc="抢夺其它玩家成功，但有碎片保护",desc_type="圣杯"}
}
return t_message_box 
