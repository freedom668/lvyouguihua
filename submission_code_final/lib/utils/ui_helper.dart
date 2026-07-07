/// UI 工具类 —— 全局加载遮罩 / Toast 反馈
///
/// 避免在各页面中重复编写 CircularProgressIndicator 和 SnackBar，
/// 提供统一、可复用的静态方法。
import 'package:flutter/material.dart';

class UIHelper {
  /// 显示全屏半透明加载遮罩（禁止用户操作底层页面）
  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 18),
                  Text('加载中...', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 关闭 showLoading 打开的遮罩层
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 在屏幕底部显示圆角 SnackBar（居中文字，深灰背景，2 秒自动消失）
  static void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        elevation: 4,
      ),
    );
  }
}
