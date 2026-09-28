import '../core/theme/app_theme.dart';
import '../models/category_model.dart';

class LegalCategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onCategoryTap;
  final VoidCallback? onMoreTap;

  const LegalCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(7).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
        children: [
          ...visibleCategories.map(
            (category) => LegalCategoryTile(
              category: category,
              onTap: () => onCategoryTap(category),
            ),
          ),
          LegalCategoryTile.more(onTap: onMoreTap),
        ],
      ),
    );
  }
}

class LegalCategoryTile extends StatelessWidget {
  final CategoryModel? category;
  final VoidCallback? onTap;
  final bool isMore;

  const LegalCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  }) : isMore = false;

  const LegalCategoryTile.more({
    super.key,
    required this.onTap,
  })  : category = null,
        isMore = true;

  @override
  Widget build(BuildContext context) {
    final tileColor = isMore ? const Color(0xFFEC4899) : category!.color;
    final label = isMore ? 'More' : category!.name;
    final icon = isMore ? Icons.more_horiz_rounded : category!.iconData;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tileColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: tileColor),
          ),
          const SizedBox(height: 7),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.6,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
