extends Node
class_name 技能管理器

var 装备组件节点: Node = null
var 神魂组件节点: Node = null
var 技能池数据: Dictionary = {}

var 当前普攻技能: Dictionary = {}
var 当前大招技能: Dictionary = {}
var 当前被动列表: Array[Dictionary] = []


func _ready() -> void:
  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  技能池数据 = Jsonc工具.解析文件("res://设计/数据/技能池.jsonc")

  var 父节点 := get_parent()
  装备组件节点 = 父节点.get_node_or_null("装备组件")
  神魂组件节点 = 父节点.get_node_or_null("神魂组件")

  if 装备组件节点 and 装备组件节点.has_signal("装备变更"):
    if not 装备组件节点.装备变更.is_connected(_on_装备变更):
      装备组件节点.装备变更.connect(_on_装备变更)
  if 神魂组件节点 and 神魂组件节点.has_signal("神魂变更"):
    if not 神魂组件节点.神魂变更.is_connected(_on_神魂变更):
      神魂组件节点.神魂变更.connect(_on_神魂变更)

  _刷新技能()


func _on_装备变更(_部位: int, _新装备: Resource, _旧装备: Resource) -> void:
  _刷新技能()


func _on_神魂变更(_新神魂: Resource, _旧神魂: Resource) -> void:
  _刷新技能()


func _刷新技能() -> void:
  当前被动列表.clear()
  当前普攻技能.clear()
  当前大招技能.clear()

  # 从神魂读取普攻+大招
  if 神魂组件节点 and 神魂组件节点.has_method("获取当前神魂"):
    var 当前神魂 = 神魂组件节点.获取当前神魂()
    if 当前神魂 != null:
      当前普攻技能 = _获取技能配置(当前神魂.普攻技能ID)
      当前大招技能 = _获取技能配置(当前神魂.大招技能ID)

  # 从武器读取被动
  if 装备组件节点 and 装备组件节点.has_method("获取部位装备"):
    var 武器 = 装备组件节点.获取部位装备(0)
    if 武器 != null and 武器.has_method("获取部位名"):
      for 技能 in 武器.技能列表:
        if 技能.get("type") == "被动":
          当前被动列表.append(技能)


func _获取技能配置(技能ID: String) -> Dictionary:
  if 技能池数据.is_empty():
    return {"id": 技能ID, "倍率": 1.0, "特效": ""}

  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  var 行 := Jsonc工具.查找行(技能池数据, "skill_id", 技能ID)
  if 行.is_empty():
    return {"id": 技能ID, "倍率": 1.0, "特效": ""}

  var 结果 := {
    "id": 行.get("skill_id", 技能ID),
    "倍率": 行.get("multiplier", 1.0),
    "特效": 行.get("effect", "")
  }
  if 行.get("category", "") == "大招":
    结果["冷却"] = 行.get("cooldown", 0.0)
  return 结果


func 计算普攻伤害(基础劲力: int) -> int:
  var 倍率: float = 当前普攻技能.get("倍率", 1.0)
  var 被动加成: float = 1.0
  for 被动 in 当前被动列表:
    match 被动.get("id"):
      "剑意强化", "剑意": 被动加成 += 0.15
      "劲力增幅": 被动加成 += 0.10
      "雷霆共鸣": pass
      "暴击精通": pass
  return int(基础劲力 * 倍率 * 被动加成)


func 获取大招配置() -> Dictionary:
  return 当前大招技能


func 是否有大招() -> bool:
  return not 当前大招技能.is_empty()


func 获取普攻技能ID() -> String:
  return 当前普攻技能.get("id", "")


func 获取大招技能ID() -> String:
  return 当前大招技能.get("id", "")


func 获取技能列表_by_category(分类: String) -> Array[Dictionary]:
  var 列表: Array[Dictionary] = []
  var 列数组: Array = 技能池数据.get("columns", [])
  var 表格: Array = 技能池数据.get("table", [])
  if 列数组.is_empty() or 表格.is_empty():
    return 列表

  var 列索引 := -1
  for i in range(列数组.size()):
    if 列数组[i].get("name", "") == "category":
      列索引 = i
      break
  if 列索引 < 0:
    return 列表

  for 行 in 表格:
    if 行 is Array and 行.size() > 列索引 and 行[列索引] == 分类:
      var 行字典 := {}
      for j in range(min(列数组.size(), 行.size())):
        行字典[列数组[j].get("name", "")] = 行[j]
      列表.append(行字典)
  return 列表


func 获取法术配置(技能ID: String) -> Dictionary:
  var Jsonc工具 = load("res://公共/jsonc工具.gd")
  var 行 := Jsonc工具.查找行(技能池数据, "skill_id", 技能ID)
  if 行.is_empty() or 行.get("category", "") != "法术":
    return {}

  return {
    "id": 行.get("skill_id", ""),
    "倍率": 行.get("multiplier", 0.0),
    "特效": 行.get("effect", ""),
    "灵气消耗": 行.get("mana_cost", 0),
    "施法距离": 行.get("cast_range", 0.0)
  }
