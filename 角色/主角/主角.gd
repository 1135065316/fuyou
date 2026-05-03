extends CharacterBody3D


@onready var 移动组件: Node = $移动
@onready var 属性组件: Node = $属性


func _ready() -> void:
  print("[主角] 就绪")
  $属性.角色模板 = "主角"
  $属性.加载模板属性()
  $名称标签.text = $属性.角色模板
  移动组件.移速倍率 = 属性组件.获取身法移速倍率()
  移动组件.启用重力 = true


func _physics_process(_delta: float) -> void:
  移动组件.输入向量 = Input.get_vector("左", "右", "上", "下")
