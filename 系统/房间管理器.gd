extends Node
class_name 房间管理器

const 房间模板目录 := "res://设计/数据/房间/"
const 地板场景路径 := "res://房间/地板.tscn"
const 门场景路径 := "res://房间/门.tscn"

var 房间工具类 = load("res://公共/房间工具.gd")

var 当前房间: Node3D = null
var 当前房间数据: Dictionary = {}


func 加载房间(模板ID: String, 连通门: Dictionary = {}, 世界位置: Vector3 = Vector3.ZERO) -> void:
  if 当前房间:
    当前房间.queue_free()
    当前房间 = null

  var 房间根 := _创建房间实例(模板ID, 连通门, self, 世界位置)
  if 房间根:
    当前房间 = 房间根
    当前房间数据 = 房间根.get_meta("room_data", {})
    print("[房间管理器] 已加载房间: ", 当前房间数据.get("room_name", "未知"))


func 创建房间(模板ID: String, 连通门: Dictionary = {}, 父节点: Node = null, 世界位置: Vector3 = Vector3.ZERO, 包含光照: bool = true) -> Node3D:
  var 目标父节点: Node = 父节点 if 父节点 else self
  return _创建房间实例(模板ID, 连通门, 目标父节点, 世界位置, 包含光照)


func _创建房间实例(模板ID: String, 连通门: Dictionary, 父节点: Node, 世界位置: Vector3, 包含光照: bool = true) -> Node3D:
  var 文件路径 := 房间模板目录 + 模板ID + ".jsonc"
  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  var 数据: Dictionary = Jsonc工具.解析文件(文件路径)

  if 数据.is_empty():
    push_error("[房间管理器] 无法加载房间: " + 文件路径)
    return null

  var 旧房间 := 当前房间
  var 旧数据 := 当前房间数据

  当前房间数据 = 数据

  当前房间 = Node3D.new()
  当前房间.name = "房间_" + 模板ID
  当前房间.position = 世界位置
  父节点.add_child(当前房间)

  _实例化地板(数据)
  _实例化装饰物(数据)
  _实例化门(数据, 连通门)
  _实例化生成点(数据)
  if 包含光照:
    _设置光照(数据)

  var 结果 := 当前房间
  结果.set_meta("room_data", 数据)
  当前房间 = 旧房间
  当前房间数据 = 旧数据

  return 结果


func _实例化地板(数据: Dictionary) -> void:
  var 网格: Array = 数据.get("floor_grid", [])
  var 资产引用: Dictionary = 数据.get("asset_refs", {})
  var 地板场景: PackedScene = load(地板场景路径)

  if 地板场景 == null:
    push_error("[房间管理器] 无法加载地板场景")
    return

  var 资产键列表 := 资产引用.keys()

  for z in range(网格.size()):
    var 行: Array = 网格[z]
    for x in range(行.size()):
      var 资产索引: int = 行[x]
      if 资产索引 == 0:
        continue

      var 资产ID := ""
      if 资产索引 > 0 and 资产索引 <= 资产键列表.size():
        资产ID = 资产键列表[资产索引 - 1]

      var 地板实例 := 地板场景.instantiate()
      地板实例.position = Vector3(x + 0.5, 0, z + 0.5)
      地板实例.name = "地板_%d_%d" % [x, z]

      if 资产ID != "" and 资产引用.has(资产ID):
        var 纹理路径: String = 资产引用[资产ID]
        if 地板实例.has_method("设置纹理"):
          var 纹理 := load(纹理路径) as Texture2D
          if 纹理:
            地板实例.设置纹理(纹理)

      当前房间.add_child(地板实例)


func _实例化装饰物(数据: Dictionary) -> void:
  var 装饰列表: Array = 数据.get("decorations", [])
  var 资产引用: Dictionary = 数据.get("asset_refs", {})

  for 装饰 in 装饰列表:
    var 资产ID: String = 装饰.get("asset_id", "")
    var 位置字符串: String = 装饰.get("position", "0,0,0")
    var 旋转字符串: String = 装饰.get("rotation", "0,0,0")
    var 缩放字符串: String = 装饰.get("scale", "1,1,1")

    var 位置: Vector3 = 房间工具类.解析向量3(位置字符串)
    var 旋转: Vector3 = 房间工具类.解析向量3(旋转字符串)
    var 缩放: Vector3 = 房间工具类.解析向量3(缩放字符串)

    var 资产路径: String = 资产引用.get(资产ID, "")
    if 资产路径.is_empty():
      push_warning("[房间管理器] 未找到装饰物资产: " + 资产ID)
      continue

    var 场景: PackedScene = load(资产路径) as PackedScene
    if 场景 == null:
      push_warning("[房间管理器] 无法加载场景: " + 资产路径)
      continue

    var 实例 := 场景.instantiate()
    实例.position = 位置
    实例.rotation_degrees = 旋转
    实例.scale = 缩放
    实例.name = "装饰_" + 资产ID
    当前房间.add_child(实例)


