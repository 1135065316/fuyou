extends Control

const 装备图标类 = preload("res://UI/装备图标.gd")

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


func _创建格子(索引: int) -> Control:
	var 格子 = 装备图标类.new("快捷:%d" % 索引, 图标尺寸, str(索引 + 1), false)
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
		if 格子 == null or not 格子.has_method("refresh显示"):
			continue
		if i < 装备组件引用.背包.size():
			var 物品 = 装备组件引用.背包[i]
			格子.refresh显示(物品)
		else:
			格子.refresh显示(null)


func _process(_delta: float) -> void:
	var 总宽 = 格子数 * 图标尺寸 + (格子数 - 1) * 间距 + 16
	var 视口 = get_viewport_rect().size
	position = Vector2((视口.x - 总宽) / 2.0, 视口.y - 图标尺寸 - 24)
