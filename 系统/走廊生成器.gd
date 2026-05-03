extends Node
class_name 走廊生成器

const 走廊地板路径 := "res://房间/地板.tscn"
const 房间间距 := 12.0

func 生成走廊(从节点: 房间生成器.房间图节点, 到节点: 房间生成器.房间图节点) -> Node3D:
	var 走廊根 := Node3D.new()
	走廊根.name = "走廊_%s_%s" % [从节点.房间ID, 到节点.房间ID]

	var 起点 := Vector3(从节点.位置.x * 房间间距, 0, 从节点.位置.y * 房间间距)
	var 终点 := Vector3(到节点.位置.x * 房间间距, 0, 到节点.位置.y * 房间间距)

	var 中点 := Vector3(终点.x, 0, 起点.z)
	var 路径点 := [起点, 中点, 终点]

	var 地板场景: PackedScene = load(走廊地板路径)
	if 地板场景 == null:
		push_error("[走廊生成器] 无法加载走廊地板")
		return 走廊根

	for i in range(路径点.size() - 1):
		var 段起点 := 路径点[i]
		var 段终点 := 路径点[i + 1]
		var 段方向 := (段终点 - 段起点).normalized()
		var 段长度 := 段起点.distance_to(段终点)
		var 步数 := int(段长度)

		for step in range(步数 + 1):
			var 位置 := 段起点 + 段方向 * step
			var 地板 := 地板场景.instantiate()
			地板.position = Vector3(round(位置.x) + 0.5, 0, round(位置.z) + 0.5)
			走廊根.add_child(地板)

	return 走廊根
