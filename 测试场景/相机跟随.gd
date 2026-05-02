extends Camera3D


@export var 偏移 := Vector3(0, 12, 12)

var 主角: Node3D


func _ready() -> void:
	主角 = get_node("../主角") as Node3D
	if 主角:
		print("[相机] 已锁定目标: ", 主角.name)


func _process(_delta: float) -> void:
	if 主角:
		global_position = 主角.global_position + 偏移
		look_at(主角.global_position)
