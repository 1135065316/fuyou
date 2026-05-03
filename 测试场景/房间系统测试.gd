extends Node3D

const 房间间距 := 15.0
const 方块尺寸 := 8.0

@onready var 房间管理器节点: Node = $房间管理器
@onready var 主角实例: Node3D = $主角
@onready var 主角相机: Camera3D = $主角相机
@onready var 上帝相机: Camera3D = $上帝相机
@onready var 层选择框: OptionButton = $UI/面板/层选择
@onready var 视角按钮: Button = $UI/面板/视角按钮

var 生成器: Node
var 可视化根: Node3D
var 是上帝视角: bool = false


func _ready() -> void:
  print("[房间系统测试] 开始")

  生成器 = load("res://系统/房间生成器.gd").new()
  add_child(生成器)

  for 层 in range(1, 10):
    层选择框.add_item("第%d层" % 层, 层)
  层选择框.selected = 0

  _生成并显示(1)
  _设置视角(false)

  print("[房间系统测试] 就绪 — Tab 切换视角，WASD 控制上帝相机，滚轮缩放")


func _on_层选择_item_selected(索引: int) -> void:
  var 层 := 层选择框.get_item_id(索引)
  _生成并显示(层)


func _on_视角按钮按下() -> void:
  是上帝视角 = not 是上帝视角
  _设置视角(是上帝视角)


func _设置视角(上帝: bool) -> void:
  是上帝视角 = 上帝
  主角相机.current = not 上帝
  上帝相机.current = 上帝
  视角按钮.text = "上帝视角" if 上帝 else "主角视角"


func _生成并显示(层: int) -> void:
  if 可视化根:
    可视化根.queue_free()
  可视化根 = Node3D.new()
  可视化根.name = "第%d层可视化" % 层
  add_child(可视化根)

  var 图 = 生成器.生成楼层(层)

  for 节点 in 图:
    var 方块 = _创建房间方块(节点)
    可视化根.add_child(方块)

  for 节点 in 图:
    for 方向 in 节点.连接门.keys():
      var 相邻节点 = 节点.连接门[方向]
      if 节点.位置.x > 相邻节点.位置.x or (节点.位置.x == 相邻节点.位置.x and 节点.位置.y > 相邻节点.位置.y):
        continue
      _画连线(节点, 相邻节点)

  var 起点 = 图[0]
  if 起点.模板ID != "":
    房间管理器节点.加载房间(起点.模板ID, 起点.连接门)

  主角实例.position = Vector3(0, 0.5, 0)
  主角实例.rotation = Vector3.ZERO

  print("[房间系统测试] 第%d层已显示: %d个房间" % [层, 图.size()])


func _创建房间方块(节点) -> MeshInstance3D:
  var 网格实例 := MeshInstance3D.new()
  var 方块 := BoxMesh.new()
  方块.size = Vector3(方块尺寸, 2, 方块尺寸)
  网格实例.mesh = 方块

  var 材质 := StandardMaterial3D.new()
  match 节点.房间类型:
    "start":
      材质.albedo_color = Color(0.3, 0.9, 0.3)
    "boss":
      材质.albedo_color = Color(0.9, 0.2, 0.2)
    "treasure":
      材质.albedo_color = Color(0.95, 0.8, 0.2)
    _:
      材质.albedo_color = Color(0.5, 0.5, 0.55)
  网格实例.material_override = 材质

  网格实例.position = Vector3(节点.位置.x * 房间间距, 1, 节点.位置.y * 房间间距)
  网格实例.name = "房间_%d_%d" % [节点.位置.x, 节点.位置.y]
  return 网格实例


func _画连线(节点A, 节点B) -> void:
  var 位置A := Vector3(节点A.位置.x * 房间间距, 0.5, 节点A.位置.y * 房间间距)
  var 位置B := Vector3(节点B.位置.x * 房间间距, 0.5, 节点B.位置.y * 房间间距)
  var 距离 := 位置A.distance_to(位置B)
  if 距离 < 0.01:
    return

  var 连线 := MeshInstance3D.new()
  var 圆柱 := CylinderMesh.new()
  圆柱.top_radius = 0.3
  圆柱.bottom_radius = 0.3
  圆柱.height = 距离
  连线.mesh = 圆柱

  var 材质 := StandardMaterial3D.new()
  材质.albedo_color = Color(0.3, 0.3, 0.4)
  连线.material_override = 材质

  连线.position = (位置A + 位置B) / 2
  可视化根.add_child(连线)
  连线.look_at(位置B)
  连线.rotate_object_local(Vector3.RIGHT, PI / 2)


func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and event.keycode == KEY_TAB and not event.echo:
    _on_视角按钮按下()


func _process(delta: float) -> void:
  if not 是上帝视角:
    return

  var 速度 := 30.0
  var 方向 := Vector3.ZERO

  if Input.is_key_pressed(KEY_W):
    方向.z -= 1
  if Input.is_key_pressed(KEY_S):
    方向.z += 1
  if Input.is_key_pressed(KEY_A):
    方向.x -= 1
  if Input.is_key_pressed(KEY_D):
    方向.x += 1

  if 方向 != Vector3.ZERO:
    方向 = 方向.normalized()
    上帝相机.position += 方向 * 速度 * delta


func _unhandled_input(event: InputEvent) -> void:
  if not 是上帝视角:
    return
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
      上帝相机.position.y = maxf(上帝相机.position.y - 5, 5)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
      上帝相机.position.y += 5
