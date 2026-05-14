extends Resource
class_name 神魂

enum 品级 { 凡品, 良品, 上品, 极品, 天品 }

const 品级名: Array[String] = ["凡品", "良品", "上品", "极品", "天品"]
const 品级颜色: Array[String] = ["#9d9d9d", "#ffffff", "#ffd700", "#ff6b6b", "#ff00ff"]

@export var 名称: String = ""
@export var 池ID: String = ""
@export var 品级索引: int = 0
@export var 普攻技能ID: String = ""
@export var 大招技能ID: String = ""
@export var 基础属性名: String = ""
@export var 基础属性值: int = 0
@export var 描述: String = ""
@export var 是否临时: bool = false


static func _自加载() -> Script:
	return load("res://通用/装备/神魂.gd")


static func 从模板行创建(行: Dictionary) -> Resource:
	var 新神魂: Resource = _自加载().new()
	新神魂.池ID = 行.get("pool_id", "")
	新神魂.名称 = 行.get("name", "")
	新神魂.品级索引 = int(行.get("tier", 0))
	新神魂.普攻技能ID = 行.get("normal_attack_skill", "")
	新神魂.大招技能ID = 行.get("ultimate_skill", "")
	新神魂.基础属性名 = 行.get("base_affix_type", "")
	var 最小值: int = int(行.get("base_affix_min", 0))
	var 最大值: int = int(行.get("base_affix_max", 0))
	新神魂.基础属性值 = randi_range(最小值, 最大值)
	新神魂.描述 = 行.get("description", "")
	return 新神魂


static func 从池随机创建(池数据: Array[Dictionary], 目标品级: int, 敌人模板: String) -> Resource:
	var 候选池: Array[Dictionary] = 池数据.filter(func(行):
		return int(行.get("tier", 0)) == 目标品级 and 行.get("enemy_template", "") == 敌人模板
	)
	if 候选池.is_empty():
		return null
	var 总权重 := 0
	for 条目 in 候选池:
		总权重 += int(条目.get("weight", 1))
	var 随机值 := randi_range(1, 总权重)
	var 累计 := 0
	for 条目 in 候选池:
		累计 += int(条目.get("weight", 1))
		if 随机值 <= 累计:
			return 从模板行创建(条目)
	return 从模板行创建(候选池[0])


static func 能否合成(a: Resource, b: Resource) -> bool:
	if a == null or b == null:
		return false
	return a.池ID == b.池ID and a.品级索引 == b.品级索引 and a.品级索引 < 品级.天品


static func 执行合成(基底: Resource, 材料: Resource) -> Resource:
	assert(能否合成(基底, 材料))
	var 新神魂: Resource = _自加载().new()
	新神魂.品级索引 = 基底.品级索引 + 1
	新神魂.名称 = 基底.名称 + "·进阶"
	新神魂.池ID = 基底.池ID
	新神魂.普攻技能ID = 基底.普攻技能ID
	新神魂.大招技能ID = 基底.大招技能ID
	新神魂.基础属性名 = 基底.基础属性名
	新神魂.基础属性值 = int(基底.基础属性值 * 1.3)
	新神魂.描述 = 基底.描述
	print("[神魂] 合成: %s(%s) + %s(%s) = %s(%s)" % [
		基底.名称, 基底.获取品级名(),
		材料.名称, 材料.获取品级名(),
		新神魂.名称, 新神魂.获取品级名()
	])
	return 新神魂


func 获取品级名() -> String:
	if 品级索引 >= 0 and 品级索引 < 品级名.size():
		return 品级名[品级索引]
	return "凡品"


func 获取品级颜色() -> String:
	if 品级索引 >= 0 and 品级索引 < 品级颜色.size():
		return 品级颜色[品级索引]
	return "#9d9d9d"


func 系列化() -> Dictionary:
	return {
		"名称": 名称,
		"池ID": 池ID,
		"品级索引": 品级索引,
		"普攻技能ID": 普攻技能ID,
		"大招技能ID": 大招技能ID,
		"基础属性名": 基础属性名,
		"基础属性值": 基础属性值,
		"描述": 描述
	}


static func 反系列化(数据: Dictionary) -> Resource:
	var 新神魂: Resource = _自加载().new()
	新神魂.名称 = 数据.get("名称", "")
	新神魂.池ID = 数据.get("池ID", "")
	新神魂.品级索引 = int(数据.get("品级索引", 0))
	新神魂.普攻技能ID = 数据.get("普攻技能ID", "")
	新神魂.大招技能ID = 数据.get("大招技能ID", "")
	新神魂.基础属性名 = 数据.get("基础属性名", "")
	新神魂.基础属性值 = int(数据.get("基础属性值", 0))
	新神魂.描述 = 数据.get("描述", "")
	return 新神魂
