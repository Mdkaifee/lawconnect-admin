import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/user_data_repository.dart';
import '../../widgets/case_card.dart';
import 'case_detail_screen.dart';
import '../main_navigation_screen.dart';

class CaseSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool autoOpenFilter;
  const CaseSearchScreen({super.key, this.initialQuery, this.autoOpenFilter = false});

  @override
  State<CaseSearchScreen> createState() => _CaseSearchScreenState();
}

class _CaseSearchScreenState extends State<CaseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _selectedCourt = 'All';
  int? _selectedYear;
  final Set<String> _loadingBookmarks = {};
  final Map<String, bool> _bookmarkOverrides = {};

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

    if (widget.autoOpenFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showYearFilter());
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

  Future<void> _showYearFilter() async {
    final currentYear = DateTime.now().year;
    final pickedYear = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Filter by Year'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text('All Years')),
          ...List.generate(30, (i) => currentYear - i).map(
            (year) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, year), child: Text(year.toString())),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _selectedYear = pickedYear);
    _triggerSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
        leading: IconButton(
          color: AppColors.primaryNavy,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
        title: const Text('Case Search', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh results',
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
                    hintText: 'Search case name or citation...',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryNavy),
                    suffixIconConstraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(8)),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.search, size: 18, color: Colors.white),
                        onPressed: () => _triggerSearch(_searchController.text),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
                const SizedBox(height: 10),

                // Court & Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                      ..._courtFilters.map((court) {
                        final isSelected = _selectedCourt == court;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(court),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            padding: EdgeInsets.zero,
                            showCheckmark: true,
                            checkmarkColor: Colors.white,
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
                      // Year filter control at the far right.
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: _selectedYear == null ? 'Filter by year' : 'Year: $_selectedYear',
                            icon: Icon(Icons.filter_alt_outlined, size: 18, color: _selectedYear == null ? AppColors.primaryNavy : AppColors.goldAccent),
                            onPressed: _showYearFilter,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    itemCount: state.items.length + (state.hasMore ? 1 : 0) + (state.hasMore ? 0 : 1),
                    itemBuilder: (context, idx) {
                      if (!state.hasMore && idx == state.items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 18),
                          child: Center(
                            child: Text(
                              'Showing ${state.items.length} results',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }
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
                          final serverBookmarked = userState is UserDataLoaded && userState.isBookmarked(item.id);
                          final isBookmarked = _bookmarkOverrides[item.id] ?? serverBookmarked;
                          final isBookmarkLoading = _loadingBookmarks.contains(item.id);

                          return CaseCard(
                            caseItem: item,
                            compact: true,
                            isBookmarked: isBookmarked,
                            isBookmarkLoading: isBookmarkLoading,
                            onBookmark: isBookmarkLoading
                                ? null
                                : () async {
                                    setState(() => _loadingBookmarks.add(item.id));
                                    try {
                                      final repo = context.read<UserDataRepository>();
                                      if (isBookmarked) {
                                        await repo.removeBookmark(item.id);
                                      } else {
                                        await repo.addBookmark(
                                          refType: 'case',
                                          refId: item.id,
                                          title: item.title,
                                          subtitle: item.citation ?? item.court,
                                        );
                                      }
                                      if (mounted) {
                                        setState(() => _bookmarkOverrides[item.id] = !isBookmarked);
                                        context.read<UserDataBloc>().add(LoadUserDataEvent());
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isBookmarked ? 'Removed from bookmarks' : 'Added to bookmarks'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _loadingBookmarks.remove(item.id));
                                    }
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
                              ).then((_) => _triggerSearch(_searchController.text));
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
