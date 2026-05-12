extends Control
class_name 装备图标

signal 点击(图标: Control)

var 标识: String = ""
var 装备引用: Resource = null

var 背景: ColorRect
var 框: Panel
var 文字标签: Label

const 图标尺寸 := 52

# 拖拽检测
var _按下: bool = false
var _按下位置: Vector2
const _拖拽阈值: float = 8.0
var _启用拖拽: bool = true


func _init(图标标识: String = "", 图标大小: int = 52, 快捷键角标: String = "", 启用拖拽: bool = true) -> void:
  标识 = 图标标识
  size = Vector2(图标大小, 图标大小)
  _启用拖拽 = 启用拖拽
  mouse_filter = Control.MOUSE_FILTER_STOP
  mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

  背景 = ColorRect.new()
  背景.name = "Bg"
  背景.mouse_filter = Control.MOUSE_FILTER_PASS
  背景.position = Vector2.ZERO
  背景.size = size
  背景.color = Color(0.08, 0.08, 0.1, 1)
  add_child(背景)

  var 边框 := StyleBoxFlat.new()
  边框.border_width_left = 1
  边框.border_width_right = 1
  边框.border_width_top = 1
  边框.border_width_bottom = 1
  边框.border_color = Color(0.2, 0.2, 0.22)

  框 = Panel.new()
  框.name = "Frame"
  框.mouse_filter = Control.MOUSE_FILTER_IGNORE
  框.position = Vector2.ZERO
  框.size = size
  框.add_theme_stylebox_override("panel", 边框)
  add_child(框)

  文字标签 = Label.new()
  文字标签.name = "Lbl"
  文字标签.mouse_filter = Control.MOUSE_FILTER_IGNORE
  文字标签.position = Vector2(2, 2)
  文字标签.size = size - Vector2(4, 4)
  文字标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  文字标签.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  文字标签.add_theme_font_size_override("font_size", 8)
  文字标签.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
  文字标签.text = "(空)"
  add_child(文字标签)

  if not 快捷键角标.is_empty():
    var 快捷键标签 = Label.new()
    快捷键标签.name = "Hotkey"
    快捷键标签.mouse_filter = Control.MOUSE_FILTER_IGNORE
    快捷键标签.position = Vector2(图标大小 - 16, 2)
    快捷键标签.size = Vector2(14, 12)
    快捷键标签.text = 快捷键角标
    快捷键标签.add_theme_font_size_override("font_size", 9)
    快捷键标签.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
    快捷键标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(快捷键标签)


func refresh显示(装备实例: Resource = null, 默认文字: String = "(空)") -> void:
  装备引用 = 装备实例
  if 装备实例:
    var 显示名: String = 装备实例.名称.substr(0, 4)
    文字标签.text = "%s\n%s" % [显示名, 装备实例.获取品级名()]
    var 颜色字符串: String = 装备实例.获取品级颜色()
    var 颜色 := Color(颜色字符串) if not 颜色字符串.is_empty() else Color.GRAY
    背景.color = Color(颜色.r * 0.2, 颜色.g * 0.2, 颜色.b * 0.2, 1)
    文字标签.add_theme_color_override("font_color", 颜色)
    tooltip_text = "%s [%s]\n%s" % [装备实例.名称, 装备实例.获取品级名(), 装备实例.获取部位名()]
  else:
    文字标签.text = 默认文字
    背景.color = Color(0.08, 0.08, 0.1, 1)
    文字标签.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
    tooltip_text = ""


func _gui_input(event: InputEvent) -> void:
  if 装备引用 == null:
    return

  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed:
        _按下 = true
        _按下位置 = get_global_mouse_position()
      else:
        if _按下:
          点击.emit(self)
        _按下 = false

  elif _启用拖拽 and event is InputEventMouseMotion and _按下:
    if get_global_mouse_position().distance_to(_按下位置) > _拖拽阈值:
      _按下 = false
      _启动拖拽()


func _启动拖拽() -> void:
  var 数据 := {"equipment": 装备引用, "source": 标识, "icon": self}
  var 预览 := _创建拖拽预览()
  force_drag(数据, 预览)


func _创建拖拽预览() -> Control:
  var 预览 := Control.new()
  预览.mouse_filter = Control.MOUSE_FILTER_IGNORE
  预览.size = size

  var bg := ColorRect.new()
  bg.position = Vector2.ZERO
  bg.size = size
  var cs: String = 装备引用.获取品级颜色()
  var col := Color(cs) if not cs.is_empty() else Color.GRAY
  bg.color = Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 0.9)
  预览.add_child(bg)

  var lbl := Label.new()
  lbl.position = Vector2(2, 2)
  lbl.size = size - Vector2(4, 4)
  lbl.text = 装备引用.名称.substr(0, 4)
  lbl.add_theme_font_size_override("font_size", 8)
  lbl.add_theme_color_override("font_color", col)
  lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  预览.add_child(lbl)

  return 预览


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
  return data is Dictionary and data.has("equipment") and data["icon"] != self


func _drop_data(_at_position: Vector2, data: Variant) -> void:
  var 栏 := _找装备栏()
  if 栏 and 栏.has_method("_处理拖放"):
    栏._处理拖放(标识, data)


func _找装备栏() -> Node:
  var p := get_parent()
  while p:
    if p.has_method("_处理拖放"):
      return p
    p = p.get_parent()
  return null
