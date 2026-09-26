import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/act_model.dart';
import '../../../logic/blocs/act/act_bloc.dart';
import '../../../logic/blocs/act/act_event.dart';
import '../../../logic/blocs/act/act_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';

class ActDetailScreen extends StatefulWidget {
  final String actId;
  final ActModel? initialAct;

  const ActDetailScreen({
    super.key,
    required this.actId,
    this.initialAct,
  });

  @override
  State<ActDetailScreen> createState() => _ActDetailScreenState();
}

class _ActDetailScreenState extends State<ActDetailScreen> {
  final _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    context.read<ActBloc>().add(FetchActDetailsEvent(widget.actId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActBloc, ActState>(
      builder: (context, state) {
        ActModel? act = widget.initialAct;
        if (state is ActDetailLoaded) {
          act = state.act;
        }

        if (state is ActLoading && act == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingIndicator(message: 'Loading act and sections...'),
          );
        }

        if (state is ActError && act == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.message,
              onRetry: () => context.read<ActBloc>().add(FetchActDetailsEvent(widget.actId)),
            ),
          );
        }

        if (act == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Act not found')),
          );
        }

        final filteredSections = act.sections.where((s) {
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return s.number.toLowerCase().contains(q) ||
              s.title.toLowerCase().contains(q) ||
              s.text.toLowerCase().contains(q) ||
              s.explanation.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(act.shortName.isNotEmpty ? act.shortName : act.name),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Act Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            act.type,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Year: ${act.year}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (act.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        act.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),

              // Section Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchFilter = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Filter sections (e.g. Article 21, Murder...)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),

              // Sections List
              Expanded(
                child: filteredSections.isEmpty
                    ? const EmptyView(
                        icon: Icons.search_off_rounded,
                        title: 'No Sections Found',
                        subtitle: 'Try searching with another section number or keyword.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredSections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = filteredSections[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                title: Text(
                                  s.number,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                subtitle: s.title.isNotEmpty
                                    ? Text(
                                        s.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : null,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(color: AppColors.borderLight),
                                        if (s.text.isNotEmpty) ...[
                                          const Text(
                                            'Statutory Text:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.text,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.45,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                        if (s.explanation.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentGold.withAlpha(15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.accentGold.withAlpha(50),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.lightbulb_outline,
                                                        size: 16, color: AppColors.accentGold),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Simplified Explanation:',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  s.explanation,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
