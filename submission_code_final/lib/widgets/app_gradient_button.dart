/// 可复用的渐变按钮组件。
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.height = AppConstants.buttonHeight,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: AppConstants.primaryGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textWhite,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
