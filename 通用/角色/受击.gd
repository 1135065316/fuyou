extends Area3D


func _ready() -> void:
  body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
  if body == get_parent():
    return
  if not body.has_node("属性"):
    return

  var 我的属性: Node = get_parent().get_node_or_null("属性")
  var 对方属性: Node = body.get_node_or_null("属性")
  if 我的属性 == null or 对方属性 == null:
    return
  var 伤害值: int = 我的属性.劲力
  var 技能节点 = get_parent().get_node_or_null("技能管理器")
  if 技能节点 and 技能节点.has_method("计算普攻伤害"):
    伤害值 = 技能节点.计算普攻伤害(我的属性.劲力)
  对方属性.受伤(伤害值)
