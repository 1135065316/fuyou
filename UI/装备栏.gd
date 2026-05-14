extends Control
class_name 装备栏UI

const 图标类 = preload("res://UI/装备图标.gd")
const 神魂脚本 = preload("res://通用/装备/神魂.gd")
const 装备脚本 = preload("res://通用/装备/装备.gd")

signal 面板关闭

var 装备组件引用: Node = null
var 面板引用: Panel = null
var 属性标签: Label
var 当前选中图标: Control = null
var 选中高亮: ColorRect
var 详情面板: Panel
var 详情文本: RichTextLabel
var 背包背景: ColorRect = null
var _背包背景绘制回调: Callable

var 槽图标列表: Array[Control] = []
var 物品图标列表: Array[Control] = []
var 合成槽A图标: Control
var 合成槽B图标: Control

const 图标尺寸 := 52
const 图标间距 := 4
const 背包列数 := 4
const 背包行数 := 5
const 背包格子数 := 背包列数 * 背包行数

var _已绑定: bool = false


func _ready() -> void:
  visible = false
  _构建界面()


func _构建界面() -> void:
  var 全屏背景 := ColorRect.new()
  全屏背景.color = Color(0, 0, 0, 0.75)
  全屏背景.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(全屏背景)

  var 面板 := Panel.new()
  面板引用 = 面板
  面板.position = Vector2(100, 50)
  面板.size = Vector2(840, 580)
  var 面板样式 := StyleBoxFlat.new()
  面板样式.bg_color = Color(0.07, 0.07, 0.09, 0.95)
  面板样式.border_width_left = 2; 面板样式.border_width_right = 2; 面板样式.border_width_top = 2; 面板样式.border_width_bottom = 2
  面板样式.border_color = Color(0.3, 0.3, 0.35, 1)
  面板样式.corner_radius_top_left = 8
  面板样式.corner_radius_top_right = 8
  面板样式.corner_radius_bottom_left = 8
  面板样式.corner_radius_bottom_right = 8
  面板.add_theme_stylebox_override("panel", 面板样式)
  add_child(面板)

  var 标题栏 := ColorRect.new()
  标题栏.position = Vector2(0, 0)
  标题栏.size = Vector2(840, 38)
  标题栏.color = Color(0.13, 0.13, 0.18, 1)
  面板.add_child(标题栏)

  var 标题 := Label.new()
  标题.position = Vector2(16, 6)
  标题.text = "装 备"
  标题.add_theme_font_size_override("font_size", 20)
  标题.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
  面板.add_child(标题)

  var 关闭按钮 := Button.new()
  关闭按钮.position = Vector2(788, 4)
  关闭按钮.size = Vector2(44, 28)
  关闭按钮.text = "X"
  关闭按钮.pressed.connect(关闭面板)
  面板.add_child(关闭按钮)

  # 属性
  _构建分区标题(面板, Vector2(20, 48), "属性")
  属性标签 = Label.new()
  属性标签.position = Vector2(20, 70)
  属性标签.size = Vector2(130, 200)
  属性标签.add_theme_font_size_override("font_size", 10)
  属性标签.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
  面板.add_child(属性标签)

  # 装备槽
  var 槽起始X := 170
  _构建分区标题(面板, Vector2(槽起始X, 48), "装备槽")
  var 槽位名 := ["武器", "法冠", "道袍", "步履", "饰品"]
  for i in range(5):
    var y := 72 + i * (图标尺寸 + 图标间距)
    var 标签 := Label.new()
    标签.position = Vector2(槽起始X, y + 图标尺寸 * 0.3)
    标签.size = Vector2(44, 20)
    标签.text = 槽位名[i]
    标签.add_theme_font_size_override("font_size", 11)
    标签.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
    面板.add_child(标签)
    var 图标 := _创建图标(面板, Vector2(槽起始X + 48, y), "slot:%d" % i)
    槽图标列表.append(图标)

  # 神魂槽
  var 神魂Y := 72 + 5 * (图标尺寸 + 图标间距) + 8
  _构建分区标题(面板, Vector2(槽起始X, 神魂Y), "神魂")
  var 神魂标签 := Label.new()
  神魂标签.position = Vector2(槽起始X, 神魂Y + 图标尺寸 * 0.3)
  神魂标签.size = Vector2(44, 20)
  神魂标签.text = "神魂"
  神魂标签.add_theme_font_size_override("font_size", 11)
  神魂标签.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
  面板.add_child(神魂标签)
  var 神魂图标 := _创建图标(面板, Vector2(槽起始X + 48, 神魂Y), "soul")
  槽图标列表.append(神魂图标)

  # 合成
  var 合成Y := 72 + 6 * (图标尺寸 + 图标间距) + 16
  _构建分区标题(面板, Vector2(20, 合成Y), "合成")
  合成槽A图标 = _创建图标(面板, Vector2(48, 合成Y + 24), "combine:A")
  var 加号 := Label.new()
  加号.position = Vector2(108, 合成Y + 38)
  加号.text = "+"
  加号.add_theme_font_size_override("font_size", 18)
  加号.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
  面板.add_child(加号)
  合成槽B图标 = _创建图标(面板, Vector2(130, 合成Y + 24), "combine:B")

  var 合成按钮 := Button.new()
  合成按钮.position = Vector2(48, 合成Y + 84)
  合成按钮.size = Vector2(140, 28)
  合成按钮.text = "合 成"
  合成按钮.disabled = true
  合成按钮.pressed.connect(_执行合成)
  面板.add_child(合成按钮)

  var 合成状态 := Label.new()
  合成状态.name = "合成状态"
  合成状态.position = Vector2(48, 合成Y + 116)
  合成状态.size = Vector2(150, 16)
  合成状态.text = "拖入同名同级同部位装备"
  合成状态.add_theme_font_size_override("font_size", 9)
  合成状态.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
  合成状态.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  面板.add_child(合成状态)

  # 背包
  var 背包起始X := 槽起始X + 图标尺寸 + 24 + 40
  _构建分区标题(面板, Vector2(背包起始X, 48), "背包")

  var 整理按钮 := Button.new()
  整理按钮.position = Vector2(背包起始X + 180, 46)
  整理按钮.size = Vector2(56, 22)
  整理按钮.text = "整理"
  整理按钮.add_theme_font_size_override("font_size", 10)
  整理按钮.pressed.connect(_on_一键整理)
  面板.add_child(整理按钮)

  var 网格宽 := 背包列数 * 图标尺寸 + (背包列数 - 1) * 图标间距
  var 网格高 := 背包行数 * 图标尺寸 + (背包行数 - 1) * 图标间距

  背包背景 = ColorRect.new()
  背包背景.position = Vector2(背包起始X, 72)
  背包背景.size = Vector2(网格宽 + 8, 网格高 + 8)
  背包背景.color = Color(0.04, 0.04, 0.05, 1)
  面板.add_child(背包背景)
  _背包背景绘制回调 = func():
    for col in range(1, 背包列数):
      var x: int = col * (图标尺寸 + 图标间距) + 4
      背包背景.draw_line(Vector2(x, 0), Vector2(x, 背包背景.size.y), Color(0.1, 0.1, 0.12), 1)
    for row in range(1, 背包行数):
      var y: int = row * (图标尺寸 + 图标间距) + 4
      背包背景.draw_line(Vector2(0, y), Vector2(背包背景.size.x, y), Color(0.1, 0.1, 0.12), 1)
  背包背景.draw.connect(_背包背景绘制回调)

  var 物品容器 := Control.new()
  物品容器.name = "物品容器"
  物品容器.position = Vector2(背包起始X + 4, 76)
  物品容器.size = Vector2(网格宽, 网格高)
  物品容器.mouse_filter = Control.MOUSE_FILTER_PASS
  面板.add_child(物品容器)

  # 选中高亮
  选中高亮 = ColorRect.new()
  选中高亮.color = Color(1, 0.85, 0.3, 0.3)
  选中高亮.size = Vector2(图标尺寸, 图标尺寸)
  选中高亮.visible = false
  选中高亮.mouse_filter = Control.MOUSE_FILTER_IGNORE
  面板.add_child(选中高亮)

  # 详情面板
  详情面板 = Panel.new()
  详情面板.visible = false
  详情面板.size = Vector2(240, 180)
  var 详情样式 := StyleBoxFlat.new()
  详情样式.bg_color = Color(0.08, 0.08, 0.1, 0.95)
  详情样式.border_width_left = 1
  详情样式.border_width_right = 1
  详情样式.border_width_top = 1
  详情样式.border_width_bottom = 1
  详情样式.border_color = Color(0.35, 0.35, 0.4, 1)
  详情样式.corner_radius_top_left = 6
  详情样式.corner_radius_top_right = 6
  详情样式.corner_radius_bottom_left = 6
  详情样式.corner_radius_bottom_right = 6
  详情面板.add_theme_stylebox_override("panel", 详情样式)
  面板.add_child(详情面板)

  详情文本 = RichTextLabel.new()
  详情文本.position = Vector2(10, 10)
  详情文本.size = Vector2(220, 160)
  详情文本.bbcode_enabled = true
  详情文本.scroll_active = false
  详情文本.mouse_filter = Control.MOUSE_FILTER_IGNORE
  详情面板.add_child(详情文本)

  var 丢弃提示 := Label.new()
  丢弃提示.position = Vector2(背包起始X, 72 + 网格高 + 16)
  丢弃提示.text = "拖出面板可丢弃装备"
  丢弃提示.add_theme_font_size_override("font_size", 10)
  丢弃提示.add_theme_color_override("font_color", Color(0.4, 0.25, 0.25))
  面板.add_child(丢弃提示)


