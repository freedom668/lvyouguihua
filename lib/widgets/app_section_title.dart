/// 可复用的分组标题组件。
import 'package:flutter/material.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;

  const AppSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black.withValues(alpha: 0.45),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
