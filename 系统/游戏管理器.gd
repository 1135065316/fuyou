extends Node
class_name 游戏管理器

enum 游戏状态 { 初始化中, 探索中, 房间切换中, 战斗进行中, 胜利, 失败 }

const 房间间距 = 15.0

var 当前状态: 游戏状态 = 游戏状态.初始化中
var 当前楼层图: Array = []
var 当前房间节点 = null
var 当前层数: int = 1
var 房间ID映射: Dictionary = {}

var 房间管理器节点: Node
var 敌人生成器节点: Node
var 主角实例: Node3D
var 房间信息标签: Label
var 结束面板: Control
var 结束标题: Label

var 走廊根: Node3D
var 触发器根: Node3D


func _ready() -> void:
	房间管理器节点 = get_node("../房间管理器")
	敌人生成器节点 = get_node("../敌人生成器")
	主角实例 = get_node("../主角")
	房间信息标签 = get_node("../UI/房间信息")
	结束面板 = get_node("../UI/结束面板")
	结束标题 = get_node("../UI/结束面板/VBoxContainer/标题")

	主角实例.add_to_group("玩家")
	主角实例.get_node("属性").死亡信号.connect(_on_主角死亡)

	var 重新开始按钮: Button = get_node_or_null("../UI/结束面板/VBoxContainer/重新开始")
	if 重新开始按钮:
		重新开始按钮.pressed.connect(_on_重新开始)

	call_deferred("_开始新游戏", 1)


func _开始新游戏(层数: int) -> void:
	当前层数 = 层数
	房间ID映射.clear()

	if not 走廊根:
		走廊根 = Node3D.new()
		走廊根.name = "走廊根"
		get_parent().add_child(走廊根)
	else:
		for 子节点 in 走廊根.get_children():
			子节点.queue_free()

	if not 触发器根:
		触发器根 = Node3D.new()
		触发器根.name = "触发器根"
		get_parent().add_child(触发器根)
	else:
		for 子节点 in 触发器根.get_children():
			子节点.queue_free()

	var 生成器 = load("res://系统/房间生成器.gd").new()
	add_child(生成器)
	当前楼层图 = 生成器.生成楼层(层数)
	生成器.queue_free()

	for 节点 in 当前楼层图:
		房间ID映射[节点.房间ID] = 节点

	当前房间节点 = 当前楼层图[0]
	当前房间节点.是否已访问 = true
	当前房间节点.是否已清理 = true

	房间管理器节点.加载房间(当前房间节点.模板ID, 当前房间节点.连接门)
	_放置主角到房间中心()
	_生成走廊和触发器(当前房间节点)
	_尝试开启当前房间门()
	_更新相机边界()

	_更新房间信息()
	_隐藏结束面板()
	_切换状态(游戏状态.探索中)
	print("[游戏管理器] 第%d层已启动，共%d个房间" % [层数, 当前楼层图.size()])


func _生成走廊和触发器(节点) -> void:
	for 子节点 in 走廊根.get_children():
		子节点.queue_free()
	for 子节点 in 触发器根.get_children():
		子节点.queue_free()

	for 方向 in 节点.连接门.keys():
		var 相邻节点 = 节点.连接门[方向]
		var 起点: Vector3 = _计算门世界位置(节点, 方向)
		var 终点: Vector3 = _计算门世界位置(相邻节点, _反向方向(方向))
		_生成走廊(起点, 终点)
		_放置触发器(终点, 相邻节点, 方向)


func _生成走廊(起点: Vector3, 终点: Vector3) -> void:
	var 地板场景: PackedScene = load("res://房间/地板.tscn")
	if 地板场景 == null:
		return

	var 方向向量: Vector3 = 终点 - 起点
	var 长度: float = 方向向量.length()
	var 单位方向: Vector3 = 方向向量.normalized()
	var 步数: int = int(长度)

	for i in range(步数 + 1):
		var 位置: Vector3 = 起点 + 单位方向 * i
		var 地板 = 地板场景.instantiate()
		地板.position = Vector3(round(位置.x) + 0.5, 0, round(位置.z) + 0.5)
		地板.name = "走廊地板_%d" % i
		走廊根.add_child(地板)


