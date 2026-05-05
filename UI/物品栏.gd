extends GridContainer
class_name 物品栏UI

signal 物品选中(装备实例: Resource, 背包索引: int)
signal 物品双击(装备实例: Resource, 背包索引: int)

var 装备组件引用: Node = null
var 物品按钮: Array[Button] = []


func 绑定(组件: Node) -> void:
	if 装备组件引用 and 装备组件引用.has_signal("背包变更") and 装备组件引用.背包变更.is_connected(刷新):
		装备组件引用.背包变更.disconnect(刷新)
	装备组件引用 = 组件
	if 装备组件引用 and 装备组件引用.has_signal("背包变更"):
		if not 装备组件引用.背包变更.is_connected(刷新):
			装备组件引用.背包变更.connect(刷新)
	刷新()


func 刷新() -> void:
	for 按钮 in 物品按钮:
		if is_instance_valid(按钮):
			按钮.queue_free()
	物品按钮.clear()

	if 装备组件引用 == null:
		return

	var 背包数组 = 装备组件引用.get("背包")
	if 背包数组 == null:
		return

	var 暗色边框 := Color(0.3, 0.3, 0.3)

	for i in range(背包数组.size()):
		var 装备实例: Resource = 背包数组[i]
		var 按钮 := Button.new()
		按钮.text = "%s\n[%s]" % [装备实例.名称, 装备实例.获取品级名()]
		按钮.custom_minimum_size = Vector2(98, 68)

		var 颜色字符串: String = 装备实例.获取品级颜色()
		var 边框颜色 := Color(颜色字符串) if not 颜色字符串.is_empty() else 暗色边框
		if not 颜色字符串.is_empty():
			按钮.add_theme_color_override("font_color", Color(颜色字符串))

		var 格子样式 := StyleBoxFlat.new()
		格子样式.bg_color = Color(0.16, 0.16, 0.16, 0.95)
		格子样式.border_width_left = 2
		格子样式.border_width_right = 2
		格子样式.border_width_top = 2
		格子样式.border_width_bottom = 2
		格子样式.border_color = 边框颜色
		格子样式.corner_radius_top_left = 4
		格子样式.corner_radius_top_right = 4
		格子样式.corner_radius_bottom_left = 4
		格子样式.corner_radius_bottom_right = 4
		按钮.add_theme_stylebox_override("normal", 格子样式)

		var 悬停样式 := 格子样式.duplicate()
		悬停样式.bg_color = Color(0.25, 0.25, 0.25, 0.95)
		按钮.add_theme_stylebox_override("hover", 悬停样式)

		按钮.add_theme_font_size_override("font_size", 10)

		var 索引 := i
		按钮.pressed.connect(func():
			物品选中.emit(装备实例, 索引)
		)

		按钮.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.double_click:
				物品双击.emit(装备实例, 索引)
		)

		add_child(按钮)
		物品按钮.append(按钮)
