extends RefCounted


static func 解析文件(路径: String) -> Dictionary:
  var 内容 := FileAccess.get_file_as_string(路径)
  if 内容.is_empty() and not FileAccess.file_exists(路径):
    push_error("[Jsonc工具] 文件不存在: " + 路径)
    return {}
  var 去注释 := _去掉注释(内容)
  var 结果: Variant = JSON.parse_string(去注释)
  if 结果 == null:
    push_error("[Jsonc工具] 解析失败: " + 路径)
    return {}
  return 结果 as Dictionary


static func 查找行(数据: Dictionary, 列名: String, 值: Variant) -> Dictionary:
  var 列数组: Array = 数据.get("columns", [])
  var 表格: Array = 数据.get("table", [])
  if 列数组.is_empty() or 表格.is_empty():
    return {}

  var 列索引 := -1
  for i in range(列数组.size()):
    if 列数组[i].get("name", "") == 列名:
      列索引 = i
      break
  if 列索引 < 0:
    return {}

  for 行 in 表格:
    if 行 is Array and 行.size() > 列索引 and 行[列索引] == 值:
      var 行字典 := {}
      for j in range(min(列数组.size(), 行.size())):
        行字典[列数组[j].get("name", "")] = 行[j]
      return 行字典
  return {}


static func _去掉注释(文本: String) -> String:
  var 结果 := ""
  var 在字符串内 := false
  var i := 0
  while i < 文本.length():
    var 字符 := 文本[i]
    if not 在字符串内:
      if 字符 == '"':
        在字符串内 = true
        结果 += 字符
      elif 字符 == "/" and i + 1 < 文本.length():
        var 下一个 := 文本[i + 1]
        if 下一个 == "/":
          while i < 文本.length() and 文本[i] != "\n":
            i += 1
          continue
        elif 下一个 == "*":
          i += 2
          while i < 文本.length() - 1:
            if 文本[i] == "*" and 文本[i + 1] == "/":
              i += 2
              break
            i += 1
          continue
        else:
          结果 += 字符
      else:
        结果 += 字符
    else:
      if 字符 == "\\" and i + 1 < 文本.length():
        结果 += 字符
        i += 1
        结果 += 文本[i]
      elif 字符 == '"':
        在字符串内 = false
        结果 += 字符
      else:
        结果 += 字符
    i += 1
  return 结果
