import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LawCategory {
  final String title;
  final String slug;
  final IconData icon;
  final Color color;

  const LawCategory({
    required this.title,
    required this.slug,
    required this.icon,
    required this.color,
  });
}

const List<LawCategory> categoriesList = [
  LawCategory(
    title: 'Constitution',
    slug: 'constitution',
    icon: Icons.account_balance_outlined,
    color: AppColors.catConstitution,
  ),
  LawCategory(
    title: 'Criminal Law',
    slug: 'criminal-law',
    icon: Icons.gavel_outlined,
    color: AppColors.catCriminal,
  ),
  LawCategory(
    title: 'Contract',
    slug: 'contract',
    icon: Icons.description_outlined,
    color: AppColors.catContract,
  ),
  LawCategory(
    title: 'Torts',
    slug: 'torts',
    icon: Icons.balance_outlined,
    color: AppColors.catTorts,
  ),
  LawCategory(
    title: 'Family Law',
    slug: 'family-law',
    icon: Icons.family_restroom_outlined,
    color: AppColors.catFamily,
  ),
  LawCategory(
    title: 'Labour Law',
    slug: 'labour-law',
    icon: Icons.work_outline_rounded,
    color: AppColors.catLabour,
  ),
  LawCategory(
    title: 'Environment',
    slug: 'environment',
    icon: Icons.eco_outlined,
    color: AppColors.catEnvironment,
  ),
  LawCategory(
    title: 'More',
    slug: 'more',
    icon: Icons.grid_view_rounded,
    color: AppColors.catMore,
  ),
];

class CategoryGrid extends StatelessWidget {
  final Function(LawCategory) onCategorySelected;

  const CategoryGrid({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        final cat = categoriesList[index];
        return GestureDetector(
          onTap: () => onCategorySelected(cat),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cat.color.withAlpha(22),
                  shape: BoxShape.circle,
                  border: Border.all(color: cat.color.withAlpha(60), width: 1.2),
                ),
                child: Center(
                  child: Icon(cat.icon, color: cat.color, size: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
