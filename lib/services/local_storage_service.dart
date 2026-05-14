/// 本地存储服务 —— 单例模式封装 SharedPreferences，管理用户登录态、用户名、主题和默认城市。
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  static const _keyUsername = 'username';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyDarkMode = 'dark_mode';
  static const _keyCity = 'default_city';
  static const _keyMcpUrl = 'mcp_server_url';
  static const _keyMcpKey = 'mcp_api_key';
  static const _keyAvatar = 'avatar_url';
  static const _keySignature = 'signature';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ========== 用户名 ==========

  /// 保存用户名（覆盖，不改变登录态）
  Future<void> setUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUsername, username);
  }

  /// 保存用户名并标记已登录
  Future<void> saveUserInfo(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUsername, username);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// 获取已保存的用户名，未保存返回 null
  Future<String?> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUsername);
  }

  // ========== 深色模式 ==========

  /// 保存深色模式开关状态
  Future<void> setDarkMode(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyDarkMode, value);
  }

  /// 读取深色模式开关状态，默认 false
  Future<bool> getDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // ========== 默认城市 ==========

  /// 保存默认启动城市
  Future<void> setDefaultCity(String city) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCity, city);
  }

  /// 读取默认启动城市，未设置返回 null
  Future<String?> getDefaultCity() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCity);
  }

  // ========== 清除用户信息 ==========

  /// 清除登录态和用户名（保留主题和城市设置）
  Future<void> clearUserInfo() async {
    final prefs = await _prefs;
    await prefs.remove(_keyUsername);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  // ========== MCP 服务器配置 ==========

  Future<void> setMcpServerUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_keyMcpUrl, url);
  }

  Future<String> getMcpServerUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_keyMcpUrl) ?? 'http://localhost:9000';
  }

  Future<void> setMcpApiKey(String key) async {
    final prefs = await _prefs;
    await prefs.setString(_keyMcpKey, key);
  }

  Future<String?> getMcpApiKey() async {
    final prefs = await _prefs;
    return prefs.getString(_keyMcpKey);
  }

  // ========== 头像与签名 ==========

  Future<void> setAvatar(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAvatar, url);
  }

  Future<String> getAvatar() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAvatar) ?? '';
  }

  Future<void> setSignature(String sig) async {
    final prefs = await _prefs;
    await prefs.setString(_keySignature, sig);
  }

  Future<String> getSignature() async {
    final prefs = await _prefs;
    return prefs.getString(_keySignature) ?? '';
  }

    // ========== 已保存的 AI 计划（JSON 序列化，全平台可用） ==========

  static const _keyPlans = 'saved_plans';

  Future<List<Map<String, dynamic>>> getSavedPlans() async {
    final prefs = await _prefs;
    final json = prefs.getString(_keyPlans);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addSavedPlan(String planText, String city, int days) async {
    final plans = await getSavedPlans();
    plans.removeWhere((p) => p['text'] == planText);
    plans.insert(0, {
      'text': planText,
      'city': city,
      'days': days,
      'time': DateTime.now().toIso8601String(),
    });
    final prefs = await _prefs;
    await prefs.setString(_keyPlans, jsonEncode(plans));
  }

  Future<void> removeSavedPlan(String planText) async {
    final plans = await getSavedPlans();
    plans.removeWhere((p) => p['text'] == planText);
    final prefs = await _prefs;
    await prefs.setString(_keyPlans, jsonEncode(plans));
  }

  Future<bool> isPlanSaved(String planText) async {
    final plans = await getSavedPlans();
    return plans.any((p) => p['text'] == planText);
  }

  Future<int> getSavedPlanCount() async {
    final plans = await getSavedPlans();
    return plans.length;
  }

  /// 清除缓存数据（模拟）
  Future<void> clearCache() async {
    // 实际可扩展：清理文件缓存、图片缓存等
    final prefs = await _prefs;
    // 保留用户名和主题，仅清除非核心字段
    await prefs.remove('cache_timestamp');
    await prefs.remove('cache_data');
  }
}