func _exit_tree() -> void:
  if _背包背景绘制回调.is_valid():
    背包背景.draw.disconnect(_背包背景绘制回调)


func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
      if 详情面板.visible:
        详情面板.visible = false


func _创建图标(父节点: Node, 位置: Vector2, 标识: String) -> Control:
  var 图标 := 图标类.new(标识, 图标尺寸)
  图标.position = 位置
  图标.点击.connect(_on_图标点击)
  图标.右键.connect(_on_图标右键)
  父节点.add_child(图标)
  return 图标


func _构建分区标题(父节点: Node, 位置: Vector2, 文字: String) -> void:
  var 标签 := Label.new()
  标签.position = 位置
  标签.text = "▎" + 文字
  标签.add_theme_font_size_override("font_size", 12)
  标签.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
  父节点.add_child(标签)


## ===== 拖放处理（由Control._drop_data 调用）=====
func _处理拖放(目标标识: String, data: Dictionary) -> void:
  var eq: Resource = data["equipment"]
  var src: String = data["source"]
  if src == 目标标识 or 装备组件引用 == null:
    return

  if 目标标识.begins_with("slot:"):
    var 目标分割 = 目标标识.split(":")
    if 目标分割.size() < 2: return
    var 部位: int = int(目标分割[1])
    if src.begins_with("bag:"):
      if 装备组件引用.当前装备.has(部位):
        装备组件引用.卸下(部位)
      装备组件引用.穿戴(eq)
    elif src.begins_with("slot:"):
      var 源分割 = src.split(":")
      if 源分割.size() < 2: return
      var 旧部位: int = int(源分割[1])
      if 旧部位 != 部位:
        装备组件引用.卸下(旧部位)
        if 装备组件引用.当前装备.has(部位):
          装备组件引用.卸下(部位)
        装备组件引用.穿戴(eq)

  elif 目标标识.begins_with("bag:"):
    var 目标分割 = 目标标识.split(":")
    if 目标分割.size() < 2: return
    var 目标索引: int = int(目标分割[1])
    if src.begins_with("slot:"):
      var 源分割 = src.split(":")
      if 源分割.size() < 2: return
      var 部位: int = int(源分割[1])
      装备组件引用.卸下到背包(部位, 目标索引)
    elif src.begins_with("bag:"):
      var 源分割 = src.split(":")
      if 源分割.size() < 2: return
      var 源索引: int = int(源分割[1])
      装备组件引用.交换背包格子(源索引, 目标索引)

  elif 目标标识 == "soul":
    if src.begins_with("bag:"):
      var 源分割 = src.split(":")
      if 源分割.size() < 2: return
      var 索引: int = int(源分割[1])
      var 物品 = 装备组件引用.背包[索引]
      if 物品 != null and 装备组件引用.是神魂(物品):
        装备组件引用.装备神魂(物品)
  elif 目标标识 == "combine:A":
    if src.begins_with("bag:"):
      _设置合成槽(eq, "A")
  elif 目标标识 == "combine:B":
    if src.begins_with("bag:"):
      _设置合成槽(eq, "B")

  _清除选中()
  _刷新全部()


