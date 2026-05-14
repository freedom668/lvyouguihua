/// 模拟数据服务 —— 提供 10 条旅游数据 + AI 行程生成（纯逻辑，不涉及 UI）。
///
/// 所有方法均模拟网络延迟，便于演示和调试。
import '../models/trip_model.dart';

class MockDataService {
  /// 10 条模拟旅游数据（使用真实 Unsplash 图片链接）
  static final List<TripModel> _trips = [
    TripModel(
      id: 1,
      title: '马尔代夫 · 天堂海岛',
      city: '马尔代夫',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
      description:
          '马尔代夫是印度洋上的群岛国家，由1192个珊瑚岛组成，以其碧蓝的海水、'
          '洁白的沙滩和奢华的水上别墅闻名于世。这里是潜水爱好者的天堂，'
          '也是蜜月旅行的首选目的地。',
      days: 6,
      price: 12800,
    ),
    TripModel(
      id: 2,
      title: '京都 · 古都漫游',
      city: '京都',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e',
      description:
          '京都作为日本千年古都，保存着众多世界文化遗产。从金阁寺的闪耀到'
          '伏见稻荷大社的千本鸟居，从岚山的竹林小道到祇园的花见小路，'
          '每一处都散发着浓郁的日式美学。',
      days: 5,
      price: 8900,
    ),
    TripModel(
      id: 3,
      title: '瑞士 · 阿尔卑斯仙境',
      city: '瑞士',
      imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99',
      description:
          '瑞士坐落在阿尔卑斯山脉之中，拥有令人叹为观止的雪山、湖泊和草地。'
          '乘坐金色山口快车穿越山谷，在少女峰顶触摸云端，'
          '于卢塞恩湖畔感受宁静的午后时光。',
      days: 7,
      price: 19800,
    ),
    TripModel(
      id: 4,
      title: '曼谷 · 东南亚风情',
      city: '曼谷',
      imageUrl: 'https://images.unsplash.com/photo-1504214208698-ea1916a2195a',
      description:
          '曼谷是一座充满活力的城市，融合了古老的佛教文化与现代都市生活。'
          '从大皇宫的金碧辉煌到水上市场的热闹喧嚣，从街头小吃的味蕾冒险'
          '到暹罗商圈的时尚购物，曼谷总能带给你惊喜。',
      days: 4,
      price: 4200,
    ),
    TripModel(
      id: 5,
      title: '巴黎 · 浪漫之都',
      city: '巴黎',
      imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34',
      description:
          '巴黎是世界上最受欢迎的旅游城市之一。在埃菲尔铁塔下漫步，'
          '在卢浮宫欣赏蒙娜丽莎的微笑，在塞纳河畔享受法式下午茶，'
          '这座"光之城"的每一刻都充满浪漫与艺术气息。',
      days: 5,
      price: 15000,
    ),
    TripModel(
      id: 6,
      title: '圣托里尼 · 蓝白天堂',
      city: '圣托里尼',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592',
      description:
          '圣托里尼是爱琴海上最璀璨的明珠，标志性的蓝顶白墙建筑依山而建，'
          '俯瞰着深蓝色的爱琴海。这里有举世闻名的日落美景、'
          '古老的火山遗迹和醇厚的本地葡萄酒。',
      days: 5,
      price: 13500,
    ),
    TripModel(
      id: 7,
      title: '挪威 · 极光下的峡湾',
      city: '挪威',
      imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1',
      description:
          '挪威以壮丽的峡湾和神奇的北极光闻名。乘坐游轮穿行于松恩峡湾之间，'
          '在特罗姆瑟追寻极光的舞动，在卑尔根的五彩木屋间感受北欧文化。'
          '这里是自然爱好者的终极目的地。',
      days: 7,
      price: 22000,
    ),
    TripModel(
      id: 8,
      title: '巴厘岛 · 众神之岛',
      city: '巴厘岛',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4',
      description:
          '巴厘岛是印度尼西亚最著名的旅游胜地，以其梯田、寺庙、火山和'
          '冲浪海滩而闻名。在乌布感受瑜伽与冥想，在库塔海滩追逐海浪，'
          '在乌鲁瓦图悬崖欣赏壮丽的日落。',
      days: 6,
      price: 7600,
    ),
    TripModel(
      id: 9,
      title: '迪拜 · 奢华奇迹',
      city: '迪拜',
      imageUrl: 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2',
      description:
          '迪拜是一座从沙漠中崛起的现代化奇迹。登上世界最高的哈利法塔，'
          '在棕榈岛体验极致奢华，在黄金市场感受中东风情，'
          '每一个角落都展现着人类创造力的极限。',
      days: 4,
      price: 11000,
    ),
    TripModel(
      id: 10,
      title: '罗马 · 永恒之城',
      city: '罗马',
      imageUrl: 'https://images.unsplash.com/photo-1519451241324-20b4ea2c4220',
      description:
          '罗马是一座露天博物馆，两千年的历史在每一块石板路中流淌。'
          '从斗兽场的宏伟到许愿池的浪漫，从梵蒂冈的神圣到'
          '西班牙广场的优雅，条条大路通罗马，处处是风景。',
      days: 5,
      price: 13000,
    ),
  ];

