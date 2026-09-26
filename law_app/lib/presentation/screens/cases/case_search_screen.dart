import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/case_model.dart';
import '../../../logic/blocs/case/case_bloc.dart';
import '../../../logic/blocs/case/case_event.dart';
import '../../../logic/blocs/case/case_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import 'case_detail_screen.dart';

class CaseSearchScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const CaseSearchScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<CaseSearchScreen> createState() => _CaseSearchScreenState();
}

class _CaseSearchScreenState extends State<CaseSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCourt = 'All';
  final List<String> _courts = ['All', 'Supreme Court', 'High Court', 'District Court'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _triggerSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<CaseBloc>().add(
          FetchCasesEvent(
            query: _searchController.text.trim(),
            court: _selectedCourt,
            category: widget.initialCategory,
            refresh: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Search'),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _triggerSearch(),
                decoration: InputDecoration(
                  hintText: 'Search by case name, citation, bench...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _triggerSearch();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Court Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _courts.map((court) {
                final isSelected = _selectedCourt == court;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(court),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCourt = court);
                      _triggerSearch();
                    },
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),

          // Results List
          Expanded(
            child: BlocBuilder<CaseBloc, CaseState>(
              builder: (context, state) {
                if (state is CaseLoading) {
                  return const LoadingIndicator(message: 'Searching landmark cases...');
                }

                if (state is CaseError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: _triggerSearch,
                  );
                }

                if (state is CasesLoaded) {
                  final cases = state.cases;

                  if (cases.isEmpty) {
                    return const EmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'No Cases Found',
                      subtitle: 'Try searching with different keywords, year or court name.',
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = cases[index];
                            return _buildCaseCard(context, c);
                          },
                        ),
                      ),
                      // Result count footer
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: AppColors.borderLight)),
                        ),
                        child: Text(
                          'Showing ${cases.length} results',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseModel c) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaseDetailScreen(caseId: c.id, initialCase: c),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (c.citation.isNotEmpty) ...[
                        Text(
                          c.citation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                      ],
                      Expanded(
                        child: Text(
                          c.court,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (c.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: c.tags.take(3).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withAlpha(12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
