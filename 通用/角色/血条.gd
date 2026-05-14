extends Sprite3D


@export var 填充色: Color = Color(0.25, 0.75, 0.25)

@onready var 属性组件: Node = get_parent().get_node("属性")

const 条宽: int = 64
const 条高: int = 8


func _ready() -> void:
  pixel_size = 0.015
  billboard = BaseMaterial3D.BILLBOARD_ENABLED
  属性组件.受伤信号.connect(_on_受伤)
  _更新血条()


func _on_受伤(_伤害值: int) -> void:
  _更新血条()


func 设置填充色(颜色: Color) -> void:
  填充色 = 颜色
  _更新血条()


func _更新血条() -> void:
  var 图像 := Image.create(条宽, 条高, false, Image.FORMAT_RGBA8)
  图像.fill(Color(0.2, 0.05, 0.05, 1.0))
  var 比例 := clampf(float(属性组件.气血) / float(属性组件.气血上限), 0.0, 1.0)
  var 填充宽 := maxi(1, int(条宽 * 比例))
  for x in range(填充宽):
    for y in range(条高):
      图像.set_pixel(x, y, 填充色)
  texture = ImageTexture.create_from_image(图像)
