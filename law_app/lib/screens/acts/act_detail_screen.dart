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
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: AppTheme.textPrimaryColor(context),
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.actName,
          style: TextStyle(
            color: AppTheme.textPrimaryColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      body: BlocBuilder<ActBloc, ActState>(
        bloc: _actBloc,
        builder: (context, state) {
          if (state is ActLoading) {
            return Center(child: CircularProgressIndicator(color: primaryOrGold));
          }

          if (state is ActError) {
            return Center(child: Text(state.message, style: TextStyle(color: AppTheme.textPrimaryColor(context))));
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
                  color: cardBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.goldAccent.withValues(alpha: 0.15)
                                  : AppColors.primaryNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${act.type} Act',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryOrGold,
                              ),
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
                        Text(act.description!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor(context))),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sectionSearchController,
                        onChanged: (val) => setState(() => _sectionQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Filter sections by number or title...',
                          prefixIcon: Icon(Icons.search, size: 20, color: primaryOrGold),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          fillColor: AppTheme.backgroundColor(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sections Accordion List
                Expanded(
                  child: filteredSections.isEmpty
                      ? Center(child: Text('No sections match filter.', style: TextStyle(color: AppTheme.textSecondaryColor(context))))
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
                              color: cardBg,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppTheme.borderColor(context)),
                              ),
                              child: ExpansionTile(
                                shape: const Border(),
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.goldAccent.withValues(alpha: 0.15)
                                        : AppColors.primaryNavy.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.number,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: primaryOrGold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s.title.isNotEmpty ? s.title : 'Section ${s.number}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimaryColor(context),
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
                                        Divider(color: AppTheme.dividerColor(context)),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          s.text.isNotEmpty ? s.text : 'Section text not available.',
                                          style: TextStyle(fontSize: 14, height: 1.55, color: AppTheme.textPrimaryColor(context)),
                                        ),
                                        if (s.explanation != null && s.explanation!.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.25)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.goldAccent),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Simplified Explanation',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: primaryOrGold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  s.explanation!,
                                                  style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimaryColor(context)),
                                                ),
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
                                              style: TextButton.styleFrom(
                                                foregroundColor: primaryOrGold,
                                              ),
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
                                                    : (isDark ? AppColors.goldAccent : AppColors.primaryNavy),
                                                foregroundColor: isBookmarked
                                                    ? primaryOrGold
                                                    : (isDark ? AppColors.primaryNavyDark : Colors.white),
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
