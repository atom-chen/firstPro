local t_skill_formula = {
	[1001]={skill_formula="return function(a, b, c) return math.abs(a+b*c)  end",a="s_val1_1",b="s_var1_1",c="skill_lv",desc1="第一策略：值=（基础值1+变量1*技能等级）"},
	[1002]={skill_formula="return function(a, b, c) return math.abs((a+b*c)/10000)  end",a="s_val1_1",b="s_var1_1",c="skill_lv",desc1="第一策略：值=（基础值1+变量1*技能等级）/10000"},
	[1003]={skill_formula="return function(a, b, c) return math.abs(a+b*c)  end",a="s_val1_2",b="s_var1_2",c="skill_lv",desc1="第二策略：值=（基础值1+变量1*技能等级）"},
	[1004]={skill_formula="return function(a, b, c) return math.abs((a+b*c)/10000)  end",a="s_val1_2",b="s_var1_2",c="skill_lv",desc1="第二策略：值=（基础值1+变量1*技能等级）/10000"},
	[2001]={skill_formula="return function(a, b, c) return math.abs(a+b*(c+1))  end",a="s_val1_1",b="s_var1_1",c="skill_lv",desc1="第一策略升级：值=（基础值1+变量1*技能等级）"},
	[2002]={skill_formula="return function(a, b, c) return math.abs((a+b*(c+1))/10000)  end",a="s_val2_1",b="s_var2_1",c="skill_lv",desc1="第一策略升级：值=（基础值1+变量1*技能等级）/10000"},
	[2003]={skill_formula="return function(a, b, c) return math.abs(a+b*(c+1))  end",a="s_val1_2",b="s_var1_2",c="skill_lv",desc1="第二策略升级：值=（基础值1+变量1*技能等级）"},
	[2004]={skill_formula="return function(a, b, c) return math.abs((a+b*(c+1))/10000)  end",a="s_val1_2",b="s_var1_2",c="skill_lv",desc1="第二策略升级：值=（基础值1+变量1*技能等级）/10000"}
}

return t_skill_formula
