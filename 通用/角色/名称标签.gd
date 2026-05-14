extends Label3D

@export var 偏移: Vector3 = Vector3(0, 0.85, 0)

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _process(_delta: float) -> void:
	var 父节点 = get_parent()
	if 父节点 == null:
		return
	global_position = 父节点.global_position + 偏移
