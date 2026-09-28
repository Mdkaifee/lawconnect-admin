import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/act_model.dart';

class ActCard extends StatelessWidget {
  final ActModel act;
  final VoidCallback onTap;

  const ActCard({super.key, required this.act, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return Card(
      elevation: 0,
      color: AppTheme.cardColor(context),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.borderColor(context), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.goldAccent.withValues(alpha: 0.15)
                      : AppColors.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: primaryOrGold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: act.type == 'Central'
                                ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.withValues(alpha: 0.1))
                                : (isDark ? Colors.purple.shade900.withValues(alpha: 0.4) : Colors.purple.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            act.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: act.type == 'Central'
                                  ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade800)
                                  : (isDark ? Colors.purpleAccent : Colors.purple.shade800),
                            ),
                          ),
                        ),
                        if (act.year != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${act.year}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (act.description != null && act.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        act.description!,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Text(
                      '${act.sectionsCount} Sec',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryOrGold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

