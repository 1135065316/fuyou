extends Control

var 装备组件引用: Node = null
const 格子数 := 6
const 图标尺寸 := 44
const 间距 := 4


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_构建界面()


func _构建界面() -> void:
	var 总宽 = 格子数 * 图标尺寸 + (格子数 - 1) * 间距

	var 背景 = Panel.new()
	背景.position = Vector2(0, 0)
	背景.size = Vector2(总宽 + 16, 图标尺寸 + 16)
	var 样式 = StyleBoxFlat.new()
	样式.bg_color = Color(0.05, 0.05, 0.06, 0.7)
	样式.corner_radius_top_left = 8
	样式.corner_radius_top_right = 8
	样式.corner_radius_bottom_left = 8
	样式.corner_radius_bottom_right = 8
	背景.add_theme_stylebox_override("panel", 样式)
	add_child(背景)

	for i in range(格子数):
		var 格子 = _创建格子(i)
		格子.position = Vector2(8 + i * (图标尺寸 + 间距), 8)
		add_child(格子)


func _创建格子(索引: int) -> Panel:
	var 格子 = Panel.new()
	格子.size = Vector2(图标尺寸, 图标尺寸)
	var 样式 = StyleBoxFlat.new()
	样式.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	样式.border_width_left = 1
	样式.border_width_right = 1
	样式.border_width_top = 1
	样式.border_width_bottom = 1
	样式.border_color = Color(0.25, 0.25, 0.3)
	格子.add_theme_stylebox_override("panel", 样式)

	var 标签 = Label.new()
	标签.name = "快捷键"
	标签.text = str(索引 + 1)
	标签.add_theme_font_size_override("font_size", 10)
	标签.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	标签.position = Vector2(2, 2)
	标签.size = Vector2(16, 14)
	格子.add_child(标签)

	var 名称标签 = Label.new()
	名称标签.name = "名称"
	名称标签.add_theme_font_size_override("font_size", 9)
	名称标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	名称标签.position = Vector2(2, 20)
	名称标签.size = Vector2(图标尺寸 - 4, 20)
	格子.add_child(名称标签)

	return 格子


func 设置装备组件(组件: Node) -> void:
	装备组件引用 = 组件
	if 装备组件引用 and 装备组件引用.has_signal("背包变更"):
		if not 装备组件引用.背包变更.is_connected(_刷新):
			装备组件引用.背包变更.connect(_刷新)
	_刷新()


func _刷新() -> void:
	if 装备组件引用 == null:
		return
	for i in range(格子数):
		var 格子 = get_child(i + 1)
		if 格子 == null:
			continue
		var 名称标签 = 格子.get_node_or_null("名称")
		if 名称标签 == null:
			continue
		名称标签.text = ""
		名称标签.add_theme_color_override("font_color", Color.WHITE)

		if i < 装备组件引用.背包.size():
			var 物品 = 装备组件引用.背包[i]
			if 物品 != null:
				名称标签.text = 物品.名称
				if 物品.has_method("获取品级颜色"):
					var 颜色字符串 = 物品.获取品级颜色()
					if not 颜色字符串.is_empty():
						名称标签.add_theme_color_override("font_color", Color(颜色字符串))


func _process(_delta: float) -> void:
	var 总宽 = 格子数 * 图标尺寸 + (格子数 - 1) * 间距 + 16
	var 视口 = get_viewport_rect().size
	position = Vector2((视口.x - 总宽) / 2.0, 视口.y - 图标尺寸 - 24)
