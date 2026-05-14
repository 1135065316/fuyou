extends Node
class_name 游戏管理器

enum 游戏状态 { 初始化中, 探索中, 房间切换中, 战斗进行中, 胜利, 失败 }

const 房间间距 = 20.0

var 当前状态: 游戏状态 = 游戏状态.初始化中
var 当前楼层图: Array = []
var 当前房间节点 = null
var 当前层数: int = 1
var 房间ID映射: Dictionary = {}

var 房间管理器节点: Node
var 敌人生成器节点: Node
var 主角实例: Node3D
var 房间信息标签: Label
var 结束面板: Control
var 结束标题: Label

var 走廊根: Node3D
var 触发器根: Node3D
var 小地图节点: Control

const 掉落阈值 := -5.0
const 掉落伤害比例 := 0.3
const 掉落最低伤害 := 1


func _ready() -> void:
  房间管理器节点 = get_node_or_null("../房间管理器")
  敌人生成器节点 = get_node_or_null("../敌人生成器")
  房间信息标签 = get_node_or_null("../UI/房间信息") as Label
  结束面板 = get_node_or_null("../UI/结束面板") as Control
  结束标题 = get_node_or_null("../UI/结束面板/VBoxContainer/标题") as Label
  小地图节点 = get_node_or_null("../UI/小地图") as Control

  var 重新开始按钮: Button = get_node_or_null("../UI/结束面板/VBoxContainer/重新开始")
  if 重新开始按钮:
    重新开始按钮.pressed.connect(_on_重新开始)

  call_deferred("_开始新游戏", 1)


func _开始新游戏(层数: int) -> void:
  当前层数 = 层数
  房间ID映射.clear()

  var 旧主角 = get_parent().get_node_or_null("主角")
  if 旧主角:
    get_parent().remove_child(旧主角)
    旧主角.free()
  主角实例 = null

  if not 走廊根:
    走廊根 = Node3D.new()
    走廊根.name = "走廊根"
    get_parent().add_child(走廊根)
  else:
    for 子节点 in 走廊根.get_children():
      子节点.queue_free()

  if not 触发器根:
    触发器根 = Node3D.new()
    触发器根.name = "触发器根"
    get_parent().add_child(触发器根)
  else:
    for 子节点 in 触发器根.get_children():
      子节点.queue_free()

  var 生成器 = load("res://系统/房间生成器.gd").new()
  add_child(生成器)
  当前楼层图 = 生成器.生成楼层(层数)
  生成器.queue_free()

  for 节点 in 当前楼层图:
    房间ID映射[节点.房间ID] = 节点
    var 连接信息: String = ""
    for 方向 in 节点.连接门.keys():
      var 相邻节点 = 节点.连接门[方向]
      连接信息 += "%s->%s " % [方向, 相邻节点.位置]
    print("[游戏管理器] 房间 ", 节点.位置, " 类型=", 节点.房间类型, " 模板=", 节点.模板ID, " 连接: ", 连接信息)

  当前房间节点 = 当前楼层图[0]
  当前房间节点.是否已访问 = true
  当前房间节点.是否已清理 = true

  var 房间世界位置 := Vector3(当前房间节点.位置.x * 房间间距, 0, 当前房间节点.位置.y * 房间间距)
  房间管理器节点.加载房间(当前房间节点.模板ID, 当前房间节点.连接门, 房间世界位置)

  # 先检查是否有保存的状态（从大厅返回）
  var 全局状态节点 = get_node_or_null("/root/全局状态")
  if 全局状态节点 and 全局状态节点.has_method("恢复副本状态"):
    if not 全局状态节点.玩家数据.is_empty():
      主角实例 = 全局状态节点.恢复副本状态(get_parent())
      if 主角实例:
        _完成游戏启动()
        return

  # 新游戏：先选神魂，再实例化角色
  _弹出初始神魂选择()


