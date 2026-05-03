extends Node
class_name 房间生成器

class 房间图节点:
  var 房间ID: String
  var 房间类型: String = "monster"
  var 模板ID: String = ""
  var 位置: Vector2i
  var 连接门: Dictionary = {}
  var 是否已清理: bool = false
  var 是否已访问: bool = false

  func _to_string() -> String:
    return "节点(%s, %s, 门=%d)" % [房间类型, 位置, 连接门.size()]

const 房间池路径 := "res://设计/数据/房间池.jsonc"

var _房间池: Array[Dictionary] = []


func _ready() -> void:
  _加载房间池()


func _加载房间池() -> void:
  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  var 数据: Dictionary = Jsonc工具.解析文件(房间池路径)
  var 表格: Array = 数据.get("table", [])
  var 列数组: Array = 数据.get("columns", [])

  for 行 in 表格:
    var 行字典 := {}
    for j in range(min(列数组.size(), 行.size())):
      行字典[列数组[j].get("name", "")] = 行[j]
    _房间池.append(行字典)


func 生成楼层(层数: int) -> Array[房间图节点]:
  var 随机种子 := randi()
  seed(随机种子)

  var 房间数量 := randi_range(12, 20)
  if 层数 == 3 or 层数 == 6 or 层数 == 9:
    房间数量 = maxi(房间数量, 10)

  var 图 := _生成拓扑图(房间数量)
  _分配房间类型(图, 层数)
  _选择房间模板(图, 层数)
  _匹配门连接(图)

  print("[房间生成器] 第%d层生成完成: %d个房间, seed=%d" % [层数, 图.size(), 随机种子])
  return 图


func _生成拓扑图(房间数量: int) -> Array[房间图节点]:
  var 图: Array[房间图节点] = []
  var 已占位置 := {}
  var 方向偏移 := {
    "north": Vector2i(0, -1),
    "south": Vector2i(0, 1),
    "east": Vector2i(1, 0),
    "west": Vector2i(-1, 0)
  }
  var 反向 := {"north": "south", "south": "north", "east": "west", "west": "east"}

  var 起点 := 房间图节点.new()
  起点.位置 = Vector2i(0, 0)
  起点.房间类型 = "start"
  图.append(起点)
  已占位置[起点.位置] = 起点

  var 可扩展节点: Array[房间图节点] = [起点]

  while 图.size() < 房间数量 and 可扩展节点.size() > 0:
    var 索引 := randi_range(0, 可扩展节点.size() - 1)
    var 当前节点 := 可扩展节点[索引]

    var 可用方向: Array[String] = []
    for 方向 in 方向偏移.keys():
      if not 当前节点.连接门.has(方向):
        var 检查位置: Vector2i = 当前节点.位置 + 方向偏移[方向]
        if not 已占位置.has(检查位置):
          可用方向.append(方向)

    if 可用方向.is_empty():
      可扩展节点.remove_at(索引)
      continue

    var 选中方向: String = 可用方向[randi_range(0, 可用方向.size() - 1)]
    var 新位置: Vector2i = 当前节点.位置 + 方向偏移[选中方向]

    var 新节点 := 房间图节点.new()
    新节点.位置 = 新位置
    图.append(新节点)
    已占位置[新位置] = 新节点

    当前节点.连接门[选中方向] = 新节点
    新节点.连接门[反向[选中方向]] = 当前节点

    可扩展节点.append(新节点)

    if 当前节点.连接门.size() >= 4:
      可扩展节点.remove_at(索引)

  return 图


func _分配房间类型(图: Array[房间图节点], _层数: int) -> void:
  var 未分配 = 图.duplicate()

  for 节点 in 未分配:
    if 节点.房间类型 == "start":
      未分配.erase(节点)
      break

  var 起点 := 图[0]
  var 最远节点 := 起点
  var 最远距离 := 0

  for 节点 in 未分配:
    var 距离: int = 节点.位置.distance_squared_to(起点.位置)
    if 距离 > 最远距离:
      最远距离 = 距离
      最远节点 = 节点

  最远节点.房间类型 = "boss"
  未分配.erase(最远节点)

  var 宝藏数量 := maxi(1, int(未分配.size() / 10.0))
  for i in range(宝藏数量):
    if 未分配.is_empty():
      break
    var 索引 := randi_range(0, 未分配.size() - 1)
    未分配[索引].房间类型 = "treasure"
    未分配.remove_at(索引)

  for 节点 in 未分配:
    节点.房间类型 = "monster"


func _选择房间模板(图: Array[房间图节点], 层数: int) -> void:
  for 节点 in 图:
    var 候选池 = _房间池.filter(func(条目):
      return 条目.get("room_type") == 节点.房间类型 \
        and 层数 >= int(条目.get("min_floor", 1)) \
        and 层数 <= int(条目.get("max_floor", 9)) \
        and 节点.连接门.size() >= int(条目.get("min_doors", 1)) \
        and 节点.连接门.size() <= int(条目.get("max_doors", 4))
    )

    if 候选池.is_empty():
      push_warning("[房间生成器] 未找到合适的房间模板: 类型=%s, 层数=%d, 门数=%d" % [节点.房间类型, 层数, 节点.连接门.size()])
      continue

    var 总权重 := 0
    for 条目 in 候选池:
      总权重 += int(条目.get("weight", 1))

    var 随机值 := randi_range(1, 总权重)
    var 累计 := 0
    for 条目 in 候选池:
      累计 += int(条目.get("weight", 1))
      if 随机值 <= 累计:
        节点.模板ID = 条目.get("room_template_id", "")
        节点.房间ID = "%s_%s" % [节点.模板ID, str(randi() % 10000)]
        break


func _匹配门连接(图: Array[房间图节点]) -> void:
  var 方向映射 := {"north": "south", "south": "north", "east": "west", "west": "east"}
  for 节点 in 图:
    for 方向 in 节点.连接门.keys():
      var 相邻节点: 房间图节点 = 节点.连接门[方向]
      var 反方向: String = 方向映射[方向]
      if not 相邻节点.连接门.has(反方向) or 相邻节点.连接门[反方向] != 节点:
        push_warning("[房间生成器] 门连接不匹配: %s -> %s" % [节点.位置, 相邻节点.位置])
