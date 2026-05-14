/// AI Prompt 提示词输入页面 — 调用 Agent 后端 /generate_trip 生成行程。
///
/// 用户输入自然语言需求 → POST agent_backend:9000/generate_trip
/// → Agent 自动调用高德地图/天气/博查 MCP 工具 → 返回完整行程规划。
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/mcp_config.dart';
import '../utils/ui_helper.dart';
import '../constants/app_constants.dart';

class PromptPage extends StatefulWidget {
  const PromptPage({super.key});

  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  final _templates = [
    const Template(label: '🏖️ 海岛度假', prompt: '推荐一个5天的海岛度假行程，预算5000元以内'),
    const Template(label: '🏛️ 文化古迹', prompt: '规划一条历史文化主题的旅行路线，包含博物馆和古迹'),
    const Template(label: '🍜 美食之旅', prompt: '设计一条以美食为主题的旅行路线，推荐当地必吃餐厅'),
    const Template(label: '👨‍👩‍👧 亲子出游', prompt: '推荐适合带孩子出行的亲子游行程，安排轻松有趣'),
    const Template(label: '💑 蜜月旅行', prompt: '规划一条浪漫的蜜月旅行路线，适合情侣打卡'),
    const Template(label: '🏔️ 户外探险', prompt: '设计一条户外探险路线，包含徒步、攀岩等户外运动'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 从用户输入中提取城市、天数、风格
  Map<String, dynamic> _parsePrompt(String text) {
    String city = '三亚';
    int days = 5;
    String style = '休闲';

    // 简单关键词匹配提取城市
    final cities = ['三亚', '京都', '巴黎', '马尔代夫', '曼谷', '瑞士', '巴厘岛', '罗马', '迪拜', '圣托里尼', '北京', '上海', '成都', '杭州'];
    for (final c in cities) {
      if (text.contains(c)) {
        city = c;
        break;
      }
    }

    // 提取天数
    final dayMatch = RegExp(r'(\d+)\s*天').firstMatch(text);
    if (dayMatch != null) days = int.tryParse(dayMatch.group(1)!) ?? 5;

    // 提取风格
    if (text.contains('蜜月') || text.contains('浪漫')) style = '蜜月';
    if (text.contains('美食') || text.contains('吃')) style = '美食';
    if (text.contains('文化') || text.contains('历史') || text.contains('古迹')) style = '文化';
    if (text.contains('探险') || text.contains('户外') || text.contains('徒步')) style = '探险';

    return {'city': city, 'days': days, 'style': style};
  }

  /// 通过 MCP 协议提交请求
  void _submitPrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入你的旅行需求')),
      );
      return;
    }

    setState(() => _isLoading = true);
    UIHelper.showLoading(context);

    final args = _parsePrompt(text);
    final serverUrl = await McpConfig.getServerUrl();

    String resultText;
    try {
      final uri = Uri.parse('$serverUrl/generate_trip');
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt': text,
                'city': args['city'],
                'days': args['days'],
                'style': args['style'],
              }))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        resultText = data['itinerary'] ?? 'Agent 未返回行程内容';
      } else {
        resultText = '请求失败 (${response.statusCode})，请确认 Agent 后端已启动';
      }
    } catch (e) {
      resultText = '连接失败，请确认 Agent 后端已启动在 $serverUrl\n\n错误：$e';
    }

    if (mounted) {
      setState(() => _isLoading = false);
      UIHelper.hideLoading(context);
      Navigator.pushNamed(context, '/result', arguments: {
        'text': resultText,
        'city': args['city'],
        'days': args['days'],
      });
    }
  }

  void _selectTemplate(Template template) {
    _promptController.text = template.prompt;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ========== 顶部标题栏 ==========
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: AppConstants.primaryGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16, left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                      SizedBox(height: 10),
                      Text('AI 旅游顾问', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('告诉我你的需求，AI 为你规划行程', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ]),
                  ),
                ],
              ),
            ),

            // ========== 输入区域 ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _promptController,
                  focusNode: _focusNode,
                  maxLines: 4, minLines: 3,
                  style: const TextStyle(fontSize: 15, color: AppConstants.textPrimary, height: 1.5),
                  decoration: InputDecoration(
                    hintText: '例如：我想去三亚玩5天，预算5000元，喜欢海边和美食，帮我规划一下...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // ========== 快捷模板 ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Row(children: [
                Icon(Icons.bolt, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text('快捷模板', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black.withValues(alpha: 0.45))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _templates.map((t) => GestureDetector(
                  onTap: () => _selectTemplate(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(t.label, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                  ),
                )).toList(),
              ),
            ),

            const Spacer(),

            // ========== 提交按钮 ==========
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: GestureDetector(
                  onTap: _isLoading ? null : _submitPrompt,
                  child: Container(
                    height: AppConstants.buttonHeight,
                    decoration: BoxDecoration(
                      gradient: AppConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                      boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('✨  开始生成行程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Template {
  final String label;
  final String prompt;
  const Template({required this.label, required this.prompt});
}
