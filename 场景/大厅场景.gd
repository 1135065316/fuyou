extends Node3D

const NPC颜色: Dictionary = {
	"交易行": Color(0.2, 0.8, 0.3),
	"裁缝": Color(0.8, 0.3, 0.8),
	"仓库": Color(0.3, 0.5, 0.9),
}

var 主角实例: Node3D = null


func _ready() -> void:
	print("[大厅] 场景就绪")
	_加载玩家()
	_设置NPC交互()
	_设置返回副本()


func _加载玩家() -> void:
	var 全局状态节点 = get_node_or_null("/root/全局状态")
	if 全局状态节点 and 全局状态节点.has_method("从大厅恢复"):
		主角实例 = 全局状态节点.从大厅恢复(self)
	if 主角实例 == null:
		var 主角场景 = load("res://角色/主角/主角.tscn")
		主角实例 = 主角场景.instantiate()
		主角实例.name = "主角"
		主角实例.position = Vector3(5, 0.5, 5)
		add_child(主角实例)
		主角实例.add_to_group("玩家")


func _设置NPC交互() -> void:
	for npc in get_tree().get_nodes_in_group("NPC"):
		if npc.has_signal("body_entered"):
			npc.body_entered.connect(_on_NPC交互.bind(npc))


func _on_NPC交互(body: Node3D, npc: Node3D) -> void:
	if not body.is_in_group("玩家"):
		return
	var npc类型 = npc.get_meta("npc_type", "")
	match npc类型:
		"交易行": _打开交易行()
		"裁缝": _打开裁缝()
		"仓库": _打开仓库()


func _打开交易行() -> void:
	print("[大厅] 打开交易行")
	# 简单面板：显示背包装备，提示3%手续费
	var 面板 = _创建简单面板("交易行", "上架装备（收取3%手续费）\n功能开发中...")
	_显示面板(面板)


func _打开裁缝() -> void:
	print("[大厅] 打开裁缝")
	var 面板 = _创建简单面板("裁缝铺", "更换角色外观\n功能开发中...")
	_显示面板(面板)


func _打开仓库() -> void:
	print("[大厅] 打开仓库")
	var 面板 = _创建简单面板("仓库", "存放/取出物品\n功能开发中...")
	_显示面板(面板)


func _创建简单面板(标题: String, 内容: String) -> Control:
	var 根 = Control.new()
	根.set_anchors_preset(Control.PRESET_FULL_RECT)

	var 遮罩 = ColorRect.new()
	遮罩.color = Color(0, 0, 0, 0.5)
	遮罩.set_anchors_preset(Control.PRESET_FULL_RECT)
	根.add_child(遮罩)

	var 面板 = Panel.new()
	面板.size = Vector2(360, 240)
	面板.position = (get_viewport().get_visible_rect().size - 面板.size) / 2.0
	var 样式 = StyleBoxFlat.new()
	样式.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	样式.corner_radius_top_left = 12
	样式.corner_radius_top_right = 12
	样式.corner_radius_bottom_left = 12
	样式.corner_radius_bottom_right = 12
	面板.add_theme_stylebox_override("panel", 样式)
	根.add_child(面板)

	var 标题标签 = Label.new()
	标题标签.text = 标题
	标题标签.add_theme_font_size_override("font_size", 22)
	标题标签.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	标题标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	标题标签.position = Vector2(0, 20)
	标题标签.size = Vector2(360, 36)
	面板.add_child(标题标签)

	var 内容文本 = RichTextLabel.new()
	内容文本.bbcode_enabled = true
	内容文本.text = "[center]%s[/center]" % 内容
	内容文本.position = Vector2(20, 80)
	内容文本.size = Vector2(320, 80)
	面板.add_child(内容文本)

	var 关闭按钮 = Button.new()
	关闭按钮.text = "关闭"
	关闭按钮.position = Vector2(130, 180)
	关闭按钮.size = Vector2(100, 32)
	关闭按钮.pressed.connect(func(): 根.queue_free())
	面板.add_child(关闭按钮)

	return 根


func _显示面板(面板: Control) -> void:
	var ui层 = get_node_or_null("UI")
	if ui层:
		ui层.add_child(面板)
	else:
		add_child(面板)


func _设置返回副本() -> void:
	var 返回点 = get_node_or_null("返回副本")
	if 返回点 and 返回点.has_signal("body_entered"):
		返回点.body_entered.connect(_on_返回副本)


func _on_返回副本(body: Node3D) -> void:
	if not body.is_in_group("玩家"):
		return
	var 全局状态节点 = get_node_or_null("/root/全局状态")
	if 全局状态节点 and 全局状态节点.has_method("保存到大厅"):
		全局状态节点.保存到大厅(主角实例)
	get_tree().change_scene_to_file("res://场景/副本场景.tscn")
