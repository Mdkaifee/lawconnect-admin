import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/html_sanitizer.dart';
import '../../models/case_model.dart';
import '../../repositories/case_repository.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  CaseModel? _caseItem;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCaseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCaseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = RepositoryProvider.of<CaseRepository>(context);
      final c = await repo.getCaseDetails(widget.caseId);
      if (mounted) {
        // Record in reading history
        context.read<UserDataBloc>().add(
              LogHistoryEvent(
                refType: 'case',
                refId: c.id,
                title: c.title,
              ),
            );
        setState(() {
          _caseItem = c;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
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
              decoration: InputDecoration(
                hintText: 'Key ratios, judicial precedents, personal observations...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = _noteController.text.trim();
              if (text.isNotEmpty) {
                context.read<UserDataBloc>().add(
                      SaveNoteEvent(
                        title: 'Note: ${caseItem.title}',
                        content: text,
                        refType: 'case',
                        refId: caseItem.id,
                        refTitle: caseItem.title,
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved to your profile!')),
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
      body: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
            )
          : _errorMessage != null || _caseItem == null
              ? Scaffold(
                  appBar: AppBar(title: const Text('Case Details')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage ?? 'Failed to load case details.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCaseDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _buildCaseView(context, _caseItem!),
    );
  }

  Widget _buildCaseView(BuildContext context, CaseModel c) {
    final formattedDate = AppDateFormatter.formatDate(c.dateOfJudgment);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            title: Text(
              c.citation?.isNotEmpty == true ? c.citation! : 'Judgment Details',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            actions: [
              BlocBuilder<UserDataBloc, UserDataState>(
                builder: (context, userState) {
                  final isBookmarked = userState is UserDataLoaded &&
                      userState.bookmarks.any((b) => b.refId == c.id);
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
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {
                  Share.share('${c.title}\n${c.citation ?? ""}\nCourt: ${c.court}\n\n- Shared via Law Hub');
                },
              ),
              IconButton(
                icon: const Icon(Icons.note_add_outlined, color: Colors.white),
                onPressed: () => _showAddNoteDialog(context, c),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primaryNavy,
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          c.court,
                          style: const TextStyle(fontSize: 12, color: AppColors.goldAccentLight, fontWeight: FontWeight.w600),
                        ),
                        if (formattedDate.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: Colors.white70)),
                          Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.goldAccent,
              indicatorWeight: 3,
              labelColor: AppColors.goldAccent,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Simple'),
                Tab(text: 'Full Text'),
                Tab(text: 'Details'),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Structured Summary
          _buildSummaryTab(c),
          // 2. Simple Explanation
          _buildSimpleExplanationTab(c),
          // 3. Full Text / Judgment
          _buildFullTextTab(c),
          // 4. Bench & Meta Details
          _buildDetailsTab(c),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(CaseModel c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'Summary of the Judgment',
            icon: Icons.article_outlined,
            child: Text(
              c.summary?.isNotEmpty == true ? c.summary! : 'No structured summary provided for this judgment yet.',
              style: const TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.textPrimary),
            ),
          ),
          if (c.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCard(
              title: 'Key Legal Tags & Provisions',
              icon: Icons.label_outline,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleExplanationTab(CaseModel c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildCard(
        title: 'Plain English / Legal Ratio',
        icon: Icons.lightbulb_outline_rounded,
        iconColor: AppColors.goldAccent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key takeaway simplified for advocates, students, and citizens:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Text(
              c.simpleExplanation?.isNotEmpty == true
                  ? c.simpleExplanation!
                  : (c.summary?.isNotEmpty == true
                      ? c.summary!
                      : 'The full explanation is available in the Full Text tab.'),
              style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullTextTab(CaseModel c) {
    if (c.fullText == null || c.fullText!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Complete Judgment Text',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'The full judgment transcript is available via official court repository.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              if (c.sourceUrl != null && c.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openUrl(c.sourceUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Court Copy PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final cleanHtml = HtmlSanitizer.stripHtml(c.fullText!);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          cleanHtml,
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(CaseModel c) {
    final formattedDate = AppDateFormatter.formatDate(c.dateOfJudgment);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            title: 'Court & Bench Metadata',
            icon: Icons.gavel_rounded,
            child: Column(
              children: [
                _buildMetaRow('Court', c.court),
                _buildMetaRow('Bench', c.bench ?? 'N/A'),
                _buildMetaRow('Petitioners', c.petitioners ?? 'N/A'),
                _buildMetaRow('Respondents', c.respondents ?? 'N/A'),
                _buildMetaRow('Date of Judgment', formattedDate.isNotEmpty ? formattedDate : 'N/A'),
                _buildMetaRow('Citation', c.citation ?? 'N/A'),
              ],
            ),
          ),
          if (c.hasCourtCopy) ...[
            const SizedBox(height: 16),
            _buildCard(
              title: 'Original Document Copies',
              icon: Icons.picture_as_pdf_outlined,
              iconColor: AppColors.success,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_present_rounded, color: AppColors.success, size: 32),
                title: const Text('Verified Official Court Copy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('PDF copy sourced directly from court portal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _openUrl(c.sourceUrl),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? AppColors.primaryNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderLight),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
          ),
        ],
      ),
    );
  }
}