func _放置触发器(位置: Vector3, 目标节点, 进入方向: String) -> void:
	var 触发器 = Area3D.new()
	触发器.name = "触发器_" + 目标节点.房间ID
	触发器.position = 位置

	var 碰撞体 = CollisionShape3D.new()
	var 形状 = BoxShape3D.new()
	形状.size = Vector3(1.5, 2, 1.5)
	碰撞体.shape = 形状
	触发器.add_child(碰撞体)

	触发器.body_entered.connect(_on_触发器触发.bind(目标节点, 进入方向))
	触发器根.add_child(触发器)


func _on_触发器触发(body: Node3D, 目标节点, 进入方向: String) -> void:
	if not body.is_in_group("玩家"):
		return
	if 当前状态 == 游戏状态.房间切换中:
		return

	_切换到房间(目标节点, 进入方向)


func _切换到房间(目标节点, 进入方向: String) -> void:
	_切换状态(游戏状态.房间切换中)

	var 旧房间根: Node3D = 房间管理器节点.当前房间
	if 旧房间根:
		for 子节点 in 旧房间根.get_children():
			if 子节点.is_in_group("敌人"):
				子节点.queue_free()

	房间管理器节点.加载房间(目标节点.模板ID, 目标节点.连接门)

	当前房间节点 = 目标节点
	当前房间节点.是否已访问 = true

	var 反方向: String = _反向方向(进入方向)
	_放置主角到门对面(反方向)
	_生成走廊和触发器(当前房间节点)

	if not 当前房间节点.是否已清理:
		var 敌人列表: Array = 敌人生成器节点.生成敌人(房间管理器节点.当前房间)
		for 敌人 in 敌人列表:
			if 敌人.has_node("属性"):
				敌人.get_node("属性").死亡信号.connect(_on_敌人死亡)
		if 敌人列表.size() > 0:
			_切换状态(游戏状态.战斗进行中)
			_关闭当前房间门()
		else:
			当前房间节点.是否已清理 = true
			_尝试开启当前房间门()
			_切换状态(游戏状态.探索中)
	else:
		_尝试开启当前房间门()
		_切换状态(游戏状态.探索中)

	_更新相机边界()
	_更新房间信息()
	print("[游戏管理器] 进入房间: ", 目标节点.房间类型, " ", 目标节点.房间ID)


func _计算门世界位置(节点, 方向: String) -> Vector3:
	var 数据: Dictionary = _读取房间数据(节点.模板ID)
	var size_x: int = 数据.get("size_x", 8)
	var size_z: int = 数据.get("size_z", 8)
	var 房间位置: Vector3 = Vector3(节点.位置.x * 房间间距, 0, 节点.位置.y * 房间间距)

	var grid_x: float = 0.0
	var grid_z: float = 0.0
	match 方向:
		"north":
			grid_x = size_x / 2.0
			grid_z = 0
		"south":
			grid_x = size_x / 2.0
			grid_z = size_z - 1
		"east":
			grid_x = size_x - 1
			grid_z = size_z / 2.0
		"west":
			grid_x = 0
			grid_z = size_z / 2.0

	return 房间位置 + Vector3(grid_x + 0.5, 0.5, grid_z + 0.5)


func _读取房间数据(模板ID: String) -> Dictionary:
	var 文件路径: String = "res://设计/数据/房间/" + 模板ID + ".jsonc"
	var Jsonc工具 = load("res://公共/jsonc工具.gd")
	return Jsonc工具.解析文件(文件路径)


func _放置主角到房间中心() -> void:
	var 数据: Dictionary = 房间管理器节点.当前房间数据
	var size_x: int = 数据.get("size_x", 8)
	var size_z: int = 数据.get("size_z", 8)
	主角实例.position = Vector3(size_x / 2.0 + 0.5, 0.5, size_z / 2.0 + 0.5)
	主角实例.rotation = Vector3.ZERO


