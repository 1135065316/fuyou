extends Node
class_name 装备组件

# preload 用于运行时调用静态方法，避免 class_name 循环依赖
const 装备脚本 = preload("res://通用/装备/装备.gd")
const 冷却脚本 = preload("res://通用/装备/技能冷却.gd")

signal 装备变更(部位: int, 新装备: Resource, 旧装备: Resource)
signal 属性变更()
signal 背包变更()
signal 神魂变更(新神魂: Resource, 旧神魂: Resource)

@export var 背包上限: int = 30

var 当前装备: Dictionary = {}
var 背包: Array = []
var 当前神魂: Resource = null

@onready var 技能冷却节点: Node = $技能冷却


func _ready() -> void:
	背包.resize(背包上限)
	for i in range(背包上限):
		背包[i] = null

	if 技能冷却节点 == null or not 技能冷却节点.has_method("重置部位"):
		if 技能冷却节点:
			技能冷却节点.queue_free()
		var 新建CD := 冷却脚本.new()
		新建CD.name = "技能冷却"
		add_child(新建CD)
		技能冷却节点 = 新建CD


func 获取属性组件() -> Node:
	var 父节点 := get_parent()
	if 父节点 and 父节点.has_node("属性"):
		return 父节点.get_node("属性")
	return null


func _应用装备属性(装备实例: Resource, 添加: bool) -> void:
	var 属性节点 := 获取属性组件()
	if 属性节点 == null:
		return

	var 加成: Dictionary = 装备实例.获取所有属性加成()
	var 系数 := 1 if 添加 else -1
	for 属性名 in 加成.keys():
		var 值: int = 加成[属性名]
		if 属性名 in 属性节点:
			属性节点.set(属性名, 属性节点.get(属性名) + 值 * 系数)
	属性变更.emit()


func 穿戴(装备实例: Resource) -> bool:
	if 装备实例 == null:
		return false

	var 部位: int = 装备实例.部位索引

	if 当前装备.has(部位):
		var 旧装备: Resource = 当前装备[部位]
		_应用装备属性(旧装备, false)
		技能冷却节点.重置部位(部位)
		var 空位: int = _找第一个空背包位()
		if 空位 >= 0:
			背包[空位] = 旧装备
		装备变更.emit(部位, null, 旧装备)

	当前装备[部位] = 装备实例
	_应用装备属性(装备实例, true)
	技能冷却节点.重置部位(部位)
	装备变更.emit(部位, 装备实例, 当前装备.get(部位))

	for i in range(背包.size()):
		if 背包[i] == 装备实例:
			背包[i] = null
			break
	背包变更.emit()

	print("[装备组件] %s 穿戴 %s(%s) 于 %s" % [get_parent().name, 装备实例.名称, 装备实例.获取品级名(), 装备实例.获取部位名()])
	return true


func 卸下(部位: int) -> Resource:
	if not 当前装备.has(部位):
		return null

	var 空位: int = _找第一个空背包位()
	if 空位 < 0:
		push_warning("[装备组件] 背包已满，无法卸下")
		return null

	var 装备实例: Resource = 当前装备[部位]
	当前装备.erase(部位)
	_应用装备属性(装备实例, false)
	技能冷却节点.重置部位(部位)
	背包[空位] = 装备实例
	装备变更.emit(部位, null, 装备实例)
	背包变更.emit()

	print("[装备组件] %s 卸下 %s" % [get_parent().name, 装备实例.名称])
	return 装备实例


func 卸下到背包(部位: int, 目标索引: int = -1) -> Resource:
	if not 当前装备.has(部位):
		return null

	var 装备实例: Resource = 当前装备[部位]
	当前装备.erase(部位)
	_应用装备属性(装备实例, false)
	技能冷却节点.重置部位(部位)

	if 目标索引 >= 0 and 目标索引 < 背包.size() and 背包[目标索引] == null:
		背包[目标索引] = 装备实例
	else:
		var 空位: int = _找第一个空背包位()
		if 空位 >= 0:
			背包[空位] = 装备实例

	装备变更.emit(部位, null, 装备实例)
	背包变更.emit()
	print("[装备组件] %s 卸下 %s" % [get_parent().name, 装备实例.名称])
	return 装备实例


