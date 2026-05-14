extends Control

const 装备图标类 = preload("res://UI/装备图标.gd")

var 装备组件引用: Node = null
var 状态效果组件引用: Node = null
var buff刷新计时器: float = 0.0
var buff区域: HBoxContainer = null

const 格子数 := 6
const 图标尺寸 := 44
const 间距 := 4
const buff图标尺寸 := 32
const buff间距 := 4


func _ready() -> void:
  set_anchors_preset(Control.PRESET_TOP_LEFT)
  _构建界面()


func _构建界面() -> void:
  var 总宽 = 格子数 * 图标尺寸 + (格子数 - 1) * 间距

  buff区域 = HBoxContainer.new()
  buff区域.name = "Buff区域"
  buff区域.position = Vector2(0, -buff图标尺寸 - 8)
  buff区域.size = Vector2(总宽 + 16, buff图标尺寸)
  buff区域.alignment = BoxContainer.ALIGNMENT_CENTER
  buff区域.add_theme_constant_override("separation", buff间距)
  add_child(buff区域)

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


func 设置状态效果组件(组件: Node) -> void:
  状态效果组件引用 = 组件
  _刷新buff显示()


func _刷新() -> void:
  if 装备组件引用 == null:
    return
  for i in range(格子数):
    var 格子 = get_child(i + 2)
    if 格子 == null or not 格子.has_method("refresh显示"):
      continue
    if i < 装备组件引用.背包.size():
      var 物品 = 装备组件引用.背包[i]
      格子.refresh显示(物品)
    else:
      格子.refresh显示(null)


func _刷新buff显示() -> void:
  if buff区域 == null:
    return
  for 子 in buff区域.get_children():
    子.queue_free()

  if 状态效果组件引用 == null or not 状态效果组件引用.has_method("获取所有buff"):
    return

  var buff列表 = 状态效果组件引用.获取所有buff()
  for buff in buff列表:
    var 图标 = _创建buff图标(buff)
    buff区域.add_child(图标)


func _创建buff图标(buff: Dictionary) -> Control:
  var 图标 = Control.new()
  图标.size = Vector2(buff图标尺寸, buff图标尺寸)

  var 背景 = ColorRect.new()
  背景.name = "Bg"
  背景.size = Vector2(buff图标尺寸, buff图标尺寸)
  var 颜色字符串: String = buff.get("图标颜色", "#ffffff")
  var 颜色 = Color(颜色字符串) if not 颜色字符串.is_empty() else Color.WHITE
  背景.color = 颜色
  图标.add_child(背景)

  var 文字 = Label.new()
  文字.name = "Text"
  文字.size = Vector2(buff图标尺寸, buff图标尺寸)
  文字.text = buff.get("名称", "").substr(0, 1)
  文字.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  文字.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  文字.add_theme_font_size_override("font_size", 14)
  文字.add_theme_color_override("font_color", Color.WHITE)
  图标.add_child(文字)

  var 时间标签 = Label.new()
  时间标签.name = "Time"
  时间标签.position = Vector2(buff图标尺寸 - 18, buff图标尺寸 - 12)
  时间标签.size = Vector2(18, 12)
  var 剩余时间: float = buff.get("剩余时间", -1.0)
  if 剩余时间 < 0:
    时间标签.text = "∞"
  else:
    时间标签.text = "%.0f" % 剩余时间
  时间标签.add_theme_font_size_override("font_size", 8)
  时间标签.add_theme_color_override("font_color", Color.WHITE)
  时间标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  图标.add_child(时间标签)

  return 图标


func _process(delta: float) -> void:
  var 总宽 = 格子数 * 图标尺寸 + (格子数 - 1) * 间距 + 16
  var 视口 = get_viewport_rect().size
  position = Vector2((视口.x - 总宽) / 2.0, 视口.y - 图标尺寸 - 24)

  buff刷新计时器 += delta
  if buff刷新计时器 >= 0.2:
    buff刷新计时器 = 0.0
    _刷新buff显示()
