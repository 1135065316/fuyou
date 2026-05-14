extends Area3D
class_name 掉落物

var 绑定的物品: Resource = null

@export var 是否临时: bool = false

@onready var 网格节点: MeshInstance3D = $网格
@onready var 名称标签: Label3D = $名称标签
@onready var 动画播放器: AnimationPlayer = $浮动动画

var _初始Y: float = 0.0


func 初始化(物品实例: Resource) -> void:
	绑定的物品 = 物品实例
	_初始Y = position.y

	if "是否临时" in 物品实例:
		是否临时 = 物品实例.是否临时

	if 名称标签:
		var 显示名称 = 物品实例.名称
		if 是否临时:
			显示名称 += "(临)"
		名称标签.text = 显示名称

	if 网格节点:
		var 颜色 := Color.WHITE
		var 颜色字符串: String = ""
		if 物品实例.has_method("获取品级颜色"):
			颜色字符串 = 物品实例.获取品级颜色()
		if not 颜色字符串.is_empty():
			颜色 = Color(颜色字符串)
		var 材质 := StandardMaterial3D.new()
		材质.albedo_color = 颜色
		材质.emission_enabled = true
		if 是否临时:
			材质.emission = Color.GRAY * 0.5
		else:
			材质.emission = 颜色 * 0.3
		材质.emission_energy_multiplier = 0.5
		网格节点.material_override = 材质

	if 动画播放器:
		动画播放器.play("浮动")


func _ready() -> void:
	body_entered.connect(_on_拾取)
	if 动画播放器 and not 动画播放器.has_animation("浮动"):
		_创建浮动动画()


func _创建浮动动画() -> void:
	if 动画播放器 == null:
		return

	var 动画库 := AnimationLibrary.new()
	var 动画 := Animation.new()
	动画.length = 1.5
	动画.loop_mode = Animation.LOOP_LINEAR

	var 索引 := 动画.add_track(Animation.TYPE_VALUE)
	动画.track_set_path(索引, ".:position:y")
	动画.track_insert_key(索引, 0.0, -0.15)
	动画.track_insert_key(索引, 0.75, 0.15)
	动画.track_insert_key(索引, 1.5, -0.15)

	动画库.add_animation("浮动", 动画)
	动画播放器.add_animation_library("掉落物", 动画库)
	动画播放器.play("浮动")


func _on_拾取(body: Node3D) -> void:
	if not body.is_in_group("玩家"):
		return

	var 组件 := body.get_node_or_null("装备组件")
	if 组件 == null:
		return

	var 已拾取 := false
	if 绑定的物品.has_method("普攻技能ID"):
		已拾取 = 组件.拾取神魂(绑定的物品)
	else:
		已拾取 = 组件.拾取(绑定的物品)

	if 已拾取:
		queue_free()