## ===== 点击处理 =====
func _on_图标点击(图标: Control) -> void:
  var 标识: String = 图标.标识
  var eq: Resource = 图标.装备引用

  if 标识 == "combine:A":
    _设置合成槽(null, "A")
    return
  if 标识 == "combine:B":
    _设置合成槽(null, "B")
    return
  if 标识 == "soul":
    return

  if eq:
    _显示详情面板(图标, eq)
  else:
    详情面板.visible = false


func _显示详情面板(图标: Control, eq: Resource) -> void:
  var 颜色字符串: String = eq.获取品级颜色()
  var 颜色: String = 颜色字符串 if not 颜色字符串.is_empty() else "#9d9d9d"

  详情文本.text = "[b][color=%s]%s[/color][/b] [%s]\n部位: %s\n\n%s" % [
    颜色, eq.名称, eq.获取品级名(), eq.获取部位名(), eq.获取词条显示文本()
  ]

  if 面板引用 == null:
    return
  var 图标相对位置: Vector2 = 图标.global_position - 面板引用.global_position
  var 目标位置 := 图标相对位置 + Vector2(图标尺寸 + 8, 0)
  if 目标位置.x + 详情面板.size.x > 面板引用.size.x:
    目标位置.x = 图标相对位置.x - 详情面板.size.x - 8
  if 目标位置.y + 详情面板.size.y > 面板引用.size.y:
    目标位置.y = 面板引用.size.y - 详情面板.size.y - 8
  if 目标位置.y < 0:
    目标位置.y = 0

  详情面板.position = 目标位置
  详情面板.visible = true