func _弹出初始神魂选择() -> void:
  var 面板 = load("res://UI/神魂选择面板.gd").new()
  var ui层 = get_tree().current_scene.get_node_or_null("UI")
  if ui层:
    ui层.add_child(面板)
    面板.选择完成.connect(_on_初始神魂选择完成.bind(面板))
    面板.显示三选一()


func _on_初始神魂选择完成(选中神魂: Resource, 面板: Control) -> void:
  面板.queue_free()

  # 实例化主角
  var 主角场景: PackedScene = load("res://角色/主角/主角.tscn")
  主角实例 = 主角场景.instantiate()
  主角实例.name = "主角"
  get_parent().add_child(主角实例)
  主角实例.add_to_group("玩家")
  var 初始属性节点 = 主角实例.get_node("属性")
  if not 初始属性节点.死亡信号.is_connected(_on_主角死亡):
    初始属性节点.死亡信号.connect(_on_主角死亡)

  # 装备选中的神魂
  if 选中神魂:
    var 装备节点 = 主角实例.get_node_or_null("装备组件")
    if 装备节点:
      装备节点.装备神魂(选中神魂)

  _完成游戏启动()


func _完成游戏启动() -> void:
  _放置主角到房间中心()
  _初始化快捷道具栏()
  _初始化状态效果()
  _生成走廊和触发器(当前房间节点)
  _尝试开启当前房间门()
  _更新相机边界()

  _更新房间信息()
  _隐藏结束面板()
  _切换状态(游戏状态.探索中)

  if 主角实例.has_node("属性"):
    var 属性节点 = 主角实例.get_node("属性")
    if not 属性节点.死亡信号.is_connected(_on_主角死亡):
      属性节点.死亡信号.connect(_on_主角死亡)

  print("[游戏管理器] 第%d层已启动，共%d个房间" % [当前层数, 当前楼层图.size()])

  if 小地图节点 and 小地图节点.has_method("设置楼层图"):
    小地图节点.设置楼层图(当前楼层图)
  if 小地图节点 and 小地图节点.has_method("设置当前房间"):
    小地图节点.设置当前房间(当前房间节点)

  _添加大厅门(房间管理器节点.当前房间)


func _添加大厅门(房间根: Node3D) -> void:
  if 房间根 == null:
    return
  var 数据 = 房间管理器节点.当前房间数据
  if 数据 == null or 数据.is_empty():
    push_error("[游戏管理器] 当前房间数据为空，无法添加大厅门")
    return
  var size_x = 数据.get("size_x", 8)
  var size_z = 数据.get("size_z", 8)
  var 门位置 = Vector3(size_x / 2.0 + 0.5, 0.5, size_z - 0.5)
  var 触发器 = Area3D.new()
  触发器.name = "大厅门"
  触发器.position = 门位置
  var 碰撞体 = CollisionShape3D.new()
  var 形状 = BoxShape3D.new()
  形状.size = Vector3(1.5, 2, 1.5)
  碰撞体.shape = 形状
  触发器.add_child(碰撞体)
  触发器.body_entered.connect(_on_进入大厅)
  房间根.add_child(触发器)
  var 标记 = MeshInstance3D.new()
  var 网格 = BoxMesh.new()
  网格.size = Vector3(0.6, 1.0, 0.6)
  标记.mesh = 网格
  标记.position = 门位置 + Vector3(0, 0.5, 0)
  var 材质 = StandardMaterial3D.new()
  材质.albedo_color = Color(1.0, 0.84, 0.0, 0.5)
  材质.emission_enabled = true
  材质.emission = Color(1.0, 0.84, 0.0)
  标记.set_surface_override_material(0, 材质)
  房间根.add_child(标记)


func _on_进入大厅(body: Node3D) -> void:
  if not body.is_in_group("玩家"):
    return
  if 当前状态 != 游戏状态.探索中:
    return
  _清理临时物品()
  var 全局状态节点 = get_node_or_null("/root/全局状态")
  if 全局状态节点 and 全局状态节点.has_method("保存到大厅"):
    全局状态节点.保存到大厅(主角实例)
  call_deferred("_延迟进入大厅")


