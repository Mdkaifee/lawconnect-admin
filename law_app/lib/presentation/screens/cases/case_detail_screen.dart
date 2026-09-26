import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/case_model.dart';
import '../../../logic/blocs/bookmark/bookmark_bloc.dart';
import '../../../logic/blocs/bookmark/bookmark_event.dart';
import '../../../logic/blocs/case/case_bloc.dart';
import '../../../logic/blocs/case/case_event.dart';
import '../../../logic/blocs/case/case_state.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import '../notes/add_edit_note_dialog.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  final CaseModel? initialCase;

  const CaseDetailScreen({
    super.key,
    required this.caseId,
    this.initialCase,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<CaseBloc>().add(FetchCaseDetailsEvent(widget.caseId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleBookmark(CaseModel c) {
    setState(() => _isBookmarked = !_isBookmarked);
    context.read<BookmarkBloc>().add(
          ToggleBookmarkEvent(
            refType: 'case',
            refId: c.id,
            title: c.title,
            subtitle: c.citation.isNotEmpty ? c.citation : c.court,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Case bookmarked!' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareCase(CaseModel c) {
    Share.share(
      '${c.title}\nCitation: ${c.citation}\nCourt: ${c.court}\n\nSummary:\n${c.summary}\n\nRead on Rishikesh Law Hub',
    );
  }

  Future<void> _openPdf(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judgment PDF link not available for this case.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the judgment PDF link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaseBloc, CaseState>(
      builder: (context, state) {
        CaseModel? c = widget.initialCase;
        if (state is CaseDetailLoaded) {
          c = state.caseModel;
        }

        if (state is CaseLoading && c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingIndicator(message: 'Loading case details...'),
          );
        }

        if (state is CaseError && c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.message,
              onRetry: () => context.read<CaseBloc>().add(FetchCaseDetailsEvent(widget.caseId)),
            ),
          );
        }

        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Case not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: _isBookmarked ? AppColors.accentGold : AppColors.textPrimary,
                ),
                onPressed: () => _toggleBookmark(c!),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareCase(c!),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () => _openPdf(c!.judgmentPdfUrl),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text('Read Full Judgment (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: GoogleFonts.merriweather(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (c.citation.isNotEmpty) ...[
                          Text(
                            c.citation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentGold,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        ],
                        Expanded(
                          child: Text(
                            c.court,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (c.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: c.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
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

              // TabBar
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight),
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryNavy,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primaryNavy,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Judgment'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Related'),
                  ],
                ),
              ),

              // TabBarViews
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Overview
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataRow('Bench', c.bench.isNotEmpty ? c.bench : 'Not Specified'),
                          _buildMetadataRow('Petitioners', c.petitioners.isNotEmpty ? c.petitioners : '—'),
                          _buildMetadataRow('Respondents', c.respondents.isNotEmpty ? c.respondents : '—'),
                          _buildMetadataRow(
                            'Date of Judgment',
                            c.dateOfJudgment != null
                                ? c.dateOfJudgment!.split('T').first
                                : '${c.year}',
                          ),
                          _buildMetadataRow('Citation', c.citation.isNotEmpty ? c.citation : '—'),
                          const Divider(height: 32, color: AppColors.borderLight),
                          const Text(
                            'Case Summary',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.summary.isNotEmpty ? c.summary : 'No summary provided for this judgment.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (c.simpleExplanation.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accentGold.withAlpha(60)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accentGold),
                                      SizedBox(width: 8),
                                      Text(
                                        'Simple Language Explanation',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    c.simpleExplanation,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
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

                    // Tab 2: Full Judgment Text
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Full Judgment Digest',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            c.summary,
                            style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          if (c.judgmentPdfUrl.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _openPdf(c!.judgmentPdfUrl),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('Open Official PDF Source'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                            ),
                        ],
                      ),
                    ),

                    // Tab 3: Notes
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'Personal Notes for this Case',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your key takeaways, case laws, or exam revision bullet points.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              AddEditNoteDialog.show(
                                context,
                                refType: 'case',
                                refId: c!.id,
                                refTitle: c.title,
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Note for this Case'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                          ),
                        ],
                      ),
                    ),

                    // Tab 4: Related Cases
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Related landmark cases will appear here.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
