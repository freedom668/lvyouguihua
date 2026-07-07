/// MCP (Model Context Protocol) 客户端 — 通过 HTTP/JSON-RPC 与 MCP 服务端通信。
///
/// 支持：initialize → tools/list → tools/call 完整协议链路。
/// 若服务端不可达，自动降级为本地 MockDataService 模拟数据。
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mock_data_service.dart';

// ============================================================
// MCP 协议数据模型
// ============================================================

/// MCP 工具定义
class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  factory McpTool.fromJson(Map<String, dynamic> json) {
    return McpTool(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      inputSchema: json['inputSchema'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// MCP 工具调用结果
class McpToolResult {
  final List<McpContent> content;
  final bool isError;

  const McpToolResult({required this.content, this.isError = false});
}

/// MCP 内容块
class McpContent {
  final String type; // "text" | "image" | "resource"
  final String? text;
  final String? data;
  final String? mimeType;

  const McpContent({required this.type, this.text, this.data, this.mimeType});

  factory McpContent.fromJson(Map<String, dynamic> json) {
    return McpContent(
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String?,
      data: json['data'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }
}

// ============================================================
// MCP 客户端
// ============================================================

class McpClientService {
  final String baseUrl;
  final String? apiKey;
  final http.Client _httpClient = http.Client();
  String? _sessionId;

  McpClientService({required this.baseUrl, this.apiKey});

  /// JSON-RPC 2.0 请求封装
  Future<Map<String, dynamic>> _rpc(String method, Map<String, dynamic>? params) async {
    final body = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      'params': params ?? {},
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_sessionId != null) 'Mcp-Session-Id': _sessionId!,
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
    };

    final response = await _httpClient
        .post(Uri.parse('$baseUrl/mcp'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw McpException('HTTP ${response.statusCode}: ${response.body}');
    }

    // 提取 session ID
    final sessionId = response.headers['mcp-session-id'];
    if (sessionId != null) _sessionId = sessionId;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final err = data['error'] as Map<String, dynamic>;
      throw McpException('${err['code']}: ${err['message']}');
    }
    return data['result'] as Map<String, dynamic>;
  }

  /// 初始化连接
  Future<void> initialize() async {
    await _rpc('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {},
      },
      'clientInfo': {
        'name': 'travel-planner-flutter',
        'version': '1.0.0',
      },
    });
  }

  /// 获取服务端工具列表
  Future<List<McpTool>> listTools() async {
    try {
      final result = await _rpc('tools/list', null);
      final tools = (result['tools'] as List<dynamic>)
          .map((t) => McpTool.fromJson(t as Map<String, dynamic>))
          .toList();
      return tools;
    } catch (e) {
      // 如果服务端不可达，返回降级工具列表
      return _fallbackTools();
    }
  }

  /// 调用工具
  Future<McpToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    try {
      final result = await _rpc('tools/call', {
        'name': name,
        'arguments': arguments,
      });
      final content = (result['content'] as List<dynamic>)
          .map((c) => McpContent.fromJson(c as Map<String, dynamic>))
          .toList();
      return McpToolResult(content: content, isError: result['isError'] == true);
    } catch (e) {
      // 降级到本地模拟
      return _fallbackCall(name, arguments);
    }
  }

  // ============================================================
  // 降级方案（服务端不可用时使用本地模拟数据）
  // ============================================================

  List<McpTool> _fallbackTools() {
    return [
      const McpTool(name: 'search_destinations', description: '搜索旅游目的地', inputSchema: {}),
      const McpTool(name: 'plan_itinerary', description: 'AI 智能规划旅行行程', inputSchema: {}),
      const McpTool(name: 'calculate_budget', description: '精确计算旅行预算', inputSchema: {}),
      const McpTool(name: 'recommend_food', description: '推荐当地美食', inputSchema: {}),
      const McpTool(name: 'find_photo_spots', description: '推荐拍照打卡地点', inputSchema: {}),
      const McpTool(name: 'get_weather', description: '查询目的地天气', inputSchema: {}),
    ];
  }

  Future<McpToolResult> _fallbackCall(String name, Map<String, dynamic> arguments) async {
    final cityName = arguments['city'] as String? ?? '目的地';
    String text;

    switch (name) {
      case 'search_destinations':
        text = await MockDataService.searchDestinations(arguments['keyword'] as String? ?? '');
        break;
      case 'plan_itinerary':
        text = await MockDataService.generateAIItinerary(cityName);
        break;
      case 'calculate_budget':
        text = MockDataService.calculateBudget(arguments['days'] as int? ?? 5, arguments['style'] as String? ?? '标准');
        break;
      case 'recommend_food':
        text = '🍜 ${cityName}美食推荐：\n\n1. 当地招牌菜 — 必吃榜单第一名\n2. 特色小吃 — 街头巷尾的经典味道\n3. 网红餐厅 — 年轻人打卡首选\n4. 深夜食堂 — 最有烟火气的美食街';
        break;
      case 'find_photo_spots':
        text = '📷 ${cityName}拍照打卡推荐：\n\n1. 城市地标 — 经典全景机位\n2. 隐秘小巷 — 文艺复古风\n3. 日出观景台 — 金色时刻最佳\n4. 夜景天台 — 城市灯火尽收眼底';
        break;
      case 'get_weather':
        text = '🌤 ${cityName}一周天气预报：\n\n周一 ☀️ 晴 28°C/22°C\n周二 ⛅ 多云 26°C/21°C\n周三 🌧 小雨 24°C/19°C\n周四 ☀️ 晴 27°C/20°C\n周五 ⛅ 多云 25°C/18°C';
        break;
      default:
        text = 'AI 助手已收到您的请求，正在为您处理...';
    }

    return McpToolResult(
      content: [McpContent(type: 'text', text: text)],
    );
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}

/// MCP 异常
class McpException implements Exception {
  final String message;
  const McpException(this.message);

  @override
  String toString() => 'McpException: $message';
}
