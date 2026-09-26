import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/blocs/act/act_bloc.dart';
import '../../../logic/blocs/act/act_event.dart';
import '../../../logic/blocs/act/act_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import 'act_detail_screen.dart';

class ActsScreen extends StatefulWidget {
  const ActsScreen({super.key});

  @override
  State<ActsScreen> createState() => _ActsScreenState();
}

class _ActsScreenState extends State<ActsScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'All Acts';
  final List<String> _types = ['All Acts', 'Central Acts', 'State Acts'];

  final List<Color> _actColors = [
    AppColors.catConstitution,
    AppColors.catCriminal,
    AppColors.catContract,
    AppColors.catTorts,
    AppColors.catFamily,
    AppColors.catLabour,
    AppColors.catEnvironment,
    AppColors.catMore,
  ];

  @override
  void initState() {
    super.initState();
    _loadActs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadActs() {
    context.read<ActBloc>().add(
          FetchActsEvent(
            query: _searchController.text.trim(),
            type: _selectedType,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acts & Sections'),
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
                onSubmitted: (_) => _loadActs(),
                decoration: InputDecoration(
                  hintText: 'Search Act or Section...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _loadActs();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                      _loadActs();
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

          // Acts List
          Expanded(
            child: BlocBuilder<ActBloc, ActState>(
              builder: (context, state) {
                if (state is ActLoading) {
                  return const LoadingIndicator(message: 'Loading statutory acts...');
                }

                if (state is ActError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: _loadActs,
                  );
                }

                if (state is ActsLoaded) {
                  final acts = state.acts;

                  if (acts.isEmpty) {
                    return const EmptyView(
                      icon: Icons.menu_book_rounded,
                      title: 'No Acts Found',
                      subtitle: 'Try searching with another keyword.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: acts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final act = acts[index];
                      final color = _actColors[index % _actColors.length];

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ActDetailScreen(actId: act.id, initialAct: act),
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
                                color: Colors.black.withAlpha(5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(Icons.menu_book_rounded, color: color, size: 24),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${act.description.isNotEmpty ? act.description : act.type} • ${act.sections.length} Sections',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
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
