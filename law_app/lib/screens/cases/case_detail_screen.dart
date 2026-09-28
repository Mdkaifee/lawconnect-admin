import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/html_sanitizer.dart';
import '../../core/utils/url_helper.dart';
import '../../models/case_model.dart';
import '../../repositories/user_data_repository.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  bool _bookmarkBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<CaseBloc>().add(LoadCaseDetailsEvent(widget.caseId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _openUrl(String? url) {
    if (url == null || url.isEmpty) return;
    final resolved = url.startsWith('/')
        ? '${ApiConstants.baseUrl.replaceFirst('/api', '')}$url'
        : url;
    UrlHelper.openInAppUrl(context, resolved);
  }

  String _formatJudgmentDate(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  Future<void> _toggleBookmark(CaseModel item, bool currentlyBookmarked) async {
    if (_bookmarkBusy) return;
    setState(() => _bookmarkBusy = true);
    try {
      final repository = context.read<UserDataRepository>();
      if (currentlyBookmarked) {
        await repository.removeBookmark(item.id);
      } else {
        await repository.addBookmark(
          refType: 'case',
          refId: item.id,
          title: item.title,
          subtitle: item.citation ?? item.court,
        );
      }
      if (mounted) context.read<UserDataBloc>().add(LoadUserDataEvent());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark update failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  void _showAddNoteDialog(BuildContext context, CaseModel caseItem) {
    _noteController.clear();
    var saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Add Case Study Note', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caseItem.title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write your legal insights, principles, or notes here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: saving || _noteController.text.trim().isEmpty ? null : () async {
              setDialogState(() => saving = true);
              try {
                await context.read<UserDataRepository>().saveNote(
                  title: 'Note: ${HtmlSanitizer.truncate(caseItem.title, 35)}',
                  content: _noteController.text.trim(),
                  refType: 'case',
                  refId: caseItem.id,
                  refTitle: caseItem.title,
                );
                if (!ctx.mounted) return;
                context.read<UserDataBloc>().add(LoadUserDataEvent());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved successfully!'), backgroundColor: AppColors.success));
              } catch (_) {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Unable to save note')));
              }
            },
            child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Note'),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final borderColor = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: BlocBuilder<CaseBloc, CaseState>(
        builder: (context, state) {
          if (state is CaseLoading) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor(context),
              appBar: AppBar(
                backgroundColor: AppTheme.appBarColor(context),
                foregroundColor: textPrimary,
                surfaceTintColor: AppTheme.appBarColor(context),
                leading: const BackButton(),
                title: Text('Case Details', style: TextStyle(color: textPrimary)),
              ),
              body: Center(child: CircularProgressIndicator(color: primaryOrGold)),
            );
          }

          if (state is CaseError) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor(context),
              appBar: AppBar(
                backgroundColor: AppTheme.appBarColor(context),
                foregroundColor: textPrimary,
                surfaceTintColor: AppTheme.appBarColor(context),
                leading: const BackButton(),
                title: Text('Case Details', style: TextStyle(color: textPrimary)),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: textPrimary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<CaseBloc>().add(LoadCaseDetailsEvent(widget.caseId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is CaseDetailsLoaded) {
            final c = state.caseItem;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: AppTheme.appBarColor(context),
                    surfaceTintColor: AppTheme.appBarColor(context),
                    shadowColor: Colors.transparent,
                    foregroundColor: textPrimary,
                    iconTheme: IconThemeData(color: textPrimary),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: Text(
                      'Case Details',
                      style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    pinned: true,
                    expandedHeight: 0,
                    toolbarHeight: 56,
                    actions: [
                      BlocBuilder<UserDataBloc, UserDataState>(
                        builder: (context, userState) {
                          final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(c.id);
                          return IconButton(
                            icon: _bookmarkBusy
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrGold))
                                : Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: isBookmarked ? AppColors.goldAccent : textPrimary,
                                  ),
                            onPressed: _bookmarkBusy ? null : () => _toggleBookmark(c, isBookmarked),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined, color: textPrimary),
                        onPressed: () {
                          Share.share(
                            '${c.title}\n\nCitation: ${c.citation ?? "N/A"}\nCourt: ${c.court}\n\nRead on Rishikesh Law Hub',
                          );
                        },
                      ),
                    ],
                  ),
                ];
              },
              body: Column(
                children: [
                  // Meta Header Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: cardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              c.court,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            if (_formatJudgmentDate(c.dateOfJudgment).isNotEmpty) ...[
                              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                              Text(
                                _formatJudgmentDate(c.dateOfJudgment),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                        if (c.citation != null && c.citation!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            c.citation!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                        if (c.hasCourtCopy) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _openUrl(c.origDocUrl ?? c.sourceUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: AppColors.success, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'View Original Court Document',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Material(
                    color: cardBg,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primaryOrGold,
                      unselectedLabelColor: textSecondary,
                      indicatorColor: primaryOrGold,
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Judgment'),
                        Tab(text: 'Notes'),
                        Tab(text: 'Related'),
                      ],
                    ),
                  ),

                  // Tab Views Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Summary
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow('Bench', c.bench ?? 'N/A', context),
                                    _buildDetailRow('Petitioners', c.petitioners ?? 'N/A', context),
                                    _buildDetailRow('Respondents', c.respondents ?? 'N/A', context),
                                    _buildDetailRow('Date of Judgment', _formatJudgmentDate(c.dateOfJudgment), context),
                                    _buildDetailRow('Citation', c.citation ?? 'N/A', context),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Case Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  HtmlSanitizer.stripHtml(c.summary ?? 'No summary available for this judgment.'),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openUrl(c.origDocUrl ?? c.sourceUrl),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                  label: const Text('Read Full Judgment (PDF)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
                                    foregroundColor: isDark ? AppColors.primaryNavyDark : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab 2: Full Judgment Text
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: (c.fullText ?? '').trim().isNotEmpty
                                ? SelectableText(
                                    HtmlSanitizer.stripHtml(c.fullText!),
                                    style: TextStyle(fontSize: 14, color: textPrimary, height: 1.6),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.description_outlined, color: primaryOrGold, size: 30),
                                      const SizedBox(height: 10),
                                      Text('Full judgment text is not available yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                                      const SizedBox(height: 6),
                                      Text('You can read the official judgment using the PDF button below.', style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openUrl(c.origDocUrl ?? c.sourceUrl),
                                          icon: const Icon(Icons.picture_as_pdf_outlined),
                                          label: const Text('Open Official Judgment PDF'),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Tab 3: Precedents / Citations
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                              const SizedBox(height: 8),
                              BlocBuilder<UserDataBloc, UserDataState>(
                                builder: (context, userState) {
                                  final notes = userState is UserDataLoaded
                                      ? userState.notes.where((note) => note.refId == c.id).toList()
                                      : const [];
                                  if (notes.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Text('No notes for this case yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                    );
                                  }
                                  return Column(
                                    children: notes.map((note) => Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(note.title, style: TextStyle(fontWeight: FontWeight.w700, color: primaryOrGold)),
                                        const SizedBox(height: 5),
                                        Text(note.content, style: TextStyle(color: textPrimary, height: 1.4)),
                                      ]),
                                    )).toList(),
                                  );
                                },
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showAddNoteDialog(context, c),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Note'),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Related cases
                              Text(
                                'Cases Cited By This Judgment',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              const SizedBox(height: 8),
                              if (c.cites.isEmpty)
                                const Text('No cited cases documented for this judgment.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                              else
                                ...c.cites.map((ref) => _buildCaseRefCard(ref, context)),

                              const SizedBox(height: 20),

                              // Cases Citing This Judgment
                              Text(
                                'Cases Citing This Judgment',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              const SizedBox(height: 8),
                              if (c.citedBy.isEmpty)
                                const Text('No subsequent citations documented yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                              else
                                ...c.citedBy.map((ref) => _buildCaseRefCard(ref, context)),
                            ],
                          ),
                        ),

                        // Tab 4: Simple Ratio / Breakdown
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.goldAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Key Legal Principle',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  c.simpleExplanation ??
                                      c.summary ??
                                      'This judgment sets key binding precedent on the constitutional and statutory questions raised before the Bench.',
                                  style: TextStyle(fontSize: 14, color: textPrimary, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: CircularProgressIndicator(color: primaryOrGold),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 105, child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor(context)))),
          const Text(':', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildCaseRefCard(CaseReference ref, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: ListTile(
        title: Text(
          ref.title,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor(context)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: 'ik_${ref.providerId}')),
          );
        },
      ),
    );
  }
}