func _延迟进入大厅() -> void:
  get_tree().change_scene_to_file("res://场景/大厅场景.tscn")


func _初始化快捷道具栏() -> void:
  var ui层 := get_tree().current_scene.get_node_or_null("UI")
  if ui层:
    var 快捷栏 = ui层.get_node_or_null("快捷道具栏")
    if 快捷栏 and 快捷栏.has_method("设置装备组件") and 主角实例:
      var 装备节点 = 主角实例.get_node_or_null("装备组件")
      if 装备节点:
        快捷栏.设置装备组件(装备节点)


func _初始化状态效果() -> void:
  if 主角实例 == null:
    return
  var 状态效果节点 = 主角实例.get_node_or_null("状态效果")
  if 状态效果节点 == null:
    状态效果节点 = load("res://通用/角色/状态效果.gd").new()
    状态效果节点.name = "状态效果"
    主角实例.add_child(状态效果节点)

  var ui层 = get_tree().current_scene.get_node_or_null("UI")
  if ui层:
    var 快捷栏 = ui层.get_node_or_null("快捷道具栏")
    if 快捷栏 and 快捷栏.has_method("设置状态效果组件"):
      快捷栏.设置状态效果组件(状态效果节点)


func _生成走廊和触发器(节点) -> void:
  for 子节点 in 走廊根.get_children():
    子节点.queue_free()
  for 子节点 in 触发器根.get_children():
    子节点.queue_free()

  for 方向 in 节点.连接门.keys():
    var 相邻节点 = 节点.连接门[方向]
    var 起点: Vector3 = _计算门世界位置(节点, 方向)
    var 终点: Vector3 = _计算门世界位置(相邻节点, _反向方向(方向))
    print("[游戏管理器] 生成走廊: 当前房间=", 节点.位置, " 方向=", 方向, " 起点=", 起点, " 终点=", 终点)
    _生成走廊(起点, 终点, 方向)
    _放置触发器(终点, 相邻节点, 方向)


func _生成走廊(起点: Vector3, 终点: Vector3, 走廊方向: String) -> void:
  var 地板场景: PackedScene = load("res://房间/地板.tscn")
  if 地板场景 == null:
    return

  var 当前x: float = 起点.x
  var 当前z: float = 起点.z
  var 目标x: float = 终点.x
  var 目标z: float = 终点.z

  match 走廊方向:
    "north", "south":
      while abs(当前z - 目标z) > 0.01:
        var 地板 = 地板场景.instantiate()
        地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
        地板.name = "走廊地板_%d" % 走廊根.get_child_count()
        走廊根.add_child(地板)
        当前z += sign(目标z - 当前z)
      while abs(当前x - 目标x) > 0.01:
        var 地板 = 地板场景.instantiate()
        地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
        地板.name = "走廊地板_%d" % 走廊根.get_child_count()
        走廊根.add_child(地板)
        当前x += sign(目标x - 当前x)
    _:
      while abs(当前x - 目标x) > 0.01:
        var 地板 = 地板场景.instantiate()
        地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
        地板.name = "走廊地板_%d" % 走廊根.get_child_count()
        走廊根.add_child(地板)
        当前x += sign(目标x - 当前x)
      while abs(当前z - 目标z) > 0.01:
        var 地板 = 地板场景.instantiate()
        地板.position = Vector3(floor(当前x) + 0.5, 0, floor(当前z) + 0.5)
        地板.name = "走廊地板_%d" % 走廊根.get_child_count()
        走廊根.add_child(地板)
        当前z += sign(目标z - 当前z)


func _放置触发器(位置: Vector3, 目标节点, 进入方向: String) -> void:
  var 触发器 = Area3D.new()
  触发器.name = "触发器_" + 目标节点.房间ID
  触发器.position = 位置

  var 碰撞体 = CollisionShape3D.new()
  var 形状 = BoxShape3D.new()
  形状.size = Vector3(1.5, 2, 1.5)
  碰撞体.shape = 形状
  触发器.add_child(碰撞体)

  触发器.body_entered.connect(_on_触发器触发.bind(目标节点, 进入方向))
  触发器根.add_child(触发器)


