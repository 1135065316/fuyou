extends CharacterBody3D


@onready var 移动组件: Node = $移动


func _ready() -> void:
  print("[主角] 就绪")


func _physics_process(_delta: float) -> void:
  移动组件.输入向量 = Input.get_vector("左", "右", "上", "下")
