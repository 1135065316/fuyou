extends Label3D

@export var 偏移: Vector3 = Vector3(0, 0.85, 0)

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pixel_size = 0.015


func _process(_delta: float) -> void:
	global_position = get_parent().global_position + 偏移