func _放置主角到门对面(进入方向: String) -> void:
	var 数据: Dictionary = 房间管理器节点.当前房间数据
	var size_x: int = 数据.get("size_x", 8)
	var size_z: int = 数据.get("size_z", 8)
	var 位置 := Vector3(size_x / 2.0 + 0.5, 0.5, size_z / 2.0 + 0.5)
	const 门偏移 = 1.5

	match 进入方向:
		"north":
			位置 = Vector3(size_x / 2.0 + 0.5, 0.5, 0 + 门偏移 + 0.5)
		"south":
			位置 = Vector3(size_x / 2.0 + 0.5, 0.5, size_z - 1 - 门偏移 + 0.5)
		"east":
			位置 = Vector3(size_x - 1 - 门偏移 + 0.5, 0.5, size_z / 2.0 + 0.5)
		"west":
			位置 = Vector3(0 + 门偏移 + 0.5, 0.5, size_z / 2.0 + 0.5)

	主角实例.position = 位置
	主角实例.rotation = Vector3.ZERO


func _尝试开启当前房间门() -> void:
	var 房间根: Node3D = 房间管理器节点.当前房间
	if not 房间根:
		return
	for 子节点 in 房间根.get_children():
		if 子节点 is 门:
			子节点.call_deferred("尝试开启")


func _关闭当前房间门() -> void:
	var 房间根: Node3D = 房间管理器节点.当前房间
	if not 房间根:
		return
	for 子节点 in 房间根.get_children():
		if 子节点 is 门:
			子节点.已开启 = false


func _on_敌人死亡() -> void:
	if 敌人生成器节点.获取存活敌人数量() > 0:
		return

	当前房间节点.是否已清理 = true
	_尝试开启当前房间门()
	_切换状态(游戏状态.探索中)
	print("[游戏管理器] 房间清理完成")

	if 当前房间节点.房间类型 == "boss":
		_切换状态(游戏状态.胜利)
		_显示结束面板("斩妖成功，通关本层！")


func _on_主角死亡() -> void:
	_切换状态(游戏状态.失败)
	_显示结束面板("道友陨落")


func _on_重新开始() -> void:
	_隐藏结束面板()
	_开始新游戏(1)


func _切换状态(新状态: 游戏状态) -> void:
	print("[游戏管理器] 状态: ", 游戏状态.keys()[当前状态], " -> ", 游戏状态.keys()[新状态])
	当前状态 = 新状态


func _更新房间信息() -> void:
	if not 房间信息标签:
		return
	var 房间名: String = ""
	if 房间管理器节点.当前房间数据.has("room_name"):
		房间名 = 房间管理器节点.当前房间数据.get("room_name", "")
	房间信息标签.text = "%s / 第%d层" % [房间名, 当前层数]


func _显示结束面板(文字: String) -> void:
	if 结束标题:
		结束标题.text = 文字
	if 结束面板:
		结束面板.visible = true


func _隐藏结束面板() -> void:
	if 结束面板:
		结束面板.visible = false


func _更新相机边界() -> void:
	var 相机 := get_node_or_null("../主角相机")
	if not 相机 or not 当前房间节点:
		return

	var 房间根: Node3D = 房间管理器节点.当前房间
	if not 房间根:
		return

	var 数据: Dictionary = 房间管理器节点.当前房间数据
	var size_x: int = 数据.get("size_x", 8)
	var size_z: int = 数据.get("size_z", 8)
	var 房间最小: Vector3 = 房间根.global_position + Vector3(0.5, 0, 0.5)
	var 房间最大: Vector3 = 房间根.global_position + Vector3(size_x - 0.5, 0, size_z - 0.5)

	if 相机.has_method("设置边界"):
		相机.设置边界(房间最小, 房间最大)


func _反向方向(方向: String) -> String:
	match 方向:
		"north": return "south"
		"south": return "north"
		"east":  return "west"
		"west":  return "east"
	return ""
