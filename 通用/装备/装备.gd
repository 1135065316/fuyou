extends Resource
class_name 装备

enum 部位 { 武器, 法冠, 道袍, 步履, 饰品 }
enum 技能类型 { 主动, 被动 }

const 部位名: Dictionary = {
	部位.武器: "武器", 部位.法冠: "法冠",
	部位.道袍: "道袍", 部位.步履: "步履", 部位.饰品: "饰品"
}

enum 品级 { 凡品, 良品, 上品, 极品, 天品 }

const 品级名: Array[String] = ["凡品", "良品", "上品", "极品", "天品"]
const 品级颜色: Array[String] = ["#9d9d9d", "#ffffff", "#ffd700", "#ff6b6b", "#ff00ff"]

@export var 名称: String = ""
@export var 池ID: String = ""
@export var 部位索引: int = 0
@export var 品级索引: int = 0
@export var 基础属性名: String = ""
@export var 基础属性值: int = 0
@export var 基础属性最小值: int = 0
@export var 基础属性最大值: int = 0
@export var 普通词条: Array[Dictionary] = []
@export var 特殊词条: Array[String] = []
@export var 技能列表: Array[Dictionary] = []
@export var 描述: String = ""
@export var 是否临时: bool = false


# 用 load() 自引用避免编译期 class_name 未注册问题
static func _自加载() -> Script:
	return load("res://通用/装备/装备.gd")


static func 从模板行创建(行: Dictionary) -> Resource:
	var 新装备: Resource = _自加载().new()
	新装备.池ID = 行.get("pool_id", "")
	新装备.名称 = 行.get("name", "")
	新装备.部位索引 = int(行.get("slot", 0))
	新装备.品级索引 = int(行.get("tier", 0))
	新装备.基础属性名 = 行.get("base_affix_type", "")
	新装备.基础属性最小值 = int(行.get("base_affix_min", 0))
	新装备.基础属性最大值 = int(行.get("base_affix_max", 0))
	新装备.基础属性值 = randi_range(新装备.基础属性最小值, 新装备.基础属性最大值)
	新装备.描述 = 行.get("description", "")

	var 普通词条JSON: String = 行.get("normal_affixes", "[]")
	var 解析结果: Variant = JSON.parse_string(普通词条JSON)
	if 解析结果 != null and 解析结果 is Array:
		for 条目 in 解析结果:
			var 最小: int = int(条目.get("min", 0))
			var 最大: int = int(条目.get("max", 0))
			var 值 := randi_range(最小, 最大)
			新装备.普通词条.append({
				"属性名": 条目.get("type", ""),
				"值": 值,
				"最小值": 最小,
				"最大值": 最大
			})

	var 特殊词条JSON: String = 行.get("special_affixes", "[]")
	解析结果 = JSON.parse_string(特殊词条JSON)
	if 解析结果 != null and 解析结果 is Array:
		for 条目 in 解析结果:
			新装备.特殊词条.append(str(条目))

	var 技能JSON: String = 行.get("skills", "[]")
	解析结果 = JSON.parse_string(技能JSON)
	if 解析结果 != null and 解析结果 is Array:
		for 条目 in 解析结果:
			新装备.技能列表.append({
				"id": str(条目.get("id", "")),
				"type": str(条目.get("type", "被动")),
				"cooldown": float(条目.get("cooldown", 0.0))
			})

	return 新装备


static func 从池随机创建(池数据: Array[Dictionary], 层数: int) -> Resource:
	var 候选池: Array[Dictionary] = []
	for 条目 in 池数据:
		var 最小层: int = int(条目.get("min_floor", 1))
		var 最大层: int = int(条目.get("max_floor", 9))
		if 层数 >= 最小层 and 层数 <= 最大层:
			候选池.append(条目)

	if 候选池.is_empty():
		push_warning("[装备] 未找到适合第%d层的装备模板" % 层数)
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


func 获取所有属性加成() -> Dictionary:
	var 结果: Dictionary = {}
	if not 基础属性名.is_empty():
		结果[基础属性名] = 基础属性值
	for 词条 in 普通词条:
		var 名: String = 词条.get("属性名", "")
		var 值: int = int(词条.get("值", 0))
		if 结果.has(名):
			结果[名] = 结果[名] + 值
		else:
			结果[名] = 值
	return 结果


func 获取品级名() -> String:
	if 品级索引 >= 0 and 品级索引 < 品级名.size():
		return 品级名[品级索引]
	return "凡品"


func 获取品级颜色() -> String:
	if 品级索引 >= 0 and 品级索引 < 品级颜色.size():
		return 品级颜色[品级索引]
	return "#9d9d9d"


func 获取部位名() -> String:
	return 部位名.get(部位索引, "未知")


func 获取词条显示文本() -> String:
	var 文本 := ""
	var 加成 := 获取所有属性加成()
	for 属性名 in 加成.keys():
		var 值 = 加成[属性名]
		if 值 > 0:
			文本 += "+%d %s\n" % [值, 属性名]
		elif 值 < 0:
			文本 += "%d %s\n" % [值, 属性名]
	for 词条 in 特殊词条:
		文本 += "[%s]\n" % 词条
	for 技能 in 技能列表:
		var 类型标记 := "主动" if 技能.get("type") == "主动" else "被动"
		文本 += "%s(%s)\n" % [技能.get("id", ""), 类型标记]
	return 文本.strip_edges()


