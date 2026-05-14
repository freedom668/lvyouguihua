/// 可复用的功能卡片组件 —— 图标 + 标题 + 副标题 + 可选尾部组件。
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppFeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: AppConstants.iconSizeSmall),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppConstants.textHint)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
