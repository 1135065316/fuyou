extends Control
class_name 小地图

var 楼层图: Array = []
var 当前房间: Variant = null
var 大地图模式 := false
var 显示中心: Vector2 = Vector2.ZERO

const 小地图尺寸 := Vector2(164, 164)
const 大地图尺寸 := Vector2(400, 400)
const 插值速度 := 8.0


func 设置楼层图(图: Array) -> void:
  楼层图 = 图
  queue_redraw()


func 设置当前房间(房间) -> void:
  当前房间 = 房间
  if 当前房间 != null:
    var 目标 := Vector2(当前房间.位置.x, 当前房间.位置.y)
    if 显示中心 == Vector2.ZERO or 显示中心.distance_to(目标) > 3.0:
      显示中心 = 目标
  queue_redraw()


func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and event.keycode == KEY_M:
    大地图模式 = not 大地图模式
    _更新布局()
    queue_redraw()
    get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
  if 当前房间 == null:
    return
  var 目标 := Vector2(当前房间.位置.x, 当前房间.位置.y)
  if 显示中心.distance_to(目标) > 0.01:
    显示中心 = 显示中心.lerp(目标, 插值速度 * delta)
    queue_redraw()


func _更新布局() -> void:
  if 大地图模式:
    anchors_preset = Control.PRESET_CENTER
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -大地图尺寸.x / 2
    offset_top = -大地图尺寸.y / 2
    offset_right = 大地图尺寸.x / 2
    offset_bottom = 大地图尺寸.y / 2
    custom_minimum_size = 大地图尺寸
  else:
    anchors_preset = Control.PRESET_TOP_RIGHT
    anchor_left = 1.0
    anchor_top = 0.0
    anchor_right = 1.0
    anchor_bottom = 0.0
    offset_left = -180
    offset_top = 16
    offset_right = -16
    offset_bottom = 180
    custom_minimum_size = 小地图尺寸


func _draw() -> void:
  var 背景透明度: float = 0.92 if 大地图模式 else 0.85
  draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.05, 背景透明度))
  if 楼层图.is_empty() or 当前房间 == null:
    return

  if 大地图模式:
    _绘制全局地图()
  else:
    _绘制局部地图()


func _绘制局部地图() -> void:
  var 视野半径 := 3
  var 中心x: float = 显示中心.x
  var 中心y: float = 显示中心.y
  var 最小x: float = 中心x - 视野半径
  var 最大x: float = 中心x + 视野半径
  var 最小y: float = 中心y - 视野半径
  var 最大y: float = 中心y + 视野半径

  var 边距: float = 8.0
  var 可用宽: float = size.x - 边距 * 2
  var 可用高: float = size.y - 边距 * 2
  var 格子大小: float = minf(可用宽 / (视野半径 * 2 + 1), 可用高 / (视野半径 * 2 + 1))
  var 起始x: float = 边距 + (可用宽 - 格子大小 * (视野半径 * 2 + 1)) / 2
  var 起始y: float = 边距 + (可用高 - 格子大小 * (视野半径 * 2 + 1)) / 2

  for 节点 in 楼层图:
    for 方向 in 节点.连接门.keys():
      var 相邻节点 = 节点.连接门[方向]
      if _在视野内(节点, 最小x, 最大x, 最小y, 最大y) and _在视野内(相邻节点, 最小x, 最大x, 最小y, 最大y):
        var x1: float = 起始x + (节点.位置.x - 最小x) * 格子大小 + 格子大小 / 2
        var y1: float = 起始y + (节点.位置.y - 最小y) * 格子大小 + 格子大小 / 2
        var x2: float = 起始x + (相邻节点.位置.x - 最小x) * 格子大小 + 格子大小 / 2
        var y2: float = 起始y + (相邻节点.位置.y - 最小y) * 格子大小 + 格子大小 / 2
        draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.4, 0.4, 0.4, 0.6), 2)

  for 节点 in 楼层图:
    if not _在视野内(节点, 最小x, 最大x, 最小y, 最大y):
      continue
    var rect := Rect2(
      起始x + (节点.位置.x - 最小x) * 格子大小 + 2,
      起始y + (节点.位置.y - 最小y) * 格子大小 + 2,
      格子大小 - 4,
      格子大小 - 4
    )
    var 颜色: Color = Color(0.85, 0.85, 0.85) if 节点.是否已访问 else Color(0.25, 0.25, 0.25, 0.6)
    draw_rect(rect, 颜色)

  var 玩家x: float = 起始x + (当前房间.位置.x - 最小x) * 格子大小 + 格子大小 / 2
  var 玩家y: float = 起始y + (当前房间.位置.y - 最小y) * 格子大小 + 格子大小 / 2
  draw_circle(Vector2(玩家x, 玩家y), 格子大小 * 0.28, Color.RED)


func _绘制全局地图() -> void:
  var min_x: float = INF
  var max_x: float = -INF
  var min_y: float = INF
  var max_y: float = -INF
  for 节点 in 楼层图:
    min_x = minf(min_x, 节点.位置.x)
    max_x = maxf(max_x, 节点.位置.x)
    min_y = minf(min_y, 节点.位置.y)
    max_y = maxf(max_y, 节点.位置.y)

  var 地图宽: float = max_x - min_x + 1
  var 地图高: float = max_y - min_y + 1
  var 边距: float = 12.0
  var 可用宽: float = size.x - 边距 * 2
  var 可用高: float = size.y - 边距 * 2
  var 格子大小: float = minf(可用宽 / 地图宽, 可用高 / 地图高)
  var 起始x: float = 边距 + (可用宽 - 格子大小 * 地图宽) / 2
  var 起始y: float = 边距 + (可用高 - 格子大小 * 地图高) / 2

  for 节点 in 楼层图:
    for 方向 in 节点.连接门.keys():
      var 相邻节点 = 节点.连接门[方向]
      var x1: float = 起始x + (节点.位置.x - min_x + 0.5) * 格子大小
      var y1: float = 起始y + (节点.位置.y - min_y + 0.5) * 格子大小
      var x2: float = 起始x + (相邻节点.位置.x - min_x + 0.5) * 格子大小
      var y2: float = 起始y + (相邻节点.位置.y - min_y + 0.5) * 格子大小
      draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.4, 0.4, 0.4, 0.6), 2)

  for 节点 in 楼层图:
    var rect := Rect2(
      起始x + (节点.位置.x - min_x) * 格子大小 + 2,
      起始y + (节点.位置.y - min_y) * 格子大小 + 2,
      格子大小 - 4,
      格子大小 - 4
    )
    var 颜色: Color = Color(0.85, 0.85, 0.85) if 节点.是否已访问 else Color(0.25, 0.25, 0.25, 0.6)
    draw_rect(rect, 颜色)

  var 玩家x: float = 起始x + (当前房间.位置.x - min_x + 0.5) * 格子大小
  var 玩家y: float = 起始y + (当前房间.位置.y - min_y + 0.5) * 格子大小
  draw_circle(Vector2(玩家x, 玩家y), 格子大小 * 0.28, Color.RED)


func _在视野内(节点, 最小x: float, 最大x: float, 最小y: float, 最大y: float) -> bool:
  return 节点.位置.x >= 最小x and 节点.位置.x <= 最大x and 节点.位置.y >= 最小y and 节点.位置.y <= 最大y