func _on_图标右键(图标: Control) -> void:
  var eq: Resource = 图标.装备引用
  if eq == null or 装备组件引用 == null:
    return
  var 标识: String = 图标.标识
  if 标识.begins_with("slot:"):
    var 部位: int = int(标识.split(":")[1])
    装备组件引用.卸下(部位)
    _清除选中()
    _刷新全部()
  elif 标识 == "soul":
    return
  elif 标识.begins_with("bag:"):
    if 装备组件引用.是神魂(eq):
      装备组件引用.装备神魂(eq)
    else:
      var 部位: int = eq.部位索引
      if 装备组件引用.当前装备.has(部位):
        装备组件引用.卸下(部位)
      装备组件引用.穿戴(eq)
    _清除选中()
    _刷新全部()
  elif 标识 == "combine:A":
    _设置合成槽(null, "A")
  elif 标识 == "combine:B":
    _设置合成槽(null, "B")


func _选中图标(图标: Control, eq: Resource) -> void:
  当前选中图标 = 图标
  if 面板引用 == null:
    return
  if 选中高亮.get_parent():
    选中高亮.get_parent().remove_child(选中高亮)
  面板引用.add_child(选中高亮)
  选中高亮.global_position = 图标.global_position
  选中高亮.visible = (eq != null)


func _清除选中() -> void:
  当前选中图标 = null
  选中高亮.visible = false
  详情面板.visible = false


## ===== 刷新 =====
func _刷新全部() -> void:
  _刷新装备槽()
  _刷新背包()
  _刷新合成栏()
  _刷新属性面板()


func _刷新装备槽() -> void:
  for i in range(5):
    var eq: Resource = null
    if 装备组件引用 and 装备组件引用.has_method("获取部位装备"):
      eq = 装备组件引用.获取部位装备(i)
    槽图标列表[i].refresh显示(eq)
  # 神魂槽
  if 槽图标列表.size() > 5:
    var 当前神魂 = null
    if 装备组件引用 and 装备组件引用.has_method("获取当前神魂"):
      当前神魂 = 装备组件引用.获取当前神魂()
    槽图标列表[5].refresh显示(当前神魂)


func _刷新背包() -> void:
  if 面板引用 == null:
    return
  var 物品容器 := 面板引用.get_node_or_null("物品容器")
  if not 物品容器:
    return
  for c in 物品容器.get_children():
    c.queue_free()
  物品图标列表.clear()

  if 装备组件引用 == null:
    return

  for i in range(背包格子数):
    var col := i % 背包列数
    var row := int(i / float(背包列数))
    var 位置 := Vector2(col * (图标尺寸 + 图标间距), row * (图标尺寸 + 图标间距))
    var 图标 := _创建图标(物品容器, 位置, "bag:%d" % i)
    if i < 装备组件引用.背包.size():
      图标.refresh显示(装备组件引用.背包[i])
    else:
      图标.refresh显示(null)
    物品图标列表.append(图标)


var _合成槽A: Resource = null
var _合成槽B: Resource = null


func _设置合成槽(eq: Resource, 槽位: String) -> void:
  if 槽位 == "A":
    _合成槽A = eq
    合成槽A图标.refresh显示(eq, "槽A")
  else:
    _合成槽B = eq
    合成槽B图标.refresh显示(eq, "槽B")
  _刷新合成栏()


