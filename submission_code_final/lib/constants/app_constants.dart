/// 应用常量 —— 集中管理颜色、文字、尺寸，便于统一修改和老师查阅。
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._(); // 禁止实例化

  // ─────────────────── 品牌色 ───────────────────
  static const Color primaryColor = Colors.blueAccent;
  static const Color accentColor = Colors.purpleAccent;
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, accentColor],
  );

  // ─────────────────── 背景色 ───────────────────
  static const Color scaffoldBg = Color(0xFFF7F8FA);
  static const Color cardBg = Colors.white;

  // ─────────────────── 文字色 ───────────────────
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textHint = Colors.black45;
  static const Color textWhite = Colors.white;
  static const Color textError = Colors.red;

  // ─────────────────── 圆角 ───────────────────
  static const double radiusCard = 20.0;
  static const double radiusButton = 15.0;
  static const double radiusInput = 15.0;
  static const double radiusChip = 8.0;

  // ─────────────────── 间距 ───────────────────
  static const double paddingPage = 24.0;
  static const double paddingCard = 20.0;
  static const double gapSmall = 8.0;
  static const double gapMedium = 16.0;
  static const double gapLarge = 24.0;

  // ─────────────────── 尺寸 ───────────────────
  static const double buttonHeight = 52.0;
  static const double iconSizeSmall = 22.0;
  static const double avatarRadius = 40.0;

  // ─────────────────── 文字 ───────────────────
  static const String appName = 'AI 旅游规划助手';
  static const String appSlogan = '让每一次旅行更有温度';
  static const String loginTitle = '欢迎登录';
  static const String registerTitle = '注册新账号';
  static const String loginSubtitle = '请输入账号密码开始旅程';
  static const String registerSubtitle = '创建一个新账号，开启你的旅行';
  static const String btnLogin = '立 即 登 录';
  static const String btnRegister = '立 即 注 册';
  static const String toggleToRegister = '还没有账号？去注册';
  static const String toggleToLogin = '已有账号？去登录';

  // ─────────────────── 演示模式 ───────────────────
  static const String demoUsername = 'admin';
  static const String demoPassword = '123456';
}
