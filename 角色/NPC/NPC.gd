extends CharacterBody3D


func _ready() -> void:
	var 属性节点 = $属性
	属性节点.角色模板 = "NPC"
	属性节点.加载模板属性()
