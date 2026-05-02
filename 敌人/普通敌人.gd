extends CharacterBody3D


@onready var 移动组件: Node = $移动

var _下次重选时间 := 0.0


func _ready() -> void:
	print("[普通敌人] 就绪 ", name)


func _physics_process(_delta: float) -> void:
	var 此刻 := Time.get_ticks_msec() / 1000.0
	if 此刻 >= _下次重选时间:
		_下次重选时间 = 此刻 + randf_range(1.0, 1.8)
		var 角度 := randf() * TAU
		移动组件.输入向量 = Vector2(cos(角度), sin(角度))
		print("[", name, "] 转向 ", roundi(rad_to_deg(角度)), "°")
