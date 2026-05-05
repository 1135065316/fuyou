extends CharacterBody3D


@onready var 移动组件: Node = $移动
@onready var 属性组件: Node = $属性
@onready var 装备组件节点: Node = $装备组件

var _下次重选时间 := 0.0


func _ready() -> void:
	print("[普通敌人] 就绪 ", name)
	$属性.角色模板 = "普通敌人"
	$属性.加载模板属性()
	$名称标签.text = $属性.角色模板
	移动组件.移速倍率 = 属性组件.获取身法移速倍率()
	移动组件.启用重力 = true
	$血条.填充色 = Color(0.85, 0.15, 0.15)
	$血条._更新血条()

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
