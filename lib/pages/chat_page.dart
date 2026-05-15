/// AI 旅游助手聊天页 —— 对话框形式 + SharedPreferences 长记忆。
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';
import '../constants/app_constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _localStorage = LocalStorageService();
  List<Map<String, String>> _messages = [];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _localStorage.getChatHistory();
    if (mounted) setState(() => _messages = history);
  }

  Future<void> _saveHistory() async {
    await _localStorage.saveChatHistory(_messages);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isThinking) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _isThinking = true;
    });
    _textController.clear();
    _saveHistory();
    _scrollToBottom();
    _callAgent(text.trim());
  }

  Future<void> _callAgent(String query) async {
    try {
      final url = await _localStorage.getMcpServerUrl();
      final uri = Uri.parse('$url/generate_trip');
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': query, 'days': 1, 'style': '快速咨询'}),
      ).timeout(const Duration(seconds: 60));

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['itinerary'] ?? '抱歉，AI 没有返回有效回复。';
      } else {
        reply = _mockReply(query);
      }
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isThinking = false;
        });
        _saveHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': _mockReply(query)});
          _isThinking = false;
        });
        _saveHistory();
        _scrollToBottom();
      }
    }
  }

  String _mockReply(String query) {
    final tips = [
      '建议提前查看目的地天气，合理搭配衣物。',
      '热门景点建议提前网上购票，避免排队。',
      '出行前确认护照和签证有效期。',
      '建议购买旅游保险，以防意外。',
      '当地公共交通一般比出租车更划算。',
      '尝试当地特色小吃是旅行的一大乐趣！',
      '住宿建议选择市中心或交通便利的区域。',
      '记得随身携带充电宝和转换插头。',
    ];
    tips.shuffle();
    return '关于「$query」的建议：\n\n${tips.take(3).join('\n')}\n\n当前 AI 后端未连接，以上为离线建议。';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('AI 旅行助手'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onSelected: (v) {
              if (v == 'clear') {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: const Text('清空聊天记录'),
                  content: const Text('确认删除所有聊天记录？此操作不可恢复。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    TextButton(onPressed: () { Navigator.pop(ctx); _clearHistory(); },
                        child: const Text('确认', style: TextStyle(color: Colors.red))),
                  ],
                ));
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'clear', child: Text('清空聊天记录', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcome(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildBubble(_messages[i]),
                ),
        ),
        // 输入栏
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2))]),
          child: SafeArea(top: false, child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1, maxLines: 4,
                decoration: InputDecoration(
                  hintText: '输入你的旅游问题...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), filled: true, fillColor: const Color(0xFFF7F8FA),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(width: 42, height: 42,
                decoration: BoxDecoration(gradient: AppConstants.primaryGradient, shape: BoxShape.circle),
                child: _isThinking ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
      bottomNavigationBar: _buildNav(1),
    );
  }

  Widget _buildBubble(Map<String, String> msg) {
    final isMe = msg['role'] == 'user';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(msg['content'] ?? '', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppConstants.textPrimary, height: 1.5)),
      ),
    );
  }

  void _clearHistory() async {
    await _localStorage.saveChatHistory([]);
    setState(() => _messages.clear());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('聊天记录已清空'), behavior: SnackBarBehavior.floating));
  }

  Widget _buildWelcome(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _buildBubble({'role': 'assistant', 'content': '你好！我是你的 AI 旅游助手 ✈️\n\n我可以帮你：\n• 推荐目的地和旅游攻略\n• 解答出行注意事项\n• 推荐当地美食和景点\n• 提供天气和交通建议\n\n有什么旅游问题尽管问我吧！'}),
    ]);
  }

  Widget _buildNav(int current) => Container(
    decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))]),
    child: BottomNavigationBar(
      currentIndex: current,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey[400],
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      onTap: (i) {
        if (i == current) return;
        switch (i) {
          case 0: Navigator.pushNamed(context, '/home'); break;
          case 2: Navigator.pushNamed(context, '/prompt'); break;
          case 3: Navigator.pushNamed(context, '/profile'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'AI 聊天'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Prompt'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '个人'),
      ],
    ),
  );
}
