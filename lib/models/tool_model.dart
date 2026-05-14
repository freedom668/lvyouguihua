/// AI 工具数据模型 —— 用于 MCP Tools 选择页面的开关状态管理。
import 'package:flutter/material.dart';

class ToolModel {
  final String name;
  final String description;
  final IconData icon;
  bool isEnabled;

  ToolModel({
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = true,
  });
}
