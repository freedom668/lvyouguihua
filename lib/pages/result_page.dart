/// 规划结果页 —— 解析 AI 行程文本，结构化卡片展示 + 收藏功能。
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../constants/app_constants.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String _planText = '';
  String _city = '';
  int _days = 0;
  bool _isFavorited = false;
  bool _favLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      _planText = args['text'] as String? ?? '';
      _city = args['city'] as String? ?? '';
      _days = args['days'] as int? ?? 0;
    } else if (args is String) {
      _planText = args;
    }
    if (_planText.isNotEmpty) _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final saved = await LocalStorageService().isPlanSaved(_planText);
    if (mounted) setState(() => _isFavorited = saved);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorited) return;
    setState(() => _favLoading = true);
    await LocalStorageService().addSavedPlan(_planText, _city, _days);
    if (mounted) {
      setState(() { _isFavorited = true; _favLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已收藏到个人中心'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(_planText);

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1488646953014-85cb44e25828',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.blue[100], child: const Icon(Icons.image, size: 60, color: Colors.blueGrey)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)]),
                      ),
                    ),
                    Positioned(top: 44, left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back, color: Colors.white)),
                      )),
                    // 收藏星标按钮
                    Positioned(top: 44, right: 16,
                      child: GestureDetector(
                        onTap: _favLoading ? null : _toggleFavorite,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _isFavorited ? Colors.amber : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                          ),
                          child: Icon(
                            _isFavorited ? Icons.star : Icons.star_border,
                            color: _isFavorited ? Colors.white : Colors.amber, size: 26,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(bottom: 28, left: 24,
                      child: Text('AI 行程规划', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -35),
                  child: Container(width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: _isFavorited ? Colors.amber : Colors.green[400], shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: (_isFavorited ? Colors.amber : Colors.green).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(_isFavorited ? Icons.star : Icons.check_circle, color: Colors.white, size: 40)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSectionCard(sections[index]),
                    childCount: sections.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(bottom: 24, left: 24, right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/home'),
              child: Container(height: 56,
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient, borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: const Center(child: Text('返回首页', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 结构化段落模型 + 解析 + 卡片 + 内容渲染
// （与之前相同，略缩）
// ============================================================

class _Section {
  final String title, content;
  final IconData icon;
  final Color color, bgColor;
  const _Section({required this.title, required this.content, required this.icon, required this.color, required this.bgColor});
}

List<_Section> _parseSections(String rawText) {
  final sections = <_Section>[];
  final parts = rawText.split(RegExp(r'\n(?=## )'));
  final blocks = parts.length > 1 ? parts : rawText.split(RegExp(r'\n---+\n'));
  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;
    final lines = trimmed.split('\n');
    String title = '', content = trimmed;
    IconData icon = Icons.article;
    Color color = Colors.blue, bgColor = Colors.blue.withValues(alpha: 0.05);
    if (lines.isNotEmpty) {
      title = lines.first.trim().replaceAll(RegExp(r'^#+\s*'), '');
      if (title.contains('概览') || title.contains('行程概览')) { icon = Icons.info_outline; color = Colors.blue; bgColor = Colors.blue.withValues(alpha: 0.05); }
      else if (title.contains('Day') || title.contains('天')) { icon = Icons.map; color = Colors.orange; bgColor = Colors.orange.withValues(alpha: 0.05); }
      else if (title.contains('费用') || title.contains('预算')) { icon = Icons.account_balance_wallet; color = Colors.teal; bgColor = Colors.teal.withValues(alpha: 0.05); }
      else if (title.contains('贴士') || title.contains('注意')) { icon = Icons.lightbulb_outline; color = Colors.amber; bgColor = Colors.amber.withValues(alpha: 0.08); }
      else if (title.contains('推荐') || title.contains('TOP')) { icon = Icons.star; color = Colors.red; bgColor = Colors.red.withValues(alpha: 0.05); }
      else if (title.contains('天气')) { icon = Icons.cloud; color = Colors.cyan; bgColor = Colors.cyan.withValues(alpha: 0.05); }
      else if (title.contains('美食') || title.contains('餐厅')) { icon = Icons.restaurant; color = Colors.pink; bgColor = Colors.pink.withValues(alpha: 0.05); }
      else if (title.contains('住宿') || title.contains('酒店')) { icon = Icons.hotel; color = Colors.indigo; bgColor = Colors.indigo.withValues(alpha: 0.05); }
      if (lines.length > 1) content = lines.sublist(1).join('\n').trim();
    }
    sections.add(_Section(title: title, content: content, icon: icon, color: color, bgColor: bgColor));
  }
  if (sections.isEmpty) {
    sections.add(_Section(title: 'AI 行程规划', content: rawText, icon: Icons.auto_awesome, color: Colors.blue, bgColor: Colors.blue.withValues(alpha: 0.05)));
  }
  return sections;
}

Widget _buildSectionCard(_Section section) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: section.bgColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: section.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(section.icon, color: section.color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(section.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: section.color))),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(18), child: _buildContent(section.content)),
    ]),
  );
}

Widget _buildContent(String content) {
  final lines = content.split('\n');
  final widgets = <Widget>[];
  final tableRows = <List<String>>[];
  int i = 0;
  while (i < lines.length) {
    final line = lines[i].trim();
    if (line.startsWith('|') && line.endsWith('|') && line.length > 5) {
      final cells = line.substring(1, line.length - 1).split('|').map((c) => c.trim()).toList();
      if (!cells.every((c) => RegExp(r'^[-:\s]*$').hasMatch(c))) { tableRows.add(cells); }
      i++; continue;
    }
    if (tableRows.isNotEmpty) { widgets.add(_buildTable(tableRows)); tableRows.clear(); }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      widgets.add(Padding(padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('\u2022  ', style: TextStyle(fontSize: 14, color: Color(0xFF424242))),
          Expanded(child: _buildRichLine(line.replaceFirst(RegExp(r'^[-*]\s*'), ''))),
        ]),
      ));
      i++; continue;
    }
    if (line.isEmpty) { i++; continue; }
    widgets.add(Padding(padding: const EdgeInsets.only(bottom: 6), child: _buildRichLine(line)));
    i++;
  }
  if (tableRows.isNotEmpty) widgets.add(_buildTable(tableRows));
  if (widgets.isEmpty) return Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF424242), height: 1.7));
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
}

