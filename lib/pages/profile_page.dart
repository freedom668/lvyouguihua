/// 个人中心页 —— 沉浸式渐变头部 + 悬浮用户卡片 + 收藏展示 + 退出登录。
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/db_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '旅行达人';
  String _signature = '身体和灵魂，总有一个在路上';
  String _avatarUrl = '';
  int _favoriteCount = 0;
  List<Map<String, dynamic>> _favoriteTrips = [];
  List<Map<String, dynamic>> _savedPlans = [];
  final _localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await _localStorage.getUsername();
    final sig = await _localStorage.getSignature();
    final avt = await _localStorage.getAvatar();
    final count = await DbService.getFavoriteCount();
    final favs = await DbService.queryFavorites();
    final plans = await LocalStorageService().getSavedPlans();

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _username = name;
        if (sig.isNotEmpty) _signature = sig;
        if (avt.isNotEmpty) _avatarUrl = avt;
        _favoriteCount = count + plans.length;
        _favoriteTrips = favs;
        _savedPlans = plans;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认退出'),
        content: const Text('退出后需要重新登录，确定要退出吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _localStorage.clearUserInfo();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final gradientHeight = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Container(
            height: gradientHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.blueAccent, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
            ),
          ),

          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: gradientHeight * 0.65),

                // 悬浮用户信息卡片
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 40, backgroundColor: Colors.grey[200],
                          backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                          child: _avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(_signature, style: const TextStyle(fontSize: 13, color: Colors.black45)),
                          ]),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, '/edit_profile');
                            if (result == true) _loadData();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('编辑资料', style: TextStyle(fontSize: 12)),
                        ),
                      ]),
                      const Divider(height: 28),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _StatItem(count: '$_favoriteCount', label: '收藏'),
                        const _StatItem(count: '8', label: '足迹'),
                        const _StatItem(count: '105', label: '粉丝'),
                      ]),
                    ]),
                  ),
                ),

                const SizedBox(height: 4),

                _buildSectionTitle('工具与服务'),
                _buildFeatureCard(Icons.build_outlined, Colors.blue, 'AI 工具配置', '管理 AI 辅助工具开关',
                    onTap: () => Navigator.pushNamed(context, '/tools')),
                _buildFeatureCard(Icons.settings_outlined, Colors.teal, '应用设置', '深色模式、默认城市等',
                    onTap: () => Navigator.pushNamed(context, '/settings')),

                const SizedBox(height: 8),

                _buildSectionTitle('我的服务'),
                _buildFeatureCard(Icons.map_outlined, Colors.blue, '我的行程', '查看 AI 规划的旅行路线'),
                _buildFeatureCard(Icons.notifications_outlined, Colors.orange, '消息通知', '行程提醒与系统消息',
                    trailing: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                _buildFeatureCard(Icons.help_outline, Colors.green, '帮助与反馈', '常见问题与意见反馈'),

                // ── 已收藏的行程 ──
                if (_favoriteTrips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionTitle('我的收藏 (${_favoriteTrips.length})'),
                  ..._favoriteTrips.map((trip) => _buildFavTripCard(trip)),
                ],

                // ── 已收藏的 AI 计划 ──
                const SizedBox(height: 8),
                _buildSectionTitle('AI 生成计划 (${_savedPlans.length})'),
                if (_savedPlans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('暂无收藏的计划，去生成一个吧', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  )
                else
                  ..._savedPlans.map((plan) => _buildPlanCard(plan)),

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _handleLogout,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                    child: const Text('退出登录', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // 返回按钮（置于 ListView 上层）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, left: 8,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 设置入口（置于 ListView 上层）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, right: 16,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
          color: Colors.black.withValues(alpha: 0.45), letterSpacing: 1.0)),
    );
  }

  Widget _buildFeatureCard(IconData icon, Color iconColor, String title, String subtitle,
      {Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(width: 42, height: 42,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 22)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final text = plan['text'] as String? ?? '';
    final city = plan['city'] as String? ?? '';
    final days = (plan['days'] is int) ? plan['days'] as int : int.tryParse(plan['days'].toString()) ?? 0;
    // 提取第一行作为标题
    final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'AI 行程计划');
    final title = firstLine.replaceAll(RegExp(r'[#*🎉🌟]'), '').trim();
    final displayTitle = title.length > 25 ? '${title.substring(0, 25)}...' : title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 22)),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text('$city · ${days}天', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () => Navigator.pushNamed(context, '/result', arguments: {'text': text, 'city': city, 'days': days}),
      ),
    );
  }

  Widget _buildFavTripCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(data['image_url'] as String? ?? '', width: 50, height: 50, fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))),
        ),
        title: Text(data['title'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text('${data['city'] ?? ''} · ${data['days'] ?? 0}天', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: Icon(Icons.favorite, color: Colors.red[300], size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: data['id'] as int),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count, label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
    ]);
  }
}