func 交换背包格子(索引A: int, 索引B: int) -> void:
	if 索引A < 0 or 索引A >= 背包.size() or 索引B < 0 or 索引B >= 背包.size():
		return
	var 临时 = 背包[索引A]
	背包[索引A] = 背包[索引B]
	背包[索引B] = 临时
	背包变更.emit()


func 丢弃(部位: int, 世界位置: Vector3) -> Resource:
	var 装备实例: Resource = 卸下(部位)
	if 装备实例 == null:
		return null

	var 掉落生成器 := load("res://公共/掉落物生成器.gd")
	if 掉落生成器:
		var 场景根 := get_tree().current_scene
		掉落生成器.生成掉落物(装备实例, 世界位置, 场景根)
		print("[装备组件] %s 丢弃 %s 于 %s" % [get_parent().name, 装备实例.名称, 世界位置])
	return 装备实例


func 从背包丢弃(背包索引: int, 世界位置: Vector3) -> Resource:
	if 背包索引 < 0 or 背包索引 >= 背包.size():
		return null
	var 装备实例: Resource = 背包[背包索引]
	if 装备实例 == null:
		return null
	背包[背包索引] = null
	背包变更.emit()

	var 掉落生成器 := load("res://公共/掉落物生成器.gd")
	if 掉落生成器:
		var 场景根 := get_tree().current_scene
		掉落生成器.生成掉落物(装备实例, 世界位置, 场景根)
	return 装备实例


func 拾取(装备实例: Resource) -> bool:
	var 空位: int = _找第一个空背包位()
	if 空位 < 0:
		return false
	背包[空位] = 装备实例
	背包变更.emit()
	print("[装备组件] %s 拾取 %s" % [get_parent().name, 装备实例.名称])
	return true


func _找第一个空背包位() -> int:
	for i in range(背包.size()):
		if 背包[i] == null:
			return i
	return -1


func 获取部位装备(部位: int) -> Resource:
	return 当前装备.get(部位, null)


func 获取显示装备列表() -> Array:
	var 结果: Array = []
	# 装备.部位 枚举值: 武器=0, 道袍=2, 步履=3
	for 部位索引 in [0, 2, 3]:
		if 当前装备.has(部位索引):
			结果.append(当前装备[部位索引])
		else:
			结果.append(null)
	return 结果


func 是神魂(物品: Resource) -> bool:
	return 物品 != null and 物品.has_method("普攻技能ID")


func 装备神魂(神魂实例: Resource) -> bool:
	if 神魂实例 == null:
		return false
	var 旧神魂: Resource = 当前神魂
	if 旧神魂 != null:
		print("[装备组件] 旧神魂 %s 被销毁" % 旧神魂.名称)
		_应用神魂属性(旧神魂, false)
	当前神魂 = 神魂实例
	_应用神魂属性(神魂实例, true)
	神魂变更.emit(神魂实例, 旧神魂)
	for i in range(背包.size()):
		if 背包[i] == 神魂实例:
			背包[i] = null
			break
	背包变更.emit()
	print("[装备组件] %s 装备神魂 %s(%s)" % [get_parent().name, 神魂实例.名称, 神魂实例.获取品级名()])
	return true


func _应用神魂属性(神魂实例: Resource, 添加: bool) -> void:
	var 属性节点 := 获取属性组件()
	if 属性节点 == null or 神魂实例 == null:
		return
	var 系数 := 1 if 添加 else -1
	if not 神魂实例.基础属性名.is_empty():
		var 当前值 = 属性节点.get(神魂实例.基础属性名)
		属性节点.set(神魂实例.基础属性名, 当前值 + 神魂实例.基础属性值 * 系数)
	属性变更.emit()