static func 能否合成(a: Resource, b: Resource) -> bool:
	if a == null or b == null:
		return false
	return a.池ID == b.池ID and a.品级索引 == b.品级索引 and a.部位索引 == b.部位索引


static func 执行合成(基底: Resource, 材料: Resource) -> Resource:
	assert(基底 != null and 材料 != null)
	assert(能否合成(基底, 材料))

	var 可选项: Array[Dictionary] = []

	if not 基底.基础属性名.is_empty():
		可选项.append({
			"type": "基础属性",
			"当前值": 基底.基础属性值,
			"最小值": 基底.基础属性最小值,
			"最大值": 基底.基础属性最大值,
			"属性名": 基底.基础属性名
		})

	for i in range(基底.普通词条.size()):
		var 词条 = 基底.普通词条[i]
		可选项.append({
			"type": "普通词条",
			"index": i,
			"当前值": 词条.get("值", 0),
			"最小值": 词条.get("最小值", 0),
			"最大值": 词条.get("最大值", 0),
			"属性名": 词条.get("属性名", "")
		})

	for i in range(基底.技能列表.size()):
		var 技能 = 基底.技能列表[i]
		if 技能.get("type") == "主动":
			可选项.append({
				"type": "技能",
				"index": i,
				"属性名": 技能.get("id", ""),
				"当前cooldown": 技能.get("cooldown", 0.0)
			})

	if 可选项.is_empty():
		print("[装备] 无可强化项")
		return 基底

	var 选中: Dictionary = 可选项[randi_range(0, 可选项.size() - 1)]

	match 选中.get("type"):
		"基础属性":
			var 旧值: int = 选中["当前值"]
			var 翻倍上限: int = 选中["最大值"] * 2
			var 新值 := randi_range(旧值 + 1, mini(翻倍上限, 旧值 * 2))
			基底.基础属性值 = 新值
			print("[装备] 合成强化 基础属性[%s]: %d -> %d" % [选中["属性名"], 旧值, 新值])

		"普通词条":
			var 索引: int = 选中["index"]
			var 旧值: int = 选中["当前值"]
			var 翻倍上限: int = 选中["最大值"] * 2
			var 新值 := randi_range(旧值 + 1, mini(翻倍上限, 旧值 * 2))
			基底.普通词条[索引]["值"] = 新值
			print("[装备] 合成强化 普通词条[%s]: %d -> %d" % [选中["属性名"], 旧值, 新值])

		"技能":
			var 索引: int = 选中["index"]
			var 旧CD: float = 选中["当前cooldown"]
			var 新CD := maxf(1.0, 旧CD * 0.85)
			基底.技能列表[索引]["cooldown"] = 新CD
			print("[装备] 合成强化 技能[%s] CD: %.1f -> %.1f" % [选中["属性名"], 旧CD, 新CD])

	return 基底


func 系列化() -> Dictionary:
	var 普通词条数据: Array = []
	for 词条 in 普通词条:
		普通词条数据.append({
			"属性名": 词条.get("属性名", ""),
			"值": 词条.get("值", 0),
			"最小值": 词条.get("最小值", 0),
			"最大值": 词条.get("最大值", 0)
		})

	var 技能数据: Array = []
	for 技能 in 技能列表:
		技能数据.append({
			"id": 技能.get("id", ""),
			"type": 技能.get("type", "被动"),
			"cooldown": 技能.get("cooldown", 0.0)
		})

	return {
		"名称": 名称,
		"池ID": 池ID,
		"部位索引": 部位索引,
		"品级索引": 品级索引,
		"基础属性名": 基础属性名,
		"基础属性值": 基础属性值,
		"基础属性最小值": 基础属性最小值,
		"基础属性最大值": 基础属性最大值,
		"普通词条": 普通词条数据,
		"特殊词条": 特殊词条.duplicate(),
		"技能列表": 技能数据,
		"描述": 描述
	}


static func 反系列化(数据: Dictionary) -> Resource:
	var 新装备: Resource = _自加载().new()
	新装备.名称 = 数据.get("名称", "")
	新装备.池ID = 数据.get("池ID", "")
	新装备.部位索引 = int(数据.get("部位索引", 0))
	新装备.品级索引 = int(数据.get("品级索引", 0))
	新装备.基础属性名 = 数据.get("基础属性名", "")
	新装备.基础属性值 = int(数据.get("基础属性值", 0))
	新装备.基础属性最小值 = int(数据.get("基础属性最小值", 0))
	新装备.基础属性最大值 = int(数据.get("基础属性最大值", 0))
	新装备.描述 = 数据.get("描述", "")

	var 普通词条数据: Array = 数据.get("普通词条", [])
	for 条目 in 普通词条数据:
		新装备.普通词条.append({
			"属性名": 条目.get("属性名", ""),
			"值": 条目.get("值", 0),
			"最小值": 条目.get("最小值", 0),
			"最大值": 条目.get("最大值", 0)
		})

	var 特殊词条数据: Array = 数据.get("特殊词条", [])
	for 条目 in 特殊词条数据:
		新装备.特殊词条.append(str(条目))

	var 技能数据: Array = 数据.get("技能列表", [])
	for 条目 in 技能数据:
		新装备.技能列表.append({
			"id": 条目.get("id", ""),
			"type": 条目.get("type", "被动"),
			"cooldown": float(条目.get("cooldown", 0.0))
		})

	return 新装备
