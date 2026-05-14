extends Node

var 玩家数据: Dictionary = {}
var 当前层数: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func 保存副本状态(主角实例: Node3D, 层数: int) -> void:
	if 主角实例 == null:
		return
	当前层数 = 层数
	var 数据: Dictionary = {}

	var 属性节点 = 主角实例.get_node_or_null("属性")
	if 属性节点:
		数据["属性"] = {
			"气血上限": 属性节点.气血上限,
			"气血": 属性节点.气血,
			"境界": 属性节点.境界,
			"修为": 属性节点.修为,
			"寿元上限": 属性节点.寿元上限,
			"寿元": 属性节点.寿元,
			"身法": 属性节点.身法,
			"劲力": 属性节点.劲力,
			"根骨": 属性节点.根骨,
			"悟性": 属性节点.悟性,
			"气运": 属性节点.气运,
			"神识": 属性节点.神识,
		}

	var 装备节点 = 主角实例.get_node_or_null("装备组件")
	if 装备节点 and 装备节点.has_method("序列化"):
		数据["装备"] = 装备节点.序列化()

	玩家数据 = 数据
	print("[全局状态] 副本状态已保存（第%d层）" % 当前层数)


func 恢复副本状态(目标场景: Node) -> Node3D:
	if 玩家数据.is_empty():
		return null

	var 主角场景: PackedScene = load("res://角色/主角/主角.tscn")
	if 主角场景 == null:
		push_error("[全局状态] 无法加载主角场景")
		return null
	var 主角 = 主角场景.instantiate()
	主角.name = "主角"
	目标场景.add_child(主角)
	主角.add_to_group("玩家")

	var 属性节点 = 主角.get_node_or_null("属性")
	if 属性节点 and 玩家数据.has("属性"):
		var 属性数据 = 玩家数据["属性"]
		属性节点.气血上限 = 属性数据.get("气血上限", 100)
		属性节点.气血 = 属性数据.get("气血", 100)
		属性节点.境界 = 属性数据.get("境界", 0)
		属性节点.修为 = 属性数据.get("修为", 0)
		属性节点.寿元上限 = 属性数据.get("寿元上限", 80)
		属性节点.寿元 = 属性数据.get("寿元", 80)
		属性节点.身法 = 属性数据.get("身法", 10)
		属性节点.劲力 = 属性数据.get("劲力", 10)
		属性节点.根骨 = 属性数据.get("根骨", 0)
		属性节点.悟性 = 属性数据.get("悟性", 0)
		属性节点.气运 = 属性数据.get("气运", 0)
		属性节点.神识 = 属性数据.get("神识", 5)

	var 装备节点 = 主角.get_node_or_null("装备组件")
	if 装备节点 and 玩家数据.has("装备"):
		装备节点.反序列化(玩家数据["装备"])

	print("[全局状态] 副本状态已恢复（第%d层）" % 当前层数)
	return 主角


func 保存到大厅(主角实例: Node3D) -> void:
	保存副本状态(主角实例, 当前层数)


func 从大厅恢复(目标场景: Node) -> Node3D:
	return 恢复副本状态(目标场景)


func 清空状态() -> void:
	玩家数据.clear()
	当前层数 = 1
