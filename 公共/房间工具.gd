extends RefCounted


static func 解析向量3(文本: String) -> Vector3:
  var 部分 := 文本.split(",")
  if 部分.size() >= 3:
    return Vector3(float(部分[0]), float(部分[1]), float(部分[2]))
  return Vector3.ZERO


static func 解析颜色(文本: String) -> Color:
  return Color(文本)
