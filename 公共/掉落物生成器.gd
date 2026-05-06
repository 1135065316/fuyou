extends RefCounted
class_name 掉落物生成器

const 装备脚本 = preload("res://通用/装备/装备.gd")
const 神魂脚本 = preload("res://通用/装备/神魂.gd")

const 掉落物场景路径 := "res://场景/掉落物.tscn"
const 装备池路径 := "res://设计/数据/装备池.jsonc"
const 神魂池路径 := "res://设计/数据/神魂池.jsonc"

static var _装备池缓存: Array[Dictionary] = []
static var _神魂池缓存: Array[Dictionary] = []


static func _获取装备池() -> Array[Dictionary]:
	if not _装备池缓存.is_empty():
		return _装备池缓存

	var Jsonc工具 := load("res://公共/jsonc工具.gd")
	var 数据: Dictionary = Jsonc工具.解析文件(装备池路径)
	var 列数组: Array = 数据.get("columns", [])
	var 表格: Array = 数据.get("table", [])

	for 行 in 表格:
		var 行字典 := {}
		for j in range(min(列数组.size(), 行.size())):
			行字典[列数组[j].get("name", "")] = 行[j]
		_装备池缓存.append(行字典)

	return _装备池缓存


static func 生成掉落物(装备实例: Resource, 世界位置: Vector3, 父节点: Node) -> Node3D:
	var 场景: PackedScene = load(掉落物场景路径)
	if 场景 == null:
		push_error("[掉落物生成器] 无法加载掉落物场景")
		return null

	var 实例 := 场景.instantiate() as Node3D
	实例.position = 世界位置 + Vector3(0, 0.5, 0)
	父节点.add_child(实例)

	if 实例.has_method("初始化"):
		实例.初始化(装备实例)

	return 实例


static func 随机生成装备(层数: int) -> Resource:
	var 池数据 := _获取装备池()
	return 装备脚本.从池随机创建(池数据, 层数)


static func 敌人生成随机装备(层数: int, 装备数量: int = 1) -> Array:
	var 结果: Array = []
	var 池数据 := _获取装备池()
	for i in range(装备数量):
		var 新装备: Resource = 装备脚本.从池随机创建(池数据, 层数)
		if 新装备:
			结果.append(新装备)
	return 结果


static func _获取神魂池() -> Array[Dictionary]:
	if not _神魂池缓存.is_empty():
		return _神魂池缓存
	var Jsonc工具 := load("res://公共/jsonc工具.gd")
	var 数据: Dictionary = Jsonc工具.解析文件(神魂池路径)
	var 列数组: Array = 数据.get("columns", [])
	var 表格: Array = 数据.get("table", [])
	for 行 in 表格:
		var 行字典 := {}
		for j in range(min(列数组.size(), 行.size())):
			行字典[列数组[j].get("name", "")] = 行[j]
		_神魂池缓存.append(行字典)
	return _神魂池缓存


static func 随机生成神魂(敌人模板: String, 根骨品级: int) -> Resource:
	var 池数据 := _获取神魂池()
	return 神魂脚本.从池随机创建(池数据, 根骨品级, 敌人模板)


static func 敌人死亡掉落(敌人节点: Node3D, 世界位置: Vector3) -> void:
	var 装备组件节点 := 敌人节点.get_node_or_null("装备组件")
	if 装备组件节点 == null:
		return

	var 场景根 := 敌人节点.get_tree().current_scene
	const 掉落概率 := 0.35

	var 已装备列表: Array = []
	var 部位列表: Array = []
	for 部位 in 装备组件节点.当前装备.keys():
		if randf() < 掉落概率:
			部位列表.append(部位)
			已装备列表.append(装备组件节点.当前装备[部位])

	for i in range(部位列表.size()):
		var 装备实例: Resource = 已装备列表[i]
		var 部位: int = 部位列表[i]
		装备组件节点.卸下(部位)
		生成掉落物(装备实例, 世界位置, 场景根)

	const 背包掉落概率 := 0.2
	var 待掉落列表: Array = []
	for 装备实例 in 装备组件节点.背包:
		if 装备实例 != null and randf() < 背包掉落概率:
			待掉落列表.append(装备实例)

	for 装备实例 in 待掉落列表:
		生成掉落物(装备实例, 世界位置, 场景根)

	# 新增：神魂掉落
	var 属性节点 = 敌人节点.get_node_or_null("属性")
	if 属性节点:
		var 基础概率 := 0.15
		var 根骨加成 := float(属性节点.根骨) * 0.05
		var 最终概率 := 基础概率 + 根骨加成
		if randf() < 最终概率:
			var 掉落神魂 = 随机生成神魂(属性节点.角色模板, int(属性节点.根骨))
			if 掉落神魂:
				生成掉落物(掉落神魂, 世界位置, 场景根)
				print("[掉落物生成器] 敌人掉落神魂: %s(%s)" % [掉落神魂.名称, 掉落神魂.获取品级名()])
