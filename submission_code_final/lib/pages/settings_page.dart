/// 设置页 —— 深色模式切换 / 清除缓存 / 默认城市选择 / 退出登录。
///
/// 使用 SharedPreferences 持久化各项设置。
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/mcp_config.dart';
import '../utils/ui_helper.dart';
import '../constants/app_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _localStorage = LocalStorageService();

  bool _darkMode = false;
  String _selectedCity = '北京';
  bool _isLoaded = false;

  // MCP 配置
  String _mcpUrl = '';

  final _cities = ['北京', '上海', '广州', '三亚', '成都', '杭州'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// 从本地存储加载当前设置
  Future<void> _loadPreferences() async {
    final isDark = await _localStorage.getDarkMode();
    final city = await _localStorage.getDefaultCity();
    final mcpUrl = await _localStorage.getMcpServerUrl();
    if (mounted) {
      setState(() {
        _darkMode = isDark;
        _selectedCity = city ?? '北京';
        _mcpUrl = mcpUrl;
        _isLoaded = true;
      });
    }
  }

  /// 切换深色模式并持久化
  void _toggleDarkMode(bool value) async {
    setState(() => _darkMode = value);
    await _localStorage.setDarkMode(value);
    if (mounted) {
      UIHelper.showToast(context, '主题将在下次启动时应用');
    }
  }

  /// 保存默认城市并持久化
  void _saveCity(String city) async {
    setState(() => _selectedCity = city);
    await _localStorage.setDefaultCity(city);
    if (mounted) {
      UIHelper.showToast(context, '默认城市已设为 $city');
    }
  }

  /// 清除缓存（确认弹窗）
  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除缓存'),
        content: const Text('确认清除应用缓存数据？\n（不会清除登录状态和个人设置）'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _localStorage.clearCache();
              if (mounted) UIHelper.showToast(context, '缓存已清除');
            },
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ========== 渐变 Header ==========
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: AppConstants.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 8, left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.settings, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 14),
                          const Text('应用设置',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('个性化你的旅行体验',
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ========== 外观 ==========
          SliverToBoxAdapter(child: _buildSectionTitle('外观')),
          SliverToBoxAdapter(
            child: _buildCard(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                secondary: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_outlined, color: Colors.indigo, size: 22),
                ),
                title: const Text('深色模式',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                subtitle: const Text('切换深色/浅色主题',
                    style: TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                value: _darkMode,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: _toggleDarkMode,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ========== 默认城市 ==========
          SliverToBoxAdapter(child: _buildSectionTitle('旅行偏好')),
          SliverToBoxAdapter(
            child: _buildCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city, color: Colors.teal, size: 22),
                ),
                title: const Text('默认启动城市',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                subtitle: const Text('每次启动默认显示该城市行程',
                    style: TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 14, color: AppConstants.textPrimary, fontWeight: FontWeight.w500),
                    items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (city) {
                      if (city != null) _saveCity(city);
                    },
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ========== MCP 服务器配置 ==========
          SliverToBoxAdapter(child: _buildSectionTitle('Agent 后端')),
          SliverToBoxAdapter(
            child: _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.dns_outlined,
                    iconColor: Colors.deepPurple,
                    title: '服务器地址',
                    subtitle: _mcpUrl.isEmpty ? '点击设置 Agent 后端地址（默认 :9000）' : _mcpUrl,
                    onTap: () => _showInputDialog(
                      title: 'MCP 服务器地址',
                      hint: 'http://10.0.2.2:9000',
                      controller: TextEditingController(text: _mcpUrl),
                      onSave: (value) async {
                        await _localStorage.setMcpServerUrl(value);
                        McpConfig.clearCache();
                        setState(() => _mcpUrl = value);
                        if (mounted) UIHelper.showToast(context, 'MCP 地址已保存');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ========== 数据管理 ==========
          SliverToBoxAdapter(child: _buildSectionTitle('数据管理')),
          SliverToBoxAdapter(
            child: _buildCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                ),
                title: const Text('清除缓存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: const Text('清除临时数据，释放存储空间',
                    style: TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                onTap: _confirmClearCache,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ========== 关于 ==========
          SliverToBoxAdapter(child: _buildSectionTitle('关于')),
          SliverToBoxAdapter(
            child: _buildCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.blue, size: 22),
                ),
                title: const Text('版本信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                subtitle: const Text('v1.0.0 · AI 旅游规划助手',
                    style: TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 24, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0),
      ),
    );
  }

  /// 弹出文本输入对话框
  void _showInputDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
    required void Function(String value) onSave,
    bool isPassword = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