func 卸下神魂() -> Resource:
	if 当前神魂 == null:
		return null
	var 旧神魂: Resource = 当前神魂
	_应用神魂属性(旧神魂, false)
	当前神魂 = null
	神魂变更.emit(null, 旧神魂)
	print("[装备组件] %s 卸下神魂 %s" % [get_parent().name, 旧神魂.名称])
	return 旧神魂


func 获取当前神魂() -> Resource:
	return 当前神魂


func 拾取神魂(神魂实例: Resource) -> bool:
	return 拾取(神魂实例)


func 一键整理背包() -> void:
	var 神魂列表: Array = []
	var 装备列表: Array = []
	var 空位数量 := 0
	for i in range(背包.size()):
		var 物品 = 背包[i]
		if 物品 == null:
			空位数量 += 1
		elif 是神魂(物品):
			神魂列表.append(物品)
		else:
			装备列表.append(物品)
	装备列表.sort_custom(func(a, b): return a.部位索引 < b.部位索引)
	for i in range(背包上限):
		if i < 神魂列表.size():
			背包[i] = 神魂列表[i]
		elif i < 神魂列表.size() + 装备列表.size():
			背包[i] = 装备列表[i - 神魂列表.size()]
		else:
			背包[i] = null
	背包变更.emit()
	print("[装备组件] 背包已整理：%d神魂 %d装备 %d空位" % [神魂列表.size(), 装备列表.size(), 空位数量])


func 序列化() -> Dictionary:
	var 装备数据: Dictionary = {}
	for 部位 in 当前装备.keys():
		var 装备实例 = 当前装备[部位]
		if 装备实例 != null and 装备实例.是否临时:
			continue
		装备数据[str(部位)] = 装备实例.系列化()

	var 背包数据: Array = []
	for 物品 in 背包:
		if 物品 != null and 物品.是否临时:
			背包数据.append(null)
		elif 物品 != null:
			if 是神魂(物品):
				背包数据.append({"_type": "soul", "data": 物品.系列化()})
			else:
				背包数据.append({"_type": "equip", "data": 物品.系列化()})
		else:
			背包数据.append(null)

	var 神魂数据 = null
	if 当前神魂 != null and not 当前神魂.是否临时:
		神魂数据 = 当前神魂.系列化()

	return {"当前装备": 装备数据, "背包": 背包数据, "当前神魂": 神魂数据}


func 反序列化(数据: Dictionary) -> void:
	当前装备.clear()
	当前神魂 = null
	背包.resize(背包上限)
	for i in range(背包上限):
		背包[i] = null

	var 装备数据: Dictionary = 数据.get("当前装备", {})
	for 部位键 in 装备数据.keys():
		var 部位: int = int(部位键)
		var 装备实例: Resource = 装备脚本.反系列化(装备数据[部位键])
		当前装备[部位] = 装备实例
		_应用装备属性(装备实例, true)

	var 背包数据: Array = 数据.get("背包", [])
	for i in range(mini(背包数据.size(), 背包上限)):
		var 条目 = 背包数据[i]
		if 条目 != null:
			var 类型 = 条目.get("_type", "equip")
			var 数据内容 = 条目.get("data", {})
			if 类型 == "soul":
				var 神魂脚本 = load("res://通用/装备/神魂.gd")
				背包[i] = 神魂脚本.反系列化(数据内容)
			else:
				背包[i] = 装备脚本.反系列化(数据内容)

	var 神魂数据 = 数据.get("当前神魂", null)
	if 神魂数据 != null:
		var 神魂脚本 = load("res://通用/装备/神魂.gd")
		当前神魂 = 神魂脚本.反系列化(神魂数据)
		_应用神魂属性(当前神魂, true)
