extends Node
class_name 走廊生成器

const 走廊地板路径 := "res://房间/地板.tscn"
const 房间间距 := 20.0

func 生成所有走廊(图: Array, 父节点: Node3D) -> void:
	var 地板场景: PackedScene = load(走廊地板路径)
	if 地板场景 == null:
		push_error("[走廊生成器] 无法加载走廊地板")
		return

	var 已处理: Dictionary = {}

	for 节点 in 图:
		for 方向 in 节点.连接门.keys():
			var 相邻节点 = 节点.连接门[方向]
			var 键: String = _连接键(节点, 相邻节点)
			if 已处理.has(键):
				continue
			已处理[键] = true

			var 起点 := Vector3(节点.位置.x * 房间间距, 0, 节点.位置.y * 房间间距)
			var 终点 := Vector3(相邻节点.位置.x * 房间间距, 0, 相邻节点.位置.y * 房间间距)
			_生成L形走廊(起点, 终点, 方向, 地板场景, 父节点)


func _生成L形走廊(起点: Vector3, 终点: Vector3, 走廊方向: String, 地板场景: PackedScene, 父节点: Node3D) -> void:
	var 当前x: float = 起点.x
	var 当前z: float = 起点.z
	var 目标x: float = 终点.x
	var 目标z: float = 终点.z

	match 走廊方向:
		"north", "south":
			while abs(当前z - 目标z) > 0.01:
				var 地板 := 地板场景.instantiate()
				地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
				地板.name = "走廊地板_%d" % 父节点.get_child_count()
				父节点.add_child(地板)
				当前z += sign(目标z - 当前z)
			while abs(当前x - 目标x) > 0.01:
				var 地板 := 地板场景.instantiate()
				地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
				地板.name = "走廊地板_%d" % 父节点.get_child_count()
				父节点.add_child(地板)
				当前x += sign(目标x - 当前x)
		_:
			while abs(当前x - 目标x) > 0.01:
				var 地板 := 地板场景.instantiate()
				地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
				地板.name = "走廊地板_%d" % 父节点.get_child_count()
				父节点.add_child(地板)
				当前x += sign(目标x - 当前x)
			while abs(当前z - 目标z) > 0.01:
				var 地板 := 地板场景.instantiate()
				地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
				地板.name = "走廊地板_%d" % 父节点.get_child_count()
				父节点.add_child(地板)
				当前z += sign(目标z - 当前z)


func _连接键(节点A, 节点B) -> String:
	var  IDA: String = 节点A.房间ID
	var  IDB: String = 节点B.房间ID
	if IDA < IDB:
		return IDA + "_" + IDB
	return IDB + "_" + IDA