func _刷新合成栏() -> void:
  if 面板引用 == null:
    return
  var 合成按钮: Button = null
  for c in 面板引用.get_children():
    if c is Button and c.text == "合 成":
      合成按钮 = c
      break
  var 合成状态 := 面板引用.get_node_or_null("合成状态") as Label
  var 可合成 := false
  if _合成槽A and _合成槽B:
    if 装备组件引用 and 装备组件引用.has_method("是神魂") and 装备组件引用.是神魂(_合成槽A):
      可合成 = 神魂脚本.能否合成(_合成槽A, _合成槽B)
    else:
      可合成 = 装备脚本.能否合成(_合成槽A, _合成槽B)
  if 合成按钮:
    合成按钮.disabled = not 可合成
  if 合成状态:
    if 可合成:
      合成状态.text = "可合成"
      合成状态.add_theme_color_override("font_color", Color.GREEN)
    elif _合成槽A == null or _合成槽B == null:
      合成状态.text = "拖入同名同级同部位装备"
      合成状态.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
    else:
      合成状态.text = "无法合成"
      合成状态.add_theme_color_override("font_color", Color.RED)


func _执行合成() -> void:
  if not _合成槽A or not _合成槽B:
    return

  var 是神魂合成: bool = 装备组件引用 != null and 装备组件引用.has_method("是神魂") and 装备组件引用.是神魂(_合成槽A)
  if 是神魂合成:
    if not 神魂脚本.能否合成(_合成槽A, _合成槽B):
      return
    var 结果 = 神魂脚本.执行合成(_合成槽A, _合成槽B)
    if 结果 and 装备组件引用:
      for i in range(装备组件引用.背包.size()):
        if 装备组件引用.背包[i] == null:
          装备组件引用.背包[i] = 结果
          装备组件引用.背包变更.emit()
          break
  else:
    if not 装备脚本.能否合成(_合成槽A, _合成槽B):
      return
    装备脚本.执行合成(_合成槽A, _合成槽B)

  if 装备组件引用:
    for i in range(装备组件引用.背包.size()):
      if 装备组件引用.背包[i] == _合成槽B:
        装备组件引用.背包[i] = null
        装备组件引用.背包变更.emit()
        break
  _合成槽B = null
  _清除选中()
  _刷新全部()


func _刷新属性面板() -> void:
  if not 属性标签:
    return
  var 属性节点 := 装备组件引用.get_parent().get_node_or_null("属性") if 装备组件引用 else null
  if 属性节点 == null:
    属性标签.text = ""
    return
  var 文本 := "  %s\n  [%s]\n\n" % [
    属性节点.角色模板 if "角色模板" in 属性节点 else "---",
    属性.境界等级.keys()[属性节点.境界] if "境界" in 属性节点 and "境界等级" in 属性 else "---"
  ]
  文本 += "气血 %d/%d\n" % [属性节点.气血, 属性节点.气血上限]
  文本 += "劲力 %d\n" % 属性节点.劲力
  文本 += "身法 %d\n" % 属性节点.身法
  文本 += "气运 %d\n" % 属性节点.气运
  文本 += "神识 %d\n" % 属性节点.神识
  文本 += "修为 %d" % 属性节点.修为
  属性标签.text = 文本


func 打开面板(组件: Node) -> void:
  装备组件引用 = 组件
  if not _已绑定 and 装备组件引用 and 装备组件引用.has_signal("装备变更"):
    if not 装备组件引用.装备变更.is_connected(_on_装备变更刷新):
      装备组件引用.装备变更.connect(_on_装备变更刷新)
    if 装备组件引用.has_signal("背包变更") and not 装备组件引用.背包变更.is_connected(_on_背包变更刷新):
      装备组件引用.背包变更.connect(_on_背包变更刷新)
    _已绑定 = true
  visible = true
  _清除选中()
  _刷新全部()


func 关闭面板() -> void:
  visible = false
  面板关闭.emit()


func _on_一键整理() -> void:
  if 装备组件引用 and 装备组件引用.has_method("一键整理背包"):
    装备组件引用.一键整理背包()
    _清除选中()
    _刷新全部()


func _on_装备变更刷新(_部位: int, _新装备: Resource, _旧装备: Resource) -> void:
  if visible: _清除选中(); _刷新全部()


func _on_背包变更刷新() -> void:
  if visible: _刷新背包(); _刷新合成栏()
