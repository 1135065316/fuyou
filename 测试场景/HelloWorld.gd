extends Node


func _ready() -> void:
  print("Hello, World! —— 蜉蝣录 MCP 控制台链路验证")
  print("Godot 版本：", Engine.get_version_info().string)
  print("项目名：", ProjectSettings.get_setting("application/config/name"))
  # 不主动退出，由 mcp 的 stop_project 收尾，保证 get_debug_output 能抓到 stdout
