/// 个人中心页 —— 渐变头部 + 收藏列表填满屏幕。
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
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
  List<Map<String, dynamic>> _favoriteTrips = [];
  List<Map<String, dynamic>> _savedPlans = [];
  final _localStorage = LocalStorageService();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final name = await _localStorage.getUsername();
    final sig = await _localStorage.getSignature();
    final avt = await _localStorage.getAvatar();
    final favs = await DbService.queryFavorites();
    final plans = await LocalStorageService().getSavedPlans();
    if (mounted) setState(() {
      if (name != null && name.isNotEmpty) _username = name;
      if (sig.isNotEmpty) _signature = sig;
      if (avt.isNotEmpty) _avatarUrl = avt;
      _favoriteTrips = favs;
      _savedPlans = plans;
    });
  }

  void _handleLogout() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('确认退出'), content: const Text('退出后需要重新登录，确定要退出吗？'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      TextButton(onPressed: () { Navigator.pop(ctx); _localStorage.clearUserInfo(); Navigator.pushReplacementNamed(context, '/login'); },
          child: const Text('退出', style: TextStyle(color: Colors.red))),
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final total = _favoriteTrips.length + _savedPlans.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))]),
        child: BottomNavigationBar(
          currentIndex: 3,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          onTap: (i) {
            switch (i) {
              case 0: Navigator.popUntil(context, ModalRoute.withName('/home')); break;
              case 1: Navigator.pushNamed(context, '/chat'); break;
              case 2: Navigator.pushNamed(context, '/prompt'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'AI 聊天'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Prompt'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '个人'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // ── 渐变头部 ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blueAccent, Colors.purpleAccent]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Column(children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22), onPressed: () => Navigator.pushNamed(context, '/settings')),
              ]),
              Row(children: [
                const SizedBox(width: 8),
                CircleAvatar(radius: 30, backgroundColor: Colors.white24, backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                    child: _avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(_signature, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                ])),
                OutlinedButton(
                  onPressed: () async { final r = await Navigator.pushNamed(context, '/edit_profile'); if (r == true) _loadData(); },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  child: const Text('编辑', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
                const SizedBox(width: 4),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat('${_favoriteTrips.length}', '目的地')),
                Container(width: 1, height: 24, color: Colors.white24),
                Expanded(child: _stat('${_savedPlans.length}', 'AI 计划')),
              ]),
            ]),
          ),

          // ── 标题栏 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text('我的收藏 ($total)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
            ]),
          ),

          // ── 列表（Expanded 填满剩余空间） ──
          Expanded(
            child: total == 0
                ? Center(child: Text('暂无收藏\n去首页收藏目的地或 AI 计划吧', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[400])))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _favoriteTrips.length + _savedPlans.length,
                    itemBuilder: (_, i) {
                      if (i < _favoriteTrips.length) return _buildFavTripCard(_favoriteTrips[i]);
                      return _buildPlanCard(_savedPlans[i - _favoriteTrips.length]);
                    },
                  ),
          ),

          // ── 退出 ──
          Center(child: TextButton(onPressed: _handleLogout,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
            child: const Text('退出登录', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500)))),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _stat(String count, String label) => Column(children: [
    Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
  ]);

  Widget _buildPlanCard(Map<String, dynamic> p) {
    final text = p['text'] as String? ?? '';
    final city = p['city'] as String? ?? '';
    final days = p['days'] is int ? p['days'] as int : int.tryParse(p['days'].toString()) ?? 0;
    final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'AI 行程计划');
    final t = firstLine.replaceAll(RegExp(r'[#*🎉🌟]'), '').trim();
    return Dismissible(
      key: Key('plan_${p.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _localStorage.removeSavedPlan(text);
        _loadData();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 17)),
          title: Text(t.length > 22 ? '${t.substring(0, 22)}...' : t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          subtitle: Text('$city · ${days}天', style: const TextStyle(fontSize: 12, color: Colors.black45)),
          trailing: GestureDetector(
            onTap: () async { await _localStorage.removeSavedPlan(text); _loadData(); },
            child: const Icon(Icons.close, color: Colors.black26, size: 18),
          ),
          onTap: () => Navigator.pushNamed(context, '/result', arguments: {'text': text, 'city': city, 'days': days}),
        ),
      ),
    );
  }

  Widget _buildFavTripCard(Map<String, dynamic> d) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: ListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: ClipRRect(borderRadius: BorderRadius.circular(6),
        child: Image.network(d['image_url'] as String? ?? '', width: 38, height: 38, fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(width: 38, height: 38, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey, size: 16)))),
      title: Text(d['title'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Text('${d['city'] ?? ''} · ${d['days'] ?? 0}天', style: const TextStyle(fontSize: 12, color: Colors.black45)),
      trailing: GestureDetector(
        onTap: () async { await DbService.toggleFavorite(d['id'] as int, false); _loadData(); },
        child: const Icon(Icons.close, color: Colors.black38, size: 18),
      ),
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: d['id'] as int),
    ),
  );
}
