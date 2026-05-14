/// 主页 —— 沉浸式 Hero + 搜索栏 + 分类标签 + 旅游卡片 + Drawer + SQLite 收藏。
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/mock_data_service.dart';
import '../services/db_service.dart';
import '../utils/ui_helper.dart';
import '../constants/app_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<TripModel> _trips = [];
  bool _isLoading = true;
  final Set<int> _favoriteIds = {};

  final _categories = [
    {'icon': Icons.beach_access, 'label': '海岛度假', 'active': true},
    {'icon': Icons.temple_buddhist, 'label': '文化古迹', 'active': false},
    {'icon': Icons.restaurant, 'label': '美食之旅', 'active': false},
    {'icon': Icons.terrain, 'label': '户外探险', 'active': false},
    {'icon': Icons.favorite, 'label': '蜜月浪漫', 'active': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await MockDataService.fetchHomeTrips();
      final favorites = await DbService.queryFavorites();
      if (mounted) {
        setState(() {
          _trips = trips;
          _favoriteIds.addAll(favorites.map((f) => f['id'] as int));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showToast(context, '网络开小差了，请稍后重试');
      }
    }
  }

  Future<void> _toggleFavorite(TripModel trip) async {
    final isFav = _favoriteIds.contains(trip.id);
    await DbService.toggleFavorite(trip.id, !isFav);
    if (isFav) {
      await DbService.deleteTrip(trip.id);
    } else {
      await DbService.insertOrUpdate(trip.toMap());
    }
    setState(() {
      isFav ? _favoriteIds.remove(trip.id) : _favoriteIds.add(trip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(context),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildSectionHeader('热门目的地', '共 ${_trips.length} 条精选路线'),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildTripCard(_trips[i]),
                  childCount: _trips.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/prompt'),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  // ──── Drawer ────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(height: 160, width: double.infinity,
            decoration: const BoxDecoration(gradient: AppConstants.primaryGradient),
            child: const Padding(padding: EdgeInsets.only(left: 20, bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                SizedBox(height: 10),
                Text('旅行达人', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('探索世界，现在出发', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ])),
          ),
          const SizedBox(height: 8),
          _drawerItem(Icons.home, '首页', () => Navigator.pop(context)),
          _drawerItem(Icons.auto_awesome, 'AI Prompt 输入', () { Navigator.pop(context); Navigator.pushNamed(context, '/prompt'); }),
          _drawerItem(Icons.build_outlined, 'MCP 工具配置', () { Navigator.pop(context); Navigator.pushNamed(context, '/tools'); }),
          _drawerItem(Icons.settings_outlined, '应用设置', () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); }),
          const Spacer(), const Divider(),
          _drawerItem(Icons.person_outline, '个人中心', () { Navigator.pop(context); Navigator.pushNamed(context, '/profile'); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: AppConstants.textSecondary), title: Text(title, style: const TextStyle(fontSize: 15, color: AppConstants.textPrimary)), onTap: onTap, dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
  }

  // ──── Hero 头部 ────
  Widget _buildHeroHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300,
        child: Stack(fit: StackFit.expand, children: [
          // 背景图
          Image.network(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              decoration: const BoxDecoration(gradient: AppConstants.primaryGradient),
              child: const Icon(Icons.flight_takeoff, size: 80, color: Colors.white30),
            ),
          ),
          // 顶部暗色渐变
          Positioned(top: 0, left: 0, right: 0, height: 100,
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
            ))),
          ),
          // 底部渐变
          Positioned(bottom: 0, left: 0, right: 0, height: 150,
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ))),
          ),
          // 顶部按钮
          Positioned(top: 44, left: 12,
            child: _iconBtn(Icons.menu, () => _scaffoldKey.currentState!.openDrawer())),
          Positioned(top: 44, right: 12,
            child: _iconBtn(Icons.person_outline, () => Navigator.pushNamed(context, '/profile'))),
          // 标题
          Positioned(bottom: 60, left: 24, right: 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: const [
              Text('发现美好旅程', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black38, blurRadius: 10)])),
              SizedBox(height: 8),
              Text('AI 智能规划 · 让你的每一次旅行都值得回忆', style: TextStyle(fontSize: 15, color: Colors.white70, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
            ]),
          ),
          // 底部统计数据
          Positioned(bottom: 8, left: 24, right: 24,
            child: Row(children: [
              _heroStat('10+', '精选目的地'),
              _heroStat('6', 'AI 工具'),
              _heroStat('实时', '天气查询'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Colors.white, size: 22)),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ]),
    );
  }

  // ──── 搜索栏 ────
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 48,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Icon(Icons.search, color: Colors.grey[400]), const SizedBox(width: 10),
          Text('搜索目的地、景点、美食...', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppConstants.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('AI 搜索', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
          ),
        ]),
      ),
    );
  }

  // ──── 分类标签 ────
  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: _categories.map((c) {
            final active = c['active'] as bool;
            return GestureDetector(
              onTap: () => setState(() {
                for (var cat in _categories) cat['active'] = false;
                c['active'] = true;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppConstants.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active ? [BoxShadow(color: AppConstants.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                  border: active ? null : Border.all(color: Colors.grey[200]!),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(c['icon'] as IconData, size: 16, color: active ? Colors.white : Colors.grey[600]!),
                  const SizedBox(width: 6),
                  Text(c['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey[700]!)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──── 分区标题 ────
  Widget _buildSectionHeader(String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          Container(width: 4, height: 22, decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const Spacer(),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary)),
        ]),
      ),
    );
  }

  // ──── 旅游卡片 ────
  Widget _buildTripCard(TripModel trip) {
    final isFav = _favoriteIds.contains(trip.id);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: trip.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 图片区
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            child: Stack(children: [
              Image.network(trip.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))),
              // 图片上的渐变和标签
              Positioned(bottom: 0, left: 0, right: 0, height: 60,
                child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                ))),
              ),
              Positioned(bottom: 10, left: 14,
                child: Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                    child: Text('${trip.days}天', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
                  ),
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                    child: Text(trip.city, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                  ),
                ]),
              ),
              // 收藏按钮
              Positioned(top: 10, right: 10,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(trip),
                  child: Container(width: 34, height: 34,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                    child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey[600], size: 18),
                  ),
                ),
              ),
            ]),
          ),
          // 信息区
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trip.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
              const SizedBox(height: 6),
              Text(trip.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.attach_money, size: 14, color: Colors.orange[700]),
                Text('¥${trip.price.toInt()} 起', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: AppConstants.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Text('查看详情', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
