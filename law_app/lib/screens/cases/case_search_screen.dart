import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/case_card.dart';
import 'case_detail_screen.dart';

class CaseSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const CaseSearchScreen({super.key, this.initialQuery});

  @override
  State<CaseSearchScreen> createState() => _CaseSearchScreenState();
}

class _CaseSearchScreenState extends State<CaseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _selectedCourt = 'All';
  int? _selectedYear;

  final List<String> _courtFilters = ['All', 'Supreme Court', 'High Court'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _triggerSearch(widget.initialQuery!);
    } else {
      context.read<CaseBloc>().add(LoadCuratedLandmarksEvent());
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CaseBloc>().state;
      if (state is CaseSearchSuccess && state.hasMore) {
        context.read<CaseBloc>().add(
              SearchCasesEvent(
                query: state.query,
                court: state.court,
                year: state.year,
                page: state.page + 1,
                isNewSearch: false,
              ),
            );
      }
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _triggerSearch(val);
    });
  }

  void _triggerSearch(String val) {
    context.read<CaseBloc>().add(
          SearchCasesEvent(
            query: val.trim(),
            court: _selectedCourt == 'All' ? null : _selectedCourt,
            year: _selectedYear,
            page: 1,
            isNewSearch: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Search Judgments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _triggerSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input & Filters Box
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _triggerSearch,
                  decoration: InputDecoration(
                    hintText: 'Search case title, citation (e.g. 1973 4 SCC 225)...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryNavy),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _triggerSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Court & Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._courtFilters.map((court) {
                        final isSelected = _selectedCourt == court;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(court),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCourt = court);
                                _triggerSearch(_searchController.text);
                              }
                            },
                            selectedColor: AppColors.primaryNavy,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.primaryNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
                            ),
                          ),
                        );
                      }),
                      // Year Filter Chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryNavy),
                          label: Text(_selectedYear != null ? 'Year: $_selectedYear' : 'Select Year'),
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                          backgroundColor: _selectedYear != null ? AppColors.goldAccent.withValues(alpha: 0.2) : Colors.white,
                          side: const BorderSide(color: AppColors.borderLight),
                          onPressed: () async {
                            final currentYear = DateTime.now().year;
                            final pickedYear = await showDialog<int>(
                              context: context,
                              builder: (ctx) {
                                return SimpleDialog(
                                  title: const Text('Filter by Year'),
                                  children: [
                                    SimpleDialogOption(
                                      onPressed: () => Navigator.pop(ctx, null),
                                      child: const Text('All Years (Clear)'),
                                    ),
                                    ...List.generate(30, (i) => currentYear - i).map((y) {
                                      return SimpleDialogOption(
                                        onPressed: () => Navigator.pop(ctx, y),
                                        child: Text(y.toString()),
                                      );
                                    }),
                                  ],
                                );
                              },
                            );

                            setState(() => _selectedYear = pickedYear);
                            _triggerSearch(_searchController.text);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results List / States
          Expanded(
            child: BlocBuilder<CaseBloc, CaseState>(
              builder: (context, state) {
                if (state is CaseLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryNavy),
                        SizedBox(height: 16),
                        Text('Searching Indian Kanoon & Case Law Database...', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                if (state is CaseError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _triggerSearch(_searchController.text),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Search'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is CaseSearchSuccess) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No judgments found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try searching with broader keywords, party names, or a standard citation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == state.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2),
                          ),
                        );
                      }

                      final item = state.items[idx];
                      return BlocBuilder<UserDataBloc, UserDataState>(
                        builder: (context, userState) {
                          final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(item.id);

                          return CaseCard(
                            caseItem: item,
                            isBookmarked: isBookmarked,
                            onBookmark: () {
                              context.read<UserDataBloc>().add(
                                    ToggleBookmarkEvent(
                                      refType: 'case',
                                      refId: item.id,
                                      title: item.title,
                                      subtitle: item.citation ?? item.court,
                                    ),
                                  );
                            },
                            onTap: () {
                              context.read<UserDataBloc>().add(
                                    LogHistoryEvent(
                                      refType: 'case',
                                      refId: item.id,
                                      title: item.title,
                                    ),
                                  );
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: item.id)),
                              );
                            },
                          );
                        },
                      );
                    },
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
}
