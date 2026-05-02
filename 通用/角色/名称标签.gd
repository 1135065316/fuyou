extends Label3D


func _process(_delta: float) -> void:
	global_position = get_parent().global_position + Vector3(-0.5, 0.85, 0)
