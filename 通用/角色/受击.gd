extends Area3D


func _ready() -> void:
  body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
  if body == get_parent():
    return
  if not body.has_node("属性"):
    return

  var 我的属性: Node = get_parent().get_node("属性")
  var 对方属性: Node = body.get_node("属性")
  对方属性.受伤(我的属性.劲力)