  /// 模拟网络请求：获取首页旅游列表
  static Future<List<TripModel>> fetchHomeTrips() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.unmodifiable(_trips);
  }

  /// 模拟网络请求：根据 ID 获取行程详情
  static Future<TripModel> fetchTripDetail(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final trip = _trips.firstWhere(
      (t) => t.id == id,
      orElse: () => _trips.first,
    );
    return trip;
  }

  /// 模拟 AI 生成行程文案
  static Future<String> generateAIItinerary(String cityName) async {
    await Future.delayed(const Duration(seconds: 2));
    return '''
🎉 为您规划的「$cityName」专属行程已生成！

第一天：抵达$cityName
抵达$cityName国际机场，专车接机前往市中心酒店办理入住。下午在酒店周边自由探索，感受$cityName的城市氛围。晚上推荐前往当地著名夜市，品尝地道美食，开启美妙旅程。

第二天：文化深度游
上午参观$cityName最著名的历史文化景点，了解当地悠久的历史和独特的文化传承。建议聘请当地向导，深入探索不为人知的秘境。午餐品尝正宗本地料理。

第三天：自然风光探索
前往$cityName周边最受欢迎的自然景区。乘坐观光缆车俯瞰全城，在山顶餐厅享用午餐。下午在自然保护区徒步，感受大自然的神奇魅力。

第四天：购物与美食
在$cityName最繁华的商业街区自由购物，选购当地特色纪念品和手工艺品。中午打卡网红餐厅，下午参加一场有趣的手作体验课。

第五天：返程 / 继续探索
睡到自然醒，在酒店享用丰盛早餐。根据航班时间安排最后的活动——可以选择去一家特色咖啡馆小憩，或者前往机场，带着美好回忆踏上归途。

💡 温馨提示：
• 建议提前查看当地天气，合理搭配衣物
• 预订景点门票时选择正规渠道
• 保管好护照和贵重物品
''';
  }

  /// 搜索目的地（MCP 降级方案）
  static Future<String> searchDestinations(String keyword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final matches = _trips.where((t) =>
        t.city.contains(keyword) ||
        t.title.contains(keyword) ||
        t.description.contains(keyword)).toList();

    if (matches.isEmpty) {
      return '🔍 未找到与「$keyword」匹配的目的地，试试其他关键词吧！';
    }

    final buf = StringBuffer('🔍 为您找到 ${matches.length} 个目的地：\n');
    for (final t in matches) {
      buf.writeln();
      buf.writeln('📍 ${t.title}');
      buf.writeln('   ${t.description.substring(0, t.description.length.clamp(0, 40))}...');
      buf.writeln('   游玩天数: ${t.days}天 | 参考价: ¥${t.price.toInt()}');
    }
    return buf.toString();
  }

  /// 计算预算（MCP 降级方案）
  static String calculateBudget(int days, String style) {
    final multipliers = {'经济': 0.5, '标准': 1.0, '奢华': 2.5};
    final multiplier = multipliers[style] ?? 1.0;
    final base = 800.0 * multiplier;
    final flight = base * 2;
    final hotel = base * days * 0.4;
    final food = base * days * 0.3;
    final transport = base * days * 0.1;
    final tickets = base * days * 0.15;
    final other = base * days * 0.05;
    final total = flight + hotel + food + transport + tickets + other;

    return '💰 ${days}天 ${style}档 预算明细\n\n'
        '✈️  往返机票：¥${flight.toStringAsFixed(0)}\n'
        '🏨 酒店住宿：¥${hotel.toStringAsFixed(0)}（${days}晚）\n'
        '🍽️  餐饮费用：¥${food.toStringAsFixed(0)}\n'
        '🚗 当地交通：¥${transport.toStringAsFixed(0)}\n'
        '🎫 门票/活动：¥${tickets.toStringAsFixed(0)}\n'
        '📦 其他杂费：¥${other.toStringAsFixed(0)}\n'
        '${"—" * 25}\n'
        '💎 预估总计：¥${total.toStringAsFixed(0)}（约 ¥${(total / days).toStringAsFixed(0)}/天）';
  }
}
