extends Node
class_name 敌人生成器

const 普通敌人场景路径 = "res://角色/敌人/普通敌人.tscn"

var 已生成敌人: Array[Node3D] = []


func 生成敌人(房间根节点: Node3D) -> Array[Node3D]:
	已生成敌人.clear()

	var 生成点根 = 房间根节点.get_node_or_null("生成点")
	if not 生成点根:
		return 已生成敌人

	for 标记 in 生成点根.get_children():
		if not 标记 is Marker3D:
			continue
		if 标记.get_meta("spawn_type", "") != "enemy":
			continue

		var 模板名: String = 标记.get_meta("enemy_template", "普通敌人")
		var 场景路径 = _模板转路径(模板名)
		var 场景: PackedScene = load(场景路径)
		if not 场景:
			push_warning("[敌人生成器] 无法加载场景: " + 场景路径)
			continue

		var 敌人 = 场景.instantiate() as Node3D
		敌人.position = 标记.global_position
		敌人.add_to_group("敌人")
		房间根节点.add_child(敌人)
		已生成敌人.append(敌人)
		print("[敌人生成器] 生成 ", 模板名, " at ", 标记.global_position)

	return 已生成敌人


func 获取存活敌人数量() -> int:
	var 存活 = 0
	for 敌人 in 已生成敌人:
		if not is_instance_valid(敌人) or 敌人.get_parent() == null:
			continue
		var 属性节点 = 敌人.get_node_or_null("属性")
		if 属性节点 and 属性节点.气血 <= 0:
			continue
		存活 += 1
	return 存活


func _模板转路径(模板名: String) -> String:
	match 模板名:
		"Boss":
			return 普通敌人场景路径
		_:
			return 普通敌人场景路径
