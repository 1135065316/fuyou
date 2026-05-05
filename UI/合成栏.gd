extends Control
class_name 合成栏UI

const 装备脚本 = preload("res://通用/装备/装备.gd")

signal 合成完成(结果装备: Resource)

var 槽A: Resource = null
var 槽B: Resource = null
var 装备组件引用: Node = null

@onready var 槽A标签: Label = $VBox/槽A/标签
@onready var 槽B标签: Label = $VBox/槽B/标签
@onready var 合成按钮: Button = $VBox/合成按钮
@onready var 状态标签: Label = $VBox/状态


func _ready() -> void:
  if 合成按钮: 合成按钮.pressed.connect(_执行合成)
  _更新显示()


func 绑定(组件: Node) -> void:
  装备组件引用 = 组件


func 设置槽A(装备实例: Resource) -> void:
  槽A = 装备实例
  _更新显示()


func 设置槽B(装备实例: Resource) -> void:
  槽B = 装备实例
  _更新显示()


func _更新显示() -> void:
  if 槽A标签:
    槽A标签.text = _装备简短信息(槽A)
  if 槽B标签:
    槽B标签.text = _装备简短信息(槽B)

  var 可合成 := 装备脚本.能否合成(槽A, 槽B)
  if 合成按钮:
    合成按钮.disabled = not 可合成
  if 状态标签:
    if 可合成:
      状态标签.text = "可合成"
      状态标签.add_theme_color_override("font_color", Color.GREEN)
    else:
      if 槽A == null or 槽B == null:
        状态标签.text = "右键背包装备放入合成槽"
      else:
        状态标签.text = "两件装备无法合成（需同名同级同部位）"
      状态标签.add_theme_color_override("font_color", Color.RED)


func _执行合成() -> void:
  if not 装备脚本.能否合成(槽A, 槽B):
    return

  if 装备组件引用:
    var 槽B索引: int = 装备组件引用.背包.find(槽B)
    if 槽B索引 >= 0:
      装备组件引用.背包[槽B索引] = null

  装备脚本.执行合成(槽A, 槽B)
  合成完成.emit(槽A)
  槽B = null
  _更新显示()

  if 装备组件引用 and 装备组件引用.has_signal("背包变更"):
    装备组件引用.背包变更.emit()


func _装备简短信息(装备实例: Resource) -> String:
  if 装备实例 == null:
    return "  [空]"
  return "  %s [%s] | %s" % [装备实例.名称, 装备实例.获取品级名(), 装备实例.获取部位名()]
