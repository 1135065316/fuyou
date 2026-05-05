extends Node
class_name 技能冷却

## CD表：{部位索引: {技能索引: 剩余CD秒数}}
var _冷却表: Dictionary = {}


func 触发冷却(部位: int, 技能索引: int, CD时长: float) -> void:
	if not _冷却表.has(部位):
		_冷却表[部位] = {}
	_冷却表[部位][技能索引] = CD时长


func 是否就绪(部位: int, 技能索引: int) -> bool:
	if not _冷却表.has(部位):
		return true
	if not _冷却表[部位].has(技能索引):
		return true
	return _冷却表[部位][技能索引] <= 0.0


func 获取剩余CD(部位: int, 技能索引: int) -> float:
	if not _冷却表.has(部位):
		return 0.0
	return _冷却表[部位].get(技能索引, 0.0)


func 重置部位(部位: int) -> void:
	if _冷却表.has(部位):
		_冷却表.erase(部位)


func 重置所有() -> void:
	_冷却表.clear()


func _process(delta: float) -> void:
	var 需清理部位: Array = []
	for 部位 in _冷却表.keys():
		var 需清理技能: Array = []
		for 技能索引 in _冷却表[部位].keys():
			_冷却表[部位][技能索引] -= delta
			if _冷却表[部位][技能索引] <= 0.0:
				需清理技能.append(技能索引)
		for 技能索引 in 需清理技能:
			_冷却表[部位].erase(技能索引)
		if _冷却表[部位].is_empty():
			需清理部位.append(部位)
	for 部位 in 需清理部位:
		_冷却表.erase(部位)
