import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ScalesLogo extends StatelessWidget {
  final double size;
  final bool withBackground;

  const ScalesLogo({
    super.key,
    this.size = 64,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!withBackground) {
      return Icon(Icons.balance, size: size, color: AppColors.accentGold);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardNavy,
        border: Border.all(color: AppColors.accentGold.withAlpha(120), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withAlpha(50),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.balance,
          size: size * 0.55,
          color: AppColors.accentGold,
        ),
      ),
    );
  }
}
