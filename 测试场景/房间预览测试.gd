extends Node3D

@onready var 房间管理器节点: Node = $房间管理器
@onready var 模板列表: ItemList = $UI/面板/模板列表
@onready var 类型标签: Label = $UI/面板/类型标签

var _所有模板: Array[Dictionary] = []
var _当前筛选: String = "全部"


func _ready() -> void:
	print("[房间预览测试] 开始")
	_加载房间池()
	_填充列表()
	print("[房间预览测试] 就绪 — 点击左侧列表切换房间预览")


func _加载房间池() -> void:
	var Jsonc工具 = load("res://公共/jsonc工具.gd")
	var 数据: Dictionary = Jsonc工具.解析文件("res://设计/数据/房间池.jsonc")
	var 表格: Array = 数据.get("table", [])
	var 列数组: Array = 数据.get("columns", [])

	var 已见模板 := {}
	for 行 in 表格:
		var 行字典 := {}
		for j in range(min(列数组.size(), 行.size())):
			行字典[列数组[j].get("name", "")] = 行[j]

		var 模板ID: String = 行字典.get("room_template_id", "")
		if 模板ID.is_empty() or 已见模板.has(模板ID):
			continue
		已见模板[模板ID] = true
		_所有模板.append(行字典)

	print("[房间预览测试] 加载了 %d 个唯一模板" % _所有模板.size())


func _填充列表() -> void:
	模板列表.clear()
	for 模板 in _所有模板:
		var 类型: String = 模板.get("room_type", "")
		if _当前筛选 != "全部" and 类型 != _当前筛选:
			continue
		var 模板ID: String = 模板.get("room_template_id", "")
		var 说明: String = 模板.get("note", "")
		var 显示文本 := "%s | %s | %s" % [模板ID, 类型, 说明]
		模板列表.add_item(显示文本)
		模板列表.set_item_metadata(模板列表.item_count - 1, 模板ID)

	类型标签.text = "当前筛选: %s (%d个)" % [_当前筛选, 模板列表.item_count]


func _on_筛选按钮按下(类型: String) -> void:
	_当前筛选 = 类型
	_填充列表()


func _on_模板列表_item_selected(索引: int) -> void:
	var 模板ID: String = 模板列表.get_item_metadata(索引)
	if 模板ID.is_empty():
		return
	房间管理器节点.加载房间(模板ID)
	print("[房间预览测试] 已加载: %s" % 模板ID)
