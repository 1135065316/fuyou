extends CharacterBody3D

const 装备脚本 = preload("res://通用/装备/装备.gd")

@onready var 移动组件: Node = $移动
@onready var 属性组件: Node = $属性
@onready var 装备组件节点: Node = $装备组件

var 装备面板实例: Control = null
var _面板已打开 := false


func _ready() -> void:
  print("[主角] 就绪")
  $属性.角色模板 = "主角"
  $属性.加载模板属性()
  $名称标签.text = $属性.角色模板
  移动组件.移速倍率 = 属性组件.获取身法移速倍率()
  移动组件.启用重力 = true

  _初始化随机装备()


func _physics_process(_delta: float) -> void:
  移动组件.输入向量 = Input.get_vector("左", "右", "上", "下")


func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and event.keycode == KEY_I:
    _切换装备面板()


func _切换装备面板() -> void:
  if _面板已打开:
    _关闭装备面板()
  else:
    _打开装备面板()


func _打开装备面板() -> void:
  if 装备面板实例 == null:
    装备面板实例 = 装备栏UI.new()
    # 挂到场景已有的 UI CanvasLayer 下
    var ui层 := get_tree().current_scene.get_node_or_null("UI")
    if ui层:
      ui层.add_child(装备面板实例)
    else:
      get_tree().current_scene.add_child(装备面板实例)

  if 装备面板实例 and 装备面板实例.has_method("打开面板"):
    装备面板实例.打开面板(装备组件节点)

  _面板已打开 = true
  if 装备面板实例 and 装备面板实例.has_signal("面板关闭") and not 装备面板实例.面板关闭.is_connected(_on_面板关闭):
    装备面板实例.面板关闭.connect(_on_面板关闭)


func _关闭装备面板() -> void:
  if 装备面板实例 and 装备面板实例.has_method("关闭面板"):
    装备面板实例.关闭面板()
  _面板已打开 = false


func _on_面板关闭() -> void:
  _面板已打开 = false
  if 装备面板实例:
    装备面板实例.queue_free()
    装备面板实例 = null


func _初始化随机装备() -> void:
  var 掉落生成器 := load("res://公共/掉落物生成器.gd")
  if 掉落生成器 == null:
    return

  # 生成 4 件测试装备：穿戴第1件，其余放背包
  var 测试数量 := 4
  for i in range(测试数量):
    var 装备实例: Resource = 掉落生成器.随机生成装备(1)
    if 装备实例:
      装备组件节点.拾取(装备实例)
      print("[主角] 测试装备 %d: %s(%s)" % [i + 1, 装备实例.名称, 装备实例.获取部位名()])

  # 自动穿戴第一个非空装备
  for i in range(装备组件节点.背包.size()):
    if 装备组件节点.背包[i] != null:
      var 要穿戴的装备: Resource = 装备组件节点.背包[i]
      装备组件节点.穿戴(要穿戴的装备)
      print("[主角] 自动穿戴: %s" % 要穿戴的装备.名称)
      break
