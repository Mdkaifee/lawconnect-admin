import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/html_sanitizer.dart';
import '../../models/case_model.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

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

  void _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddNoteDialog(BuildContext context, CaseModel caseItem) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteController.text.trim().isNotEmpty) {
                context.read<UserDataBloc>().add(
                      SaveNoteEvent(
                        title: 'Note: ${HtmlSanitizer.truncate(caseItem.title, 35)}',
                        content: _noteController.text.trim(),
                        refType: 'case',
                        refId: caseItem.id,
                        refTitle: caseItem.title,
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocBuilder<CaseBloc, CaseState>(
        builder: (context, state) {
          if (state is CaseLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
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
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CaseBloc>().add(LoadCaseDetailsEvent(widget.caseId)),
                      child: const Text('Retry'),
                    ),
                  ],
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
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    pinned: true,
                    floating: true,
                    actions: [
                      BlocBuilder<UserDataBloc, UserDataState>(
                        builder: (context, userState) {
                          final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(c.id);
                          return IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? AppColors.goldAccent : Colors.white,
                            ),
                            onPressed: () {
                              context.read<UserDataBloc>().add(
                                    ToggleBookmarkEvent(
                                      refType: 'case',
                                      refId: c.id,
                                      title: c.title,
                                      subtitle: c.citation ?? c.court,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.note_add_outlined),
                        onPressed: () => _showAddNoteDialog(context, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () {
                          Share.share(
                            '${c.title}\n\nCitation: ${c.citation ?? "N/A"}\nCourt: ${c.court}\n\nRead on Rishikesh Law Hub',
                          );
                        },
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        const Tab(text: 'Summary'),
                        const Tab(text: 'Full Judgment'),
                        Tab(text: 'Precedents (${c.cites.length + c.citedBy.length})'),
                        const Tab(text: 'Simple Ratio'),
                      ],
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  // Meta Header Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              c.court,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (c.dateOfJudgment != null) ...[
                              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                              Text(
                                c.dateOfJudgment!,
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
                            onTap: () => _openUrl(c.sourceUrl),
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
                              if (c.bench != null && c.bench!.isNotEmpty) ...[
                                _buildInfoCard('Bench / Judges', c.bench!),
                                const SizedBox(height: 12),
                              ],
                              if (c.petitioners != null || c.respondents != null) ...[
                                _buildInfoCard(
                                  'Parties',
                                  'Petitioner: ${c.petitioners ?? "N/A"}\nRespondent: ${c.respondents ?? "N/A"}',
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text(
                                'Executive Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  HtmlSanitizer.stripHtml(c.summary ?? 'No summary available for this judgment.'),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: SelectableText(
                              HtmlSanitizer.stripHtml(c.fullText ?? c.summary ?? 'Full judgment text is loading or unavailable.'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),

                        // Tab 3: Precedents / Citations
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cited By This Judgment
                              const Text(
                                'Cases Cited By This Judgment',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(height: 8),
                              if (c.cites.isEmpty)
                                const Text('No cited cases documented for this judgment.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                              else
                                ...c.cites.map((ref) => _buildCaseRefCard(ref)),

                              const SizedBox(height: 20),

                              // Cases Citing This Judgment
                              const Text(
                                'Cases Citing This Judgment',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(height: 8),
                              if (c.citedBy.isEmpty)
                                const Text('No subsequent citations documented yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                              else
                                ...c.citedBy.map((ref) => _buildCaseRefCard(ref)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, color: AppColors.goldAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      'Key Legal Principle',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryNavy),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  c.simpleExplanation ??
                                      c.summary ??
                                      'This judgment sets key binding precedent on the constitutional and statutory questions raised before the Bench.',
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
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

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCaseRefCard(CaseReference ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        title: Text(
          ref.title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
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

