/// 景点详情页 —— SliverAppBar 视差大图 + 动态内容 + AI 行程生成 + SQLite 收藏。
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/mock_data_service.dart';
import '../services/db_service.dart';
import '../utils/ui_helper.dart';
import '../constants/app_constants.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  TripModel? _trip;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final raw = ModalRoute.of(context)!.settings.arguments;
    final tripId = raw is int ? raw : (raw as Map)['id'] as int? ?? 0;
    _loadDetail(tripId);
  }

  Future<void> _loadDetail(int id) async {
    UIHelper.showLoading(context);
    try {
      final trip = await MockDataService.fetchTripDetail(id);
      final fav = await DbService.isFavorite(id);
      if (mounted) {
        setState(() {
          _trip = trip;
          _isFavorite = fav;
          _isLoading = false;
        });
        UIHelper.hideLoading(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.hideLoading(context);
        UIHelper.showToast(context, '网络开小差了，请稍后重试');
      }
    }
  }

  /// 切换收藏状态，写入 SQLite
  Future<void> _toggleFavorite() async {
    if (_trip == null) return;
    await DbService.toggleFavorite(_trip!.id, !_isFavorite);
    if (_isFavorite) {
      await DbService.deleteTrip(_trip!.id);
    } else {
      await DbService.insertOrUpdate(_trip!.toMap());
    }
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    UIHelper.showToast(context, _isFavorite ? '已收藏' : '已取消收藏');
  }

  /// 调用 AI 生成行程文案
  void _generateAIItinerary() {
    if (_trip == null) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(), SizedBox(height: 20),
          Text('AI 正在为您规划行程...', style: TextStyle(fontSize: 15)),
        ]),
      ),
    );
    MockDataService.generateAIItinerary(_trip!.city).then((text) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushNamed(context, '/result', arguments: text);
    }).catchError((error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UIHelper.showToast(context, '生成失败，请稍后重试');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final trip = _trip!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260, pinned: true, stretch: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(fit: StackFit.expand, children: [
                Image.network(trip.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.green[100], child: const Icon(Icons.image, size: 60, color: Colors.blueGrey))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              ]),
            ),
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                onPressed: _toggleFavorite,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
                const SizedBox(height: AppConstants.gapSmall),
                Row(children: [
                  _buildInfoChip(Icons.location_on, trip.city), const SizedBox(width: 12),
                  _buildInfoChip(Icons.calendar_today, '${trip.days}天'), const SizedBox(width: 12),
                  _buildInfoChip(Icons.attach_money, '¥${trip.price.toInt()}'),
                ]),
                const SizedBox(height: 12),
                Text(trip.description, style: const TextStyle(fontSize: 14, color: AppConstants.textSecondary, height: 1.6)),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: GestureDetector(
                onTap: _generateAIItinerary,
                child: Container(
                  height: AppConstants.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: const Center(
                    child: Text('🤖  AI 生成专属行程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(AppConstants.radiusChip)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppConstants.textSecondary), const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
      ]),
    );
  }
}
