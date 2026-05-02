extends Node
class_name 属性


signal 受伤信号(伤害值: int)
signal 死亡信号()


enum 境界等级 { 炼气期, 筑基期, 金丹期, 元婴期, 化神期 }
enum 品级 { 凡品, 良品, 上品, 极品, 天品 }

# 角色模板名，用于从 JSONC 表加载初始属性；为空则使用下方默认值
@export var 角色模板: String = ""

# 气血
@export var 气血上限: int = 100
@export var 气血: int = 100

# 修为与境界
@export var 境界: 境界等级 = 境界等级.炼气期
@export var 修为: int = 0

# 寿元
@export var 寿元上限: int = 80  # 年
@export var 寿元: int = 80

# 身法
@export var 身法: int = 10

# 劲力（普攻伤害 / 体修剑修根基）
@export var 劲力: int = 10

# 根骨 / 悟性
@export var 根骨: 品级 = 品级.凡品
@export var 悟性: 品级 = 品级.凡品

# 气运
@export var 气运: int = 0

# 神识
@export var 神识: int = 5

var _无敌倒计时: float = 0.0

const 表路径 := "res://设计/数据/角色属性.jsonc"


const 品级倍率: Dictionary = {
  品级.凡品: 0.8,
  品级.良品: 1.0,
  品级.上品: 1.2,
  品级.极品: 1.5,
  品级.天品: 2.0,
}

const 境界阈值: Dictionary = {
  境界等级.炼气期: 100,
  境界等级.筑基期: 500,
  境界等级.金丹期: 2000,
  境界等级.元婴期: 8000,
  境界等级.化神期: 999999,
}

const 境界寿元: Dictionary = {
  境界等级.炼气期: 80,
  境界等级.筑基期: 200,
  境界等级.金丹期: 500,
  境界等级.元婴期: 1000,
  境界等级.化神期: 2000,
}

const 境界神识: Dictionary = {
  境界等级.炼气期: 5,
  境界等级.筑基期: 20,
  境界等级.金丹期: 50,
  境界等级.元婴期: 100,
  境界等级.化神期: 500,
}


func _ready() -> void:
  气血 = 气血上限
  寿元 = 寿元上限
  死亡信号.connect(_on_死亡)
  print("[属性] 就绪 owner=", get_parent().name,
    " 模板=", 角色模板 if not 角色模板.is_empty() else "(默认)",
    " 境界=", 境界等级.keys()[境界],
    " 根骨=", 品级.keys()[根骨],
    " 悟性=", 品级.keys()[悟性])


func 加载模板属性() -> void:
  if 角色模板.is_empty():
    return
  var Jsonc工具 := load("res://公共/jsonc工具.gd")
  if Jsonc工具 == null:
    push_warning("[属性] 无法加载 Jsonc工具")
    return
  var 数据: Dictionary = Jsonc工具.解析文件(表路径)
  var 行: Dictionary = Jsonc工具.查找行(数据, "角色模板", 角色模板)
  if 行.is_empty():
    push_warning("[属性] 未找到模板 '", 角色模板, "'，使用默认值")
    return
  气血上限 = int(行.get("气血上限", 气血上限))
  境界 = int(行.get("境界", 境界)) as 境界等级
  修为 = int(行.get("修为", 修为))
  寿元上限 = int(行.get("寿元上限", 寿元上限))
  身法 = int(行.get("身法", 身法))
  劲力 = int(行.get("劲力", 劲力))
  根骨 = int(行.get("根骨", 根骨)) as 品级
  悟性 = int(行.get("悟性", 悟性)) as 品级
  气运 = int(行.get("气运", 气运))
  神识 = int(行.get("神识", 神识))
  气血 = 气血上限
  寿元 = 寿元上限


func _physics_process(delta: float) -> void:
  if _无敌倒计时 > 0:
    _无敌倒计时 -= delta


func 受伤(伤害值: int) -> void:
  if _无敌倒计时 > 0:
    return
  气血 = maxi(0, 气血 - 伤害值)
  _无敌倒计时 = 0.5
  print("[属性] ", get_parent().name, " 受伤 ", 伤害值, " 剩余气血 ", 气血)

  var 粒子 = get_parent().get_node_or_null("受击粒子")
  if 粒子:
    粒子.restart()
    粒子.emitting = true

  受伤信号.emit(伤害值)
  if 气血 <= 0:
    死亡信号.emit()


func 是否死亡() -> bool:
  return 气血 <= 0


func _on_死亡() -> void:
  print("[属性] ", get_parent().name, " 死亡")
  get_parent().set_physics_process(false)
  await get_tree().create_timer(0.5).timeout
  get_parent().queue_free()


func 获取根骨倍率() -> float:
  return 品级倍率[根骨]


func 获取悟性倍率() -> float:
  return 品级倍率[悟性]


func 获取身法移速倍率() -> float:
  return 1.0 + (身法 - 10) * 0.02


func 是否可突破() -> bool:
  return 修为 >= 境界阈值[境界]


func 尝试突破() -> bool:
  if not 是否可突破():
    return false
  var 基础成功率 := 0.3
  var 悟性加成 := (获取悟性倍率() - 0.8) * 0.3
  var 气运加成 := 气运 * 0.01
  var 成功率 := clampf(基础成功率 + 悟性加成 + 气运加成, 0.05, 0.95)
  if randf() < 成功率:
    境界 = (境界 + 1) as 境界等级
    寿元上限 = 境界寿元[境界]
    神识 = 境界神识[境界]
    气血上限 = int(气血上限 * 1.5)
    气血 = 气血上限
    print("[属性] 突破成功！新境界：", 境界等级.keys()[境界])
    return true
  else:
    修为 = int(修为 * 0.8)
    print("[属性] 突破失败，修为倒退至 ", 修为)
    return false
