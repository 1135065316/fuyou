extends Area3D
class_name 门

signal 门开启信号()
signal 玩家进入门信号(目标房间: String)

@export var 方向: String = "north"
@export var 默认开启: bool = false
@export var 目标房间ID: String = ""

var 已开启: bool = false:
	set(v):
		已开启 = v
		_更新门状态()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_更新门状态()
	if 默认开启:
		已开启 = true


func _更新门状态() -> void:
	var 碰撞体 := get_node_or_null("碰撞体")
	if 碰撞体:
		碰撞体.disabled = 已开启

	var 网格 := get_node_or_null("网格")
	if 网格 and 网格 is MeshInstance3D:
		var 材质: Material = 网格.get_active_material(0)
		if not 材质:
			材质 = StandardMaterial3D.new()
			网格.set_surface_override_material(0, 材质)
		if 已开启:
			材质.albedo_color = Color(0.3, 1.0, 0.3, 0.5)
		else:
			材质.albedo_color = Color(1.0, 0.3, 0.3, 1.0)


func 尝试开启() -> bool:
	if 已开启:
		return true

	var 房间根 := get_parent()
	var 敌人列表 := get_tree().get_nodes_in_group("敌人")
	var 当前房间敌人 := 敌人列表.filter(func(敌人):
		return 敌人.is_ancestor_of(房间根) or 敌人.get_parent() == 房间根
	)

	if 当前房间敌人.is_empty():
		已开启 = true
		门开启信号.emit()
		return true

	return false


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("玩家"):
		return
	if not 已开启:
		return

	if not 目标房间ID.is_empty():
		玩家进入门信号.emit(目标房间ID)
