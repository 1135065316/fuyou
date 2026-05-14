extends CharacterBody3D


func _ready() -> void:
	var 属性节点 = get_node_or_null("属性")
	if 属性节点 == null:
		push_error("[NPC] 缺少'属性'子节点: %s" % name)
		return
	属性节点.角色模板 = "NPC"
	属性节点.加载模板属性()
