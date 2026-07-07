/// MCP 配置管理 —— 从 SharedPreferences 读取服务器地址和 API Key。
///
/// 供 McpClientService 和所有需要调用 MCP 的页面使用。
import 'local_storage_service.dart';

class McpConfig {
  const McpConfig._();

  static String _cachedUrl = '';
  static String? _cachedApiKey;

  /// 获取 MCP 服务端地址，未配置则返回默认值
  static Future<String> getServerUrl() async {
    if (_cachedUrl.isEmpty) {
      _cachedUrl = await LocalStorageService().getMcpServerUrl(); // 默认 http://10.0.2.2:9000
    }
    return _cachedUrl;
  }

  /// 获取 API Key，未配置返回 null
  static Future<String?> getApiKey() async {
    _cachedApiKey ??= await LocalStorageService().getMcpApiKey();
    return _cachedApiKey;
  }

  /// 清除缓存（下次读取时重新从 SharedPreferences 加载）
  static void clearCache() {
    _cachedUrl = '';
    _cachedApiKey = null;
  }
}
