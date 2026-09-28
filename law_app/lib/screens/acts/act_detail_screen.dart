import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/act/act_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/act_repository.dart';
import '../../repositories/user_data_repository.dart';

class ActDetailScreen extends StatefulWidget {
  final String actId;
  final String actName;

  const ActDetailScreen({super.key, required this.actId, required this.actName});

  @override
  State<ActDetailScreen> createState() => _ActDetailScreenState();
}

class _ActDetailScreenState extends State<ActDetailScreen> {
  final TextEditingController _sectionSearchController = TextEditingController();
  String _sectionQuery = '';
  final Set<String> _bookmarkBusy = {};
  ActBloc? _actBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actBloc ??= ActBloc(actRepository: context.read<ActRepository>())
      ..add(LoadActDetailsEvent(widget.actId));
  }

  @override
  void dispose() {
    _sectionSearchController.dispose();
    _actBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.actName,
          style: const TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: BlocBuilder<ActBloc, ActState>(
        bloc: _actBloc,
        builder: (context, state) {
          if (state is ActLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
          }

          if (state is ActError) {
            return Center(child: Text(state.message));
          }

          if (state is ActDetailsLoaded) {
            final act = state.act;
            final filteredSections = act.sections.where((s) {
              if (_sectionQuery.isEmpty) return true;
              final q = _sectionQuery.toLowerCase();
              return s.number.toLowerCase().contains(q) ||
                  s.title.toLowerCase().contains(q) ||
                  s.text.toLowerCase().contains(q);
            }).toList();

            return Column(
              children: [
                // Header Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${act.type} Act',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                            ),
                          ),
                          if (act.year != null) ...[
                            const SizedBox(width: 8),
                            Text('Enacted: ${act.year}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                          const Spacer(),
                          Text(
                            '${act.sections.length} Sections',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
                          ),
                        ],
                      ),
                      if (act.description != null && act.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(act.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sectionSearchController,
                        onChanged: (val) => setState(() => _sectionQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Filter sections by number or title...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          fillColor: AppColors.backgroundLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sections Accordion List
                Expanded(
                  child: filteredSections.isEmpty
                      ? const Center(child: Text('No sections match filter.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredSections.length,
                          itemBuilder: (context, idx) {
                            final s = filteredSections[idx];
                            final refId = '${act.id}_${s.number}';
                            final userState = context.watch<UserDataBloc>().state;
                            final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(refId);
                            final isBookmarkBusy = _bookmarkBusy.contains(refId);
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: AppColors.borderLight),
                              ),
                              child: ExpansionTile(
                                shape: const Border(),
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.number,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s.title.isNotEmpty ? s.title : 'Section ${s.number}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                subtitle: s.chapter != null && s.chapter!.isNotEmpty
                                    ? Text('Chapter: ${s.chapter}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
                                    : null,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(color: AppColors.borderLight),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          s.text.isNotEmpty ? s.text : 'Section text not available.',
                                          style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textPrimary),
                                        ),
                                        if (s.explanation != null && s.explanation!.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldAccent.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.goldAccent),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Simplified Explanation',
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(s.explanation!, style: const TextStyle(fontSize: 13, height: 1.4)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.copy, size: 16),
                                              label: const Text('Copy Text'),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: '${s.number}: ${s.title}\n\n${s.text}'));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Section copied to clipboard!')),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              icon: isBookmarkBusy
                                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 16),
                                              label: Text(isBookmarked ? 'Bookmarked' : 'Bookmark'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isBookmarked
                                                    ? AppColors.goldAccent.withValues(alpha: 0.22)
                                                    : AppColors.primaryNavy,
                                                foregroundColor: isBookmarked ? AppColors.primaryNavy : Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              onPressed: isBookmarkBusy ? null : () async {
                                                setState(() => _bookmarkBusy.add(refId));
                                                try {
                                                  final repository = context.read<UserDataRepository>();
                                                  if (isBookmarked) {
                                                    await repository.removeBookmark(refId);
                                                  } else {
                                                    await repository.addBookmark(
                                                      refType: 'section', refId: refId,
                                                      title: '${act.shortName} - ${s.number}', subtitle: s.title,
                                                    );
                                                  }
                                                  if (mounted) context.read<UserDataBloc>().add(LoadUserDataEvent());
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(isBookmarked ? 'Removed from bookmarks' : 'Bookmarked successfully')),
                                                    );
                                                  }
                                                } catch (_) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Could not update bookmark')),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) setState(() => _bookmarkBusy.remove(refId));
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
