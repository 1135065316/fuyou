extends Node
class_name 移动


@export var 角色: CharacterBody3D
@export var 基础移速 := 6.0
@export var 启动加速度 := 90.0
@export var 停止减速度 := 70.0
@export var 朝向插值速率 := 12.0

var 输入向量: Vector2 = Vector2.ZERO
var 移速倍率 := 1.0


func _ready() -> void:
  if 角色 == null:
    角色 = get_parent() as CharacterBody3D
  assert(角色 != null, "移动组件必须挂在 CharacterBody3D 下，或用 角色 字段指定宿主")
  print("[移动] 就绪 owner=", 角色.name)


func _physics_process(delta: float) -> void:
  var 输入 := 输入向量
  if 输入.length() > 1.0:
    输入 = 输入.normalized()
  var 方向 := Vector3(输入.x, 0.0, 输入.y)
  var 目标 := 方向 * 基础移速 * 移速倍率
  var 加速 := 启动加速度 if 目标.length() > 0.0 else 停止减速度
  角色.velocity = 角色.velocity.move_toward(目标, 加速 * delta)
  角色.move_and_slide()
  if 角色.velocity.length() > 0.05:
    var 目标朝向 := atan2(角色.velocity.x, 角色.velocity.z)
    角色.rotation.y = lerp_angle(角色.rotation.y, 目标朝向, 朝向插值速率 * delta)
