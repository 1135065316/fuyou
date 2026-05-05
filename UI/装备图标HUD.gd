extends Sprite3D
class_name 装备图标HUD

const 装备脚本 = preload("res://通用/装备/装备.gd")

const 图标尺寸: int = 14
const 图标间距: int = 4
const 图标总宽: int = 图标尺寸 * 3 + 图标间距 * 2
const 图标总高: int = 图标尺寸

var 装备组件节点: Node = null
var 字体: Font = null


func _ready() -> void:
  pixel_size = 0.012
  billboard = BaseMaterial3D.BILLBOARD_ENABLED

  var 父节点 := get_parent()
  if 父节点 and 父节点.has_node("装备组件"):
    装备组件节点 = 父节点.get_node("装备组件")
    if 装备组件节点 and 装备组件节点.has_signal("装备变更"):
      装备组件节点.装备变更.connect(_on_装备变更)

  字体 = ThemeDB.fallback_font
  _刷新显示()


func _on_装备变更(_部位: int, _新装备: Resource, _旧装备: Resource) -> void:
  _刷新显示()


func _刷新显示() -> void:
  var 图像 := Image.create(图标总宽, 图标总高, false, Image.FORMAT_RGBA8)
  图像.fill(Color(0, 0, 0, 0))

  var 装备列表: Array = []
  if 装备组件节点 and 装备组件节点.has_method("获取显示装备列表"):
    装备列表 = 装备组件节点.获取显示装备列表()
  else:
    装备列表 = [null, null, null]

  for i in range(3):
    var x := i * (图标尺寸 + 图标间距)
    var 装备实例: Resource = 装备列表[i] if i < 装备列表.size() else null
    var 颜色: Color

    if 装备实例:
      var 颜色字符串: String = 装备实例.获取品级颜色()
      if not 颜色字符串.is_empty():
        颜色 = Color(颜色字符串)
      else:
        颜色 = Color.GRAY
    else:
      颜色 = Color(0.25, 0.25, 0.25, 0.5)

    for px in range(图标尺寸):
      for py in range(图标尺寸):
        图像.set_pixel(x + px, py, 颜色)

  # 分隔线
  var 半间距: int = 图标间距 >> 1
  for i in range(1, 3):
    var 分隔x: int = i * (图标尺寸 + 图标间距) - 半间距
    for py in range(图标总高):
      图像.set_pixel(分隔x, py, Color(0.1, 0.1, 0.1, 0.8))

  # 部位标记
  var 半尺寸: int = 图标尺寸 >> 1
  for i in range(3):
    var 装备实例: Resource = 装备列表[i] if i < 装备列表.size() else null
    if 装备实例:
      var x := i * (图标尺寸 + 图标间距)
      var 亮度像素色 := Color(1, 1, 1, 0.6)
      var cx: int = x + 半尺寸
      var cy: int = 半尺寸
      var 部位: int = 装备实例.部位索引
      if 部位 == 0:
        _绘制十字(图像, cx, cy, 亮度像素色)
      elif 部位 == 2:
        _绘制菱形(图像, cx, cy, 亮度像素色)
      elif 部位 == 3:
        _绘制三角(图像, cx, cy, 亮度像素色)

  texture = ImageTexture.create_from_image(图像)


func _绘制十字(图像: Image, cx: int, cy: int, 颜色: Color) -> void:
  var r := 3
  for d in range(-r, r + 1):
    if cx + d >= 0 and cx + d < 图标总宽:
      图像.set_pixel(cx + d, cy, 颜色)
    if cy + d >= 0 and cy + d < 图标总高:
      图像.set_pixel(cx, cy + d, 颜色)


func _绘制菱形(图像: Image, cx: int, cy: int, 颜色: Color) -> void:
  for d in range(-2, 3):
    for d2 in range(-2 + abs(d), 3 - abs(d)):
      var px := cx + d
      var py := cy + d2
      if px >= 0 and px < 图标总宽 and py >= 0 and py < 图标总高:
        图像.set_pixel(px, py, 颜色)


func _绘制三角(图像: Image, cx: int, cy: int, 颜色: Color) -> void:
  for d in range(-2, 3):
    for d2 in range(-2, d + 1):
      var px := cx + d
      var py := cy + d2
      if px >= 0 and px < 图标总宽 and py >= 0 and py < 图标总高:
        图像.set_pixel(px, py, 颜色)