func _on_触发器触发(body: Node3D, 目标节点, 进入方向: String) -> void:
  if not body.is_in_group("玩家"):
    return
  if 当前状态 == 游戏状态.房间切换中:
    return

  _切换到房间(目标节点, 进入方向)


func _切换到房间(目标节点, 进入方向: String) -> void:
  print("[游戏管理器] 切换房间: 从 ", 当前房间节点.位置 if 当前房间节点 else "null", " 到 ", 目标节点.位置, " 进入方向=", 进入方向)
  _切换状态(游戏状态.房间切换中)

  var 旧房间根: Node3D = 房间管理器节点.当前房间
  if 旧房间根:
    for 子节点 in 旧房间根.get_children():
      if 子节点.is_in_group("敌人"):
        子节点.queue_free()

  var 目标房间世界位置 := Vector3(目标节点.位置.x * 房间间距, 0, 目标节点.位置.y * 房间间距)
  房间管理器节点.加载房间(目标节点.模板ID, 目标节点.连接门, 目标房间世界位置)

  当前房间节点 = 目标节点
  当前房间节点.是否已访问 = true

  var 反方向: String = _反向方向(进入方向)
  _放置主角到门对面(反方向)
  _生成走廊和触发器(当前房间节点)

  if not 当前房间节点.是否已清理:
    var 敌人列表: Array = 敌人生成器节点.生成敌人(房间管理器节点.当前房间, 当前层数)
    for 敌人 in 敌人列表:
      if 敌人.has_node("属性"):
        var 敌人属性 = 敌人.get_node("属性")
        if not 敌人属性.死亡信号.is_connected(_on_敌人死亡):
          敌人属性.死亡信号.connect(_on_敌人死亡)
    if 敌人列表.size() > 0:
      _切换状态(游戏状态.战斗进行中)
      _关闭当前房间门()
    else:
      当前房间节点.是否已清理 = true
      _尝试开启当前房间门()
      _切换状态(游戏状态.探索中)
  else:
    _尝试开启当前房间门()
    _切换状态(游戏状态.探索中)

  _更新相机边界()
  _更新房间信息()
  print("[游戏管理器] 进入房间: ", 目标节点.房间类型, " ", 目标节点.房间ID)

  if 小地图节点 and 小地图节点.has_method("设置当前房间"):
    小地图节点.设置当前房间(当前房间节点)


func _计算门世界位置(节点, 方向: String) -> Vector3:
  var 数据: Dictionary = _读取房间数据(节点.模板ID)
  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)
  var 房间位置: Vector3 = Vector3(节点.位置.x * 房间间距, 0, 节点.位置.y * 房间间距)

  var grid_x: float = 0.0
  var grid_z: float = 0.0
  match 方向:
    "north":
      grid_x = size_x / 2.0
      grid_z = 0
    "south":
      grid_x = size_x / 2.0
      grid_z = size_z - 1
    "east":
      grid_x = size_x - 1
      grid_z = size_z / 2.0
    "west":
      grid_x = 0
      grid_z = size_z / 2.0

  return 房间位置 + Vector3(grid_x + 0.5, 0.5, grid_z + 0.5)


func _读取房间数据(模板ID: String) -> Dictionary:
  var 文件路径: String = "res://设计/数据/房间/" + 模板ID + ".jsonc"
  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  return Jsonc工具.解析文件(文件路径)


