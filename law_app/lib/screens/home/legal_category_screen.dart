import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/case_model.dart';
import '../../repositories/case_repository.dart';
import '../../widgets/case_card.dart';
import '../cases/case_detail_screen.dart';

class LegalCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const LegalCategoryScreen({super.key, required this.category});

  @override
  State<LegalCategoryScreen> createState() => _LegalCategoryScreenState();
}

class _LegalCategoryScreenState extends State<LegalCategoryScreen> {
  final CaseRepository _caseRepository = CaseRepository();
  late Future<List<CaseModel>> _casesFuture;

  @override
  void initState() {
    super.initState();
    _casesFuture = _loadCases();
  }

  Future<List<CaseModel>> _loadCases() async {
    final result = await _caseRepository.getCasesByCategory(categorySlug: widget.category.slug, limit: 50);
    return result.items;
  }

  Future<void> _refresh() async {
    setState(() {
      _casesFuture = _loadCases();
    });
    await _casesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: textPrimary,
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        title: Text(
          widget.category.name,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      body: RefreshIndicator(
        color: primaryOrGold,
        onRefresh: _refresh,
        child: FutureBuilder<List<CaseModel>>(
          future: _casesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryOrGold));
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load this category right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondaryColor(context), fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }

            final cases = snapshot.data ?? [];
            if (cases.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(widget.category.iconData, color: widget.category.color, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'No ${widget.category.name} cases available yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondaryColor(context), fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final caseItem = cases[index];
                return CaseCard(
                  caseItem: caseItem,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseItem.id)),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