func _实例化门(数据: Dictionary, 连通门: Dictionary = {}) -> void:
  var 门场景: PackedScene = load(门场景路径)
  if 门场景 == null:
    return

  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)

  var 门配置 := {
    "north": { "grid_x": size_x / 2.0, "grid_z": 0,           "rot": Vector3(0, 0, 0) },
    "south": { "grid_x": size_x / 2.0, "grid_z": size_z - 1,   "rot": Vector3(0, 180, 0) },
    "east":  { "grid_x": size_x - 1,   "grid_z": size_z / 2.0, "rot": Vector3(0, 90, 0) },
    "west":  { "grid_x": 0,           "grid_z": size_z / 2.0, "rot": Vector3(0, -90, 0) },
  }

  for 方向 in 门配置.keys():
    if not 连通门.has(方向):
      continue

    var 相邻节点 = 连通门[方向]
    var 配置: Dictionary = 门配置[方向]
    var 门实例 := 门场景.instantiate()
    门实例.position = Vector3(配置.grid_x + 0.5, 0.5, 配置.grid_z + 0.5)
    门实例.rotation_degrees = 配置.rot
    if 门实例 is Area3D:
      门实例.方向 = 方向
      门实例.目标房间ID = 相邻节点.模板ID
    当前房间.add_child(门实例)


func _实例化生成点(数据: Dictionary) -> void:
  var 生成点根 := Node3D.new()
  生成点根.name = "生成点"
  当前房间.add_child(生成点根)

  var 房间类型: String = 数据.get("room_type", "")
  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)

  match 房间类型:
    "monster":
      var 数量 := randi_range(2, 4)
      for i in 数量:
        _创建生成点标记(生成点根, "enemy", _随机生成位置(size_x, size_z), "普通敌人")
    "boss":
      var 中心 := Vector3(size_x / 2.0, 0.5, size_z / 2.0)
      _创建生成点标记(生成点根, "enemy", 中心, "Boss")
      if randf() < 0.5:
        _创建生成点标记(生成点根, "enemy", _随机生成位置(size_x, size_z), "普通敌人")
    "treasure":
      if randf() < 0.3:
        _创建生成点标记(生成点根, "enemy", _随机生成位置(size_x, size_z), "普通敌人")


func _随机生成位置(size_x: int, size_z: int) -> Vector3:
  var 边距 := 1
  var x := randi_range(边距, size_x - 1 - 边距)
  var z := randi_range(边距, size_z - 1 - 边距)
  return Vector3(x + 0.5, 0.5, z + 0.5)


func _创建生成点标记(父节点: Node, 类型: String, 位置: Vector3, 敌人模板: String = "") -> void:
  var 标记 := Marker3D.new()
  标记.position = 位置
  标记.name = "生成点_" + 类型 + "_" + str(父节点.get_child_count())
  标记.set_meta("spawn_type", 类型)
  标记.set_meta("enemy_template", 敌人模板)
  父节点.add_child(标记)


func _设置光照(数据: Dictionary) -> void:
  var 光照配置: Dictionary = 数据.get("lighting", {})

  var 方向光颜色: Color = 房间工具类.解析颜色(光照配置.get("directional_color", "#fff8e7"))
  var 方向光强度: float = 光照配置.get("directional_energy", 0.8)
  var 方向光旋转: Vector3 = 房间工具类.解析向量3(光照配置.get("directional_rotation", "45,30,0"))

  var 方向光 := DirectionalLight3D.new()
  方向光.light_color = 方向光颜色
  方向光.light_energy = 方向光强度
  方向光.rotation_degrees = 方向光旋转
  方向光.shadow_enabled = false
  当前房间.add_child(方向光)

  var size_x: int = 数据.get("size_x", 8)
  var size_z: int = 数据.get("size_z", 8)
  var 填充光 := OmniLight3D.new()
  填充光.light_color = Color(0.9, 0.85, 0.8)
  填充光.light_energy = 0.6
  填充光.position = Vector3(size_x / 2.0 + 0.5, 4, size_z / 2.0 + 0.5)
  填充光.omni_range = maxf(size_x, size_z) * 1.5
  填充光.omni_attenuation = 0.5
  填充光.name = "填充光"
  当前房间.add_child(填充光)