func _找到最近地板位置(掉落位置: Vector3) -> Vector3:
  var 最近距离 := INF
  var 最近位置 := Vector3.ZERO
  var 已找到 := false

  var 房间根: Node3D = 房间管理器节点.当前房间
  if 房间根:
    for 子节点 in 房间根.get_children():
      if 子节点.name.begins_with("地板_"):
        var 水平距离: float = Vector2(掉落位置.x - 子节点.global_position.x, 掉落位置.z - 子节点.global_position.z).length()
        if 水平距离 < 最近距离:
          最近距离 = 水平距离
          最近位置 = Vector3(子节点.global_position.x, 0.5, 子节点.global_position.z)
          已找到 = true

  if 走廊根:
    for 子节点 in 走廊根.get_children():
      if 子节点.name.begins_with("走廊地板_"):
        var 水平距离: float = Vector2(掉落位置.x - 子节点.global_position.x, 掉落位置.z - 子节点.global_position.z).length()
        if 水平距离 < 最近距离:
          最近距离 = 水平距离
          最近位置 = Vector3(子节点.global_position.x, 0.5, 子节点.global_position.z)
          已找到 = true

  if not 已找到:
    return _计算房间中心位置()
  return 最近位置


func _计算房间中心位置() -> Vector3:
  var 房间根: Node3D = 房间管理器节点.当前房间
  if not 房间根:
    return Vector3.ZERO
  var 数据: Dictionary = 房间管理器节点.当前房间数据
  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)
  return 房间根.global_position + Vector3(size_x / 2.0 + 0.5, 0.5, size_z / 2.0 + 0.5)


func _放置主角到房间中心() -> void:
  主角实例.position = _计算房间中心位置()
  主角实例.rotation = Vector3.ZERO
  主角实例.velocity = Vector3.ZERO


func _放置主角到门对面(进入方向: String) -> void:
  var 数据: Dictionary = 房间管理器节点.当前房间数据
  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)
  var 房间根: Node3D = 房间管理器节点.当前房间
  var 位置 := Vector3(size_x / 2.0 + 0.5, 0.5, size_z / 2.0 + 0.5)
  const 门偏移 = 1.5

  match 进入方向:
    "north":
      位置 = Vector3(size_x / 2.0 + 0.5, 0.5, 0 + 门偏移 + 0.5)
    "south":
      位置 = Vector3(size_x / 2.0 + 0.5, 0.5, size_z - 1 - 门偏移 + 0.5)
    "east":
      位置 = Vector3(size_x - 1 - 门偏移 + 0.5, 0.5, size_z / 2.0 + 0.5)
    "west":
      位置 = Vector3(0 + 门偏移 + 0.5, 0.5, size_z / 2.0 + 0.5)

  主角实例.position = 房间根.global_position + 位置
  主角实例.rotation = Vector3.ZERO
  主角实例.velocity = Vector3.ZERO


func _尝试开启当前房间门() -> void:
  var 房间根: Node3D = 房间管理器节点.当前房间
  if not 房间根:
    return
  for 子节点 in 房间根.get_children():
    if 子节点 is 门:
      子节点.call_deferred("尝试开启")


func _关闭当前房间门() -> void:
  var 房间根: Node3D = 房间管理器节点.当前房间
  if not 房间根:
    return
  for 子节点 in 房间根.get_children():
    if 子节点 is 门:
      子节点.已开启 = false


func _on_敌人死亡() -> void:
  if 敌人生成器节点.获取存活敌人数量() > 0:
    return

  当前房间节点.是否已清理 = true
  _尝试开启当前房间门()
  _切换状态(游戏状态.探索中)
  print("[游戏管理器] 房间清理完成")

  if 当前房间节点.房间类型 == "boss":
    _切换状态(游戏状态.胜利)
    _显示结束面板("斩妖成功，通关本层！")