Widget _buildTable(List<List<String>> rows) {
  if (rows.isEmpty) return const SizedBox.shrink();
  final colCount = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
    clipBehavior: Clip.antiAlias,
    child: Table(
      columnWidths: {for (var c = 0; c < colCount; c++) c: const FlexColumnWidth()},
      border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey[200]!)),
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0 && rows.length > 1;
        return TableRow(
          decoration: isHeader ? BoxDecoration(color: Colors.grey[100]) : null,
          children: List.generate(colCount, (c) {
            final text = c < entry.value.length ? entry.value[c] : '';
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(text, style: TextStyle(fontSize: 13, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: isHeader ? const Color(0xFF37474F) : const Color(0xFF546E7A))));
          }),
        );
      }).toList(),
    ),
  );
}

Widget _buildRichLine(String text) {
  final boldRegex = RegExp(r'\*\*(.+?)\*\*');
  if (!boldRegex.hasMatch(text)) return Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF546E7A), height: 1.7));
  final spans = <InlineSpan>[];
  final parts = text.split(boldRegex);
  final matches = boldRegex.allMatches(text).toList();
  for (int j = 0; j < parts.length; j++) {
    spans.add(TextSpan(text: parts[j], style: const TextStyle(fontSize: 14, color: Color(0xFF546E7A), height: 1.7)));
    if (j < matches.length) spans.add(TextSpan(text: matches[j].group(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF37474F), height: 1.7)));
  }
  return RichText(text: TextSpan(children: spans));
}
