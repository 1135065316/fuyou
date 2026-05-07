extends Control
class_name 神魂选择面板

signal 选择完成(选中神魂: Resource)

var 候选神魂: Array[Resource] = []
var 装备组件引用: Node = null


func _ready() -> void:
	visible = false
	_构建界面()


func _构建界面() -> void:
	var 背景 = ColorRect.new()
	背景.color = Color(0, 0, 0, 0.85)
	背景.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(背景)

	var 标题 = Label.new()
	标题.text = "选择你的神魂"
	标题.add_theme_font_size_override("font_size", 28)
	标题.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	标题.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	标题.set_anchors_preset(Control.PRESET_TOP_WIDE)
	标题.offset_top = 80
	标题.offset_bottom = 120
	add_child(标题)

	var 容器 = HBoxContainer.new()
	容器.alignment = BoxContainer.ALIGNMENT_CENTER
	容器.add_theme_constant_override("separation", 50)
	add_child(容器)


func _process(_delta: float) -> void:
	if not visible:
		return
	var 容器 = get_child(2) if get_child_count() > 2 else null
	if 容器 == null:
		return
	var 视口 = get_viewport_rect().size
	容器.position = Vector2((视口.x - 容器.size.x) / 2.0, (视口.y - 容器.size.y) / 2.0)


func 显示三选一(组件: Node = null) -> void:
	装备组件引用 = 组件
	候选神魂.clear()

	var 神魂脚本 = load("res://通用/装备/神魂.gd")
	var 池数据 = _获取神魂池()
	var 凡品池 = 池数据.filter(func(行): return int(行.get("tier", 0)) == 0 and 行.get("enemy_template", "") == "主角")

	for i in range(3):
		if 凡品池.is_empty():
			break
		var 随机索引 = randi_range(0, 凡品池.size() - 1)
		var 候选 = 神魂脚本.从模板行创建(凡品池[随机索引])
		候选神魂.append(候选)
		凡品池.remove_at(随机索引)

	_刷新卡片()
	visible = true


func _获取神魂池() -> Array[Dictionary]:
	var Jsonc工具 := load("res://公共/jsonc工具.gd")
	var 数据: Dictionary = Jsonc工具.解析文件("res://设计/数据/神魂池.jsonc")
	var 列数组: Array = 数据.get("columns", [])
	var 表格: Array = 数据.get("table", [])
	var 结果: Array[Dictionary] = []
	for 行 in 表格:
		var 行字典 := {}
		for j in range(min(列数组.size(), 行.size())):
			行字典[列数组[j].get("name", "")] = 行[j]
		结果.append(行字典)
	return 结果


func _刷新卡片() -> void:
	var 容器 = get_child(2) if get_child_count() > 2 else null
	if 容器 == null:
		return
	for c in 容器.get_children():
		c.queue_free()

	for i in range(候选神魂.size()):
		var 卡片 = _创建神魂卡片(候选神魂[i], i)
		容器.add_child(卡片)


func _创建神魂卡片(神魂实例: Resource, 索引: int) -> Control:
	var 卡片 = Panel.new()
	卡片.custom_minimum_size = Vector2(200, 320)

	var 样式 = StyleBoxFlat.new()
	样式.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	样式.border_width_left = 2
	样式.border_width_right = 2
	样式.border_width_top = 2
	样式.border_width_bottom = 2
	样式.border_color = Color(神魂实例.获取品级颜色())
	样式.corner_radius_top_left = 12
	样式.corner_radius_top_right = 12
	样式.corner_radius_bottom_left = 12
	样式.corner_radius_bottom_right = 12
	卡片.add_theme_stylebox_override("panel", 样式)

	var 名称标签 = Label.new()
	名称标签.text = 神魂实例.名称
	名称标签.add_theme_font_size_override("font_size", 20)
	名称标签.add_theme_color_override("font_color", Color(神魂实例.获取品级颜色()))
	名称标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	名称标签.position = Vector2(0, 16)
	名称标签.size = Vector2(200, 30)
	卡片.add_child(名称标签)

	var 品级标签 = Label.new()
	品级标签.text = 神魂实例.获取品级名()
	品级标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	品级标签.position = Vector2(0, 50)
	品级标签.size = Vector2(200, 20)
	卡片.add_child(品级标签)

	var 技能文本 = RichTextLabel.new()
	技能文本.bbcode_enabled = true
	技能文本.text = "[center]普攻: %s\n大招: %s\n\n%s: +%d[/center]" % [
		神魂实例.普攻技能ID, 神魂实例.大招技能ID,
		神魂实例.基础属性名, 神魂实例.基础属性值
	]
	技能文本.position = Vector2(10, 90)
	技能文本.size = Vector2(180, 140)
	卡片.add_child(技能文本)

	var 按钮 = Button.new()
	按钮.text = "选择"
	按钮.position = Vector2(50, 260)
	按钮.size = Vector2(100, 36)
	按钮.pressed.connect(_on_选择.bind(索引))
	卡片.add_child(按钮)

	return 卡片


func _on_选择(索引: int) -> void:
	if 索引 < 0 or 索引 >= 候选神魂.size():
		return
	var 选中 = 候选神魂[索引]
	if 装备组件引用:
		装备组件引用.装备神魂(选中)
	visible = false
	选择完成.emit(选中)