func _on_主角死亡() -> void:
  _切换状态(游戏状态.失败)
  _显示结束面板("道友陨落")

  var 属性节点 = 主角实例.get_node_or_null("属性")
  if 属性节点:
    属性节点.降级()

  var 所有物品: Array = []
  var 装备节点 = 主角实例.get_node_or_null("装备组件")
  var 已装备部位: Array = []
  if 装备节点:
    for 部位 in 装备节点.当前装备.keys():
      var 装备实例 = 装备节点.当前装备[部位]
      if 装备实例 != null:
        所有物品.append(装备实例)
        已装备部位.append(部位)
    for 物品 in 装备节点.背包:
      if 物品 != null:
        所有物品.append(物品)
    if 装备节点.当前神魂 != null:
      所有物品.append(装备节点.当前神魂)

    装备节点.当前装备.clear()
    for i in range(装备节点.背包.size()):
      装备节点.背包[i] = null
    装备节点.当前神魂 = null
    装备节点.背包变更.emit()
    for 部位 in 已装备部位:
      装备节点.装备变更.emit(部位, null, null)
    装备节点.神魂变更.emit(null, null)

  var 起点 = 主角实例.global_position
  for 物品 in 所有物品:
    _喷发掉落物(物品, 起点, get_parent())

  await get_tree().create_timer(2.0).timeout

  if not is_instance_valid(主角实例):
    return
  if 当前状态 != 游戏状态.失败:
    return

  主角实例.visible = true
  主角实例.set_physics_process(true)
  属性节点.已死亡 = false

  当前房间节点 = 当前楼层图[0]
  var 房间世界位置 := Vector3(当前房间节点.位置.x * 房间间距, 0, 当前房间节点.位置.y * 房间间距)
  房间管理器节点.加载房间(当前房间节点.模板ID, 当前房间节点.连接门, 房间世界位置)

  _放置主角到房间中心()
  _生成走廊和触发器(当前房间节点)
  _尝试开启当前房间门()
  _更新相机边界()
  _更新房间信息()

  if 小地图节点 and 小地图节点.has_method("设置当前房间"):
    小地图节点.设置当前房间(当前房间节点)

  if 装备节点 and 装备节点.当前神魂 == null:
    _弹出神魂选择_保留主角()
  else:
    _切换状态(游戏状态.探索中)
    _隐藏结束面板()


func _喷发掉落物(物品实例: Resource, 起点: Vector3, 父节点: Node) -> Node3D:
  var 掉落生成器 = load("res://公共/掉落物生成器.gd")
  if 掉落生成器 == null:
    push_error("[游戏管理器] 无法加载掉落物生成器")
    return null
  var 掉落 = 掉落生成器.生成掉落物(物品实例, 起点, 父节点)
  if 掉落 == null: return null
  掉落.position = 起点

  var 角度 = randf() * TAU
  var 距离 = randf_range(2.0, 5.0)
  var 终点 = 起点 + Vector3(cos(角度) * 距离, 0, sin(角度) * 距离)
  var 最高点 = (起点 + 终点) / 2.0 + Vector3(0, 3.0, 0)

  var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  tween.tween_property(掉落, "position", 最高点, 0.4)
  tween.chain().tween_property(掉落, "position", 终点, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  return 掉落


func _弹出神魂选择_保留主角() -> void:
  var 面板 = load("res://UI/神魂选择面板.gd").new()
  var ui层 = get_tree().current_scene.get_node_or_null("UI")
  if ui层:
    ui层.add_child(面板)
    面板.选择完成.connect(_on_神魂选择完成_保留主角.bind(面板))
    面板.显示三选一()


func _on_神魂选择完成_保留主角(选中神魂: Resource, 面板: Control) -> void:
  面板.queue_free()
  if 选中神魂 and 主角实例:
    var 装备节点 = 主角实例.get_node_or_null("装备组件")
    if 装备节点:
      装备节点.装备神魂(选中神魂)
  _切换状态(游戏状态.探索中)
  _隐藏结束面板()


func _清理临时物品() -> void:
  if not is_instance_valid(主角实例):
    return
  var 装备节点 = 主角实例.get_node_or_null("装备组件")
  if 装备节点 == null: return

  var 待卸下部位: Array = []
  for 部位 in 装备节点.当前装备.keys():
    var 装备实例 = 装备节点.当前装备[部位]
    if 装备实例 != null and 装备实例.是否临时:
      待卸下部位.append(部位)
  for 部位 in 待卸下部位:
    装备节点.卸下(部位)

  for i in range(装备节点.背包.size()):
    var 物品 = 装备节点.背包[i]
    if 物品 != null and 物品.是否临时:
      装备节点.背包[i] = null

  if 装备节点.当前神魂 != null and 装备节点.当前神魂.是否临时:
    装备节点.卸下神魂()

  装备节点.背包变更.emit()


func _on_重新开始() -> void:
  _隐藏结束面板()
  var 全局状态节点 = get_node_or_null("/root/全局状态")
  if 全局状态节点 and 全局状态节点.has_method("清空状态"):
    全局状态节点.清空状态()
  _开始新游戏(1)


func _切换状态(新状态: 游戏状态) -> void:
  print("[游戏管理器] 状态: ", 游戏状态.keys()[当前状态], " -> ", 游戏状态.keys()[新状态])
  当前状态 = 新状态


func _更新房间信息() -> void:
  if not 房间信息标签:
    return
  var 房间名: String = ""
  if 房间管理器节点.当前房间数据.has("room_name"):
    房间名 = 房间管理器节点.当前房间数据.get("room_name", "")
  房间信息标签.text = "%s / 第%d层" % [房间名, 当前层数]


func _显示结束面板(文字: String) -> void:
  if 结束标题:
    结束标题.text = 文字
  if 结束面板:
    结束面板.visible = true


func _隐藏结束面板() -> void:
  if 结束面板:
    结束面板.visible = false


func _更新相机边界() -> void:
  var 相机 := get_node_or_null("../主角相机")
  if not 相机 or not 当前房间节点:
    return

  var 房间根: Node3D = 房间管理器节点.当前房间
  if not 房间根:
    return

  var 数据: Dictionary = 房间管理器节点.当前房间数据
  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)
  var 房间最小: Vector3 = 房间根.global_position + Vector3(0.5, 0, 0.5)
  var 房间最大: Vector3 = 房间根.global_position + Vector3(size_x - 0.5, 0, size_z - 0.5 + 5.0)

  if 相机.has_method("设置边界"):
    相机.设置边界(房间最小, 房间最大)


