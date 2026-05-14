extends CharacterBody3D


@onready var 移动组件: Node = $移动
@onready var 属性组件: 属性 = $属性
@onready var 装备组件节点: Node = $装备组件

var _下次重选时间 := 0.0


func _ready() -> void:
  print("[普通敌人] 就绪 ", name)
  if 属性组件:
    属性组件.角色模板 = "普通敌人"
    属性组件.加载模板属性()
  var 名称标签节点 = get_node_or_null("名称标签")
  if 名称标签节点:
    名称标签节点.text = "普通敌人"
  if 移动组件 and 属性组件:
    移动组件.移速倍率 = 属性组件.获取身法移速倍率()
  移动组件.启用重力 = true
  var 血条节点 = get_node_or_null("血条")
  if 血条节点 and 血条节点.has_method("设置填充色"):
    血条节点.设置填充色(Color(0.85, 0.15, 0.15))
  elif 血条节点:
    血条节点.fill_color = Color(0.85, 0.15, 0.15)

  if 属性组件:
    属性组件.死亡信号.connect(_on_死亡)


func _physics_process(_delta: float) -> void:
  var 此刻 := Time.get_ticks_msec() / 1000.0
  if 此刻 >= _下次重选时间:
    _下次重选时间 = 此刻 + randf_range(1.0, 1.8)
    var 角度 := randf() * TAU
    移动组件.输入向量 = Vector2(cos(角度), sin(角度))
    print("[", name, "] 转向 ", roundi(rad_to_deg(角度)), "°")


func _on_死亡() -> void:
  var 掉落生成器 := load("res://公共/掉落物生成器.gd")
  if 掉落生成器:
    掉落生成器.敌人死亡掉落(self, global_position)
