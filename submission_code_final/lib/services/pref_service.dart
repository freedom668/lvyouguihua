/// Shared Preferences 存储服务（底层封装）—— 供 LocalStorageService 调用。
import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyToken = 'token';

  /// 获取 SharedPreferences 实例
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ========== 登录状态 ==========

  /// 保存登录状态
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  /// 获取登录状态
  static Future<bool> getLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ========== 用户名 ==========

  /// 保存用户名
  static Future<void> setUsername(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUsername, value);
  }

  /// 获取用户名
  static Future<String> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUsername) ?? '';
  }

  // ========== Token（预留，用于 MCP 接口鉴权） ==========

  /// 保存 MCP Token
  static Future<void> setToken(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, value);
  }

  /// 获取 MCP Token
  static Future<String> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyToken) ?? '';
  }

  // ========== 清除所有数据（退出登录） ==========

  /// 清除所有偏好设置
  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