func _process(_delta: float) -> void:
  if 当前状态 == 游戏状态.胜利 or 当前状态 == 游戏状态.失败:
    return
  if is_instance_valid(主角实例) and 主角实例.global_position.y < 掉落阈值:
    _处理掉落()

  for 敌人 in get_tree().get_nodes_in_group("敌人"):
    if not is_instance_valid(敌人) or 敌人.get_parent() == null:
      continue
    var 属性节点 = 敌人.get_node_or_null("属性")
    if 属性节点 and 属性节点.已死亡:
      continue
    if 敌人.global_position.y < 掉落阈值:
      if 属性节点:
        if 属性节点.受伤(9999):
          print("[游戏管理器] 敌人掉落死亡: ", 敌人.name)
      else:
        敌人.queue_free()


func _处理掉落() -> void:
  if not is_instance_valid(主角实例) or not 主角实例.has_node("属性"):
    return
  var 主角属性 = 主角实例.get_node("属性")
  var 伤害值 := maxi(掉落最低伤害, int(主角属性.气血上限 * 掉落伤害比例))
  主角属性.受伤(伤害值)
  print("[游戏管理器] 主角掉落，扣除 %d 气血" % 伤害值)

  var 安全位置 := _找到最近地板位置(主角实例.global_position)
  主角实例.position = 安全位置
  主角实例.velocity.y = 0

  var tween := create_tween()
  for i in range(6):
    tween.tween_callback(func():
      if is_instance_valid(主角实例):
        主角实例.visible = false
    )
    tween.tween_interval(0.08)
    tween.tween_callback(func():
      if is_instance_valid(主角实例):
        主角实例.visible = true
    )
    tween.tween_interval(0.08)


func _反向方向(方向: String) -> String:
  match 方向:
    "north": return "south"
    "south": return "north"
    "east":  return "west"
    "west":  return "east"
  return ""
