/// MCP Tools 选择页面 —— 动态发现 MCP 服务端工具列表 + 开关控制。
///
/// 页面加载时调用 McpClientService.listTools() 获取真实工具列表，
/// 服务端不可达时自动降级为本地预设工具。
import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/mcp_client_service.dart';
import '../services/mcp_config.dart';
import '../constants/app_constants.dart';

class ToolsSelectionPage extends StatefulWidget {
  const ToolsSelectionPage({super.key});

  @override
  State<ToolsSelectionPage> createState() => _ToolsSelectionPageState();
}

class _ToolsSelectionPageState extends State<ToolsSelectionPage> {
  List<ToolModel> _tools = [];
  bool _isLoading = true;
  String _serverStatus = '正在连接 MCP 服务端...';

  McpClientService? _mcpClient;

  @override
  void initState() {
    super.initState();
    _discoverTools();
  }

  /// 从 MCP 服务端发现工具列表
  Future<void> _discoverTools() async {
    try {
      final url = await McpConfig.getServerUrl();
      final key = await McpConfig.getApiKey();
      _mcpClient = McpClientService(baseUrl: url, apiKey: key);
      await _mcpClient!.initialize();
      final tools = await _mcpClient!.listTools();

      if (mounted) {
        setState(() {
          _tools = tools.map((t) => ToolModel(
            name: t.name,
            description: t.description,
            icon: _iconForTool(t.name),
            isEnabled: true,
          )).toList();
          _isLoading = false;
          _serverStatus = 'MCP 服务端已连接 · ${_tools.length} 个工具可用';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tools = _fallbackTools();
          _isLoading = false;
          _serverStatus = 'MCP 离线模式 · 使用本地预设工具';
        });
      }
    }
  }

  /// 工具名 → 图标映射
  IconData _iconForTool(String name) {
    switch (name) {
      case 'search_destinations': return Icons.search;
      case 'plan_itinerary': return Icons.route;
      case 'calculate_budget': return Icons.calculate;
      case 'recommend_food': return Icons.restaurant;
      case 'find_photo_spots': return Icons.camera_alt;
      case 'get_weather': return Icons.cloud;
      default: return Icons.build;
    }
  }

  List<ToolModel> _fallbackTools() {
    return [
      ToolModel(name: 'search_destinations', description: '搜索旅游目的地', icon: Icons.search),
      ToolModel(name: 'plan_itinerary', description: 'AI 智能规划旅行行程', icon: Icons.route),
      ToolModel(name: 'calculate_budget', description: '精确计算旅行预算', icon: Icons.calculate),
      ToolModel(name: 'recommend_food', description: '推荐当地美食', icon: Icons.restaurant),
      ToolModel(name: 'find_photo_spots', description: '推荐拍照打卡地点', icon: Icons.camera_alt),
      ToolModel(name: 'get_weather', description: '查询目的地天气', icon: Icons.cloud),
    ];
  }

  void _handleSave() {
    final enabledTools = _tools.where((t) => t.isEnabled).map((t) => t.name).toList();
    debugPrint('MCP 工具配置已保存: $enabledTools');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('配置已保存 · ${enabledTools.length} 个工具已开启'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      ),
    );
  }

  @override
  void dispose() {
    _mcpClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldBg,
      appBar: AppBar(
        title: const Text('MCP 工具配置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 服务端状态指示
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _serverStatus.contains('离线') ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _serverStatus.contains('离线') ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(children: [
              Icon(
                _serverStatus.contains('离线') ? Icons.wifi_off : Icons.wifi,
                size: 16,
                color: _serverStatus.contains('离线') ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_serverStatus, style: TextStyle(fontSize: 12,
                    color: _serverStatus.contains('离线') ? Colors.orange[800] : Colors.green[800])),
              ),
              if (!_serverStatus.contains('离线'))
                Text('🟢', style: TextStyle(fontSize: 10)),
            ]),
          ),

          // 工具列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tools.length,
                    itemBuilder: (context, index) {
                      final tool = _tools[index];
                      return _buildToolCard(tool);
                    },
                  ),
          ),

          // 底部保存按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: GestureDetector(
                onTap: _handleSave,
                child: Container(
                  height: AppConstants.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: const Center(
                    child: Text('保存配置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(ToolModel tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(tool.icon, color: Colors.blue, size: 22),
        ),
        title: Text(tool.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
        subtitle: Text(tool.description, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
        value: tool.isEnabled,
        activeThumbColor: AppConstants.primaryColor,
        onChanged: (value) => setState(() => tool.isEnabled = value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
