extends Node
class_name 状态效果


signal buff添加(buff字典: Dictionary)
signal buff移除(buff字典: Dictionary)
signal buff列表变更()

# id -> buff字典
var _buff列表: Dictionary = {}

@onready var _属性节点: Node = get_parent().get_node_or_null("属性")


func _process(delta: float) -> void:
	var 待移除: Array[String] = []
	for id in _buff列表:
		var buff = _buff列表[id]
		if buff["剩余时间"] > 0:
			buff["剩余时间"] -= delta
			if buff["剩余时间"] <= 0:
				待移除.append(id)
	for id in 待移除:
		移除buff(id)


func 添加buff(配置: Dictionary) -> void:
	if 配置.is_empty() or not 配置.has("id"):
		push_warning("[状态效果] 添加buff失败：配置无效")
		return

	var id: String = 配置["id"]
	if _buff列表.has(id):
		移除buff(id)

	var buff = 配置.duplicate()
	if not buff.has("名称"):
		buff["名称"] = ""
	if not buff.has("类型"):
		buff["类型"] = "属性临时"
	if not buff.has("目标属性"):
		buff["目标属性"] = ""
	if not buff.has("数值"):
		buff["数值"] = 0.0
	if not buff.has("剩余时间"):
		buff["剩余时间"] = 5.0
	if not buff.has("是否百分比"):
		buff["是否百分比"] = false
	if not buff.has("图标颜色"):
		buff["图标颜色"] = "#ffffff"

	var 实际修改值 := _计算并应用(buff)
	buff["实际修改值"] = 实际修改值

	_buff列表[id] = buff
	buff添加.emit(buff)
	buff列表变更.emit()
	print("[状态效果] 添加buff: ", buff["名称"], " 目标=", buff["目标属性"], " 修改=", 实际修改值)


func 移除buff(id: String) -> void:
	if not _buff列表.has(id):
		return
	var buff: Dictionary = _buff列表[id]
	_恢复属性(buff)
	_buff列表.erase(id)
	buff移除.emit(buff)
	buff列表变更.emit()
	print("[状态效果] 移除buff: ", buff["名称"])


func 获取所有buff() -> Array[Dictionary]:
	var 结果: Array[Dictionary] = []
	for id in _buff列表:
		结果.append(_buff列表[id])
	return 结果


func 获取有效属性加成(属性名: String) -> float:
	var 总和: float = 0.0
	for id in _buff列表:
		var buff = _buff列表[id]
		if buff["目标属性"] == 属性名:
			总和 += buff.get("实际修改值", 0.0)
	return 总和


func 清除所有临时buff() -> void:
	var 待移除: Array[String] = []
	for id in _buff列表:
		if _buff列表[id]["类型"] == "属性临时":
			待移除.append(id)
	for id in 待移除:
		移除buff(id)


func 清除所有buff() -> void:
	var 待移除 := _buff列表.keys()
	for id in 待移除:
		移除buff(id)


func _计算并应用(buff: Dictionary) -> float:
	if _属性节点 == null or buff["目标属性"].is_empty():
		return 0.0

	var 属性名: String = buff["目标属性"]
	if not 属性名 in _属性节点:
		push_warning("[状态效果] 属性节点不存在属性: ", 属性名)
		return 0.0

	var 当前值: int = _属性节点.get(属性名)
	var 数值: float = buff["数值"]
	var 实际修改值: float = 0.0

	if buff["是否百分比"]:
		实际修改值 = 当前值 * 数值
	else:
		实际修改值 = 数值

	var 修改后值: int = int(当前值 + 实际修改值)
	_属性节点.set(属性名, 修改后值)

	if 属性名 == "气血上限" and 实际修改值 > 0:
		var 气血: int = _属性节点.get("气血")
		_属性节点.set("气血", 气血 + int(实际修改值))

	return 实际修改值


func _恢复属性(buff: Dictionary) -> void:
	if _属性节点 == null or buff["目标属性"].is_empty():
		return

	var 属性名: String = buff["目标属性"]
	if not 属性名 in _属性节点:
		return

	var 实际修改值: float = buff.get("实际修改值", 0.0)
	var 当前值: int = _属性节点.get(属性名)
	_属性节点.set(属性名, int(当前值 - 实际修改值))

	if 属性名 == "气血上限" and 实际修改值 > 0:
		var 气血: int = _属性节点.get("气血")
		var 新气血: int = maxi(1, 气血 - int(实际修改值))
		_属性节点.set("气血", 新气血)
