extends Camera3D


@export var 偏移 := Vector3(0, 12, 12)

var 主角: Node3D
var 限制最小: Vector3 = Vector3(-INF, -INF, -INF)
var 限制最大: Vector3 = Vector3(INF, INF, INF)


func _ready() -> void:
	主角 = get_node_or_null("../主角") as Node3D
	if 主角:
		print("[相机] 已锁定目标: ", 主角.name)
		# 固定俯视角，不再随主角旋转
		var 水平距离 := Vector2(偏移.x, 偏移.z).length()
		var 俯仰角 := rad_to_deg(atan2(偏移.y, 水平距离))
		rotation_degrees = Vector3(-俯仰角, 0, 0)


func _process(_delta: float) -> void:
	if not 主角 or not is_instance_valid(主角):
		主角 = get_node_or_null("../主角") as Node3D
	if not 主角:
		return
	var 目标位置 := 主角.global_position + 偏移
	目标位置.x = clampf(目标位置.x, 限制最小.x, 限制最大.x)
	目标位置.z = clampf(目标位置.z, 限制最小.z, 限制最大.z)
	global_position = 目标位置


func 设置边界(最小: Vector3, 最大: Vector3) -> void:
	限制最小 = 最小 + 偏移
	限制最大 = 最大 + 偏移
	限制最小.y = 偏移.y
	限制最大.y = 偏移.y
	print("[相机] 边界更新: 最小=", 限制最小, " 最大=", 限制最大)
