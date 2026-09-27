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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.category.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: _refresh,
        child: FutureBuilder<List<CaseModel>>(
          future: _casesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'Unable to load this category right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
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
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
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
