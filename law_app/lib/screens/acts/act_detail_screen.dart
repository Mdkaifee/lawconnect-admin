import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/act_model.dart';
import '../../repositories/act_repository.dart';

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
  ActModel? _act;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActDetails();
  }

  @override
  void dispose() {
    _sectionSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadActDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = RepositoryProvider.of<ActRepository>(context);
      final act = await repo.getActDetails(widget.actId);
      if (mounted) {
        setState(() {
          _act = act;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.actName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : _errorMessage != null || _act == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? 'Failed to load act details.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildActView(context, _act!),
    );
  }

  Widget _buildActView(BuildContext context, ActModel act) {
    final filteredSections = act.sections.where((s) {
      if (_sectionQuery.isEmpty) return true;
      final q = _sectionQuery.toLowerCase();
      return s.number.toLowerCase().contains(q) ||
          s.title.toLowerCase().contains(q) ||
          s.text.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Act Overview Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Year: ${act.year ?? "Central"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${act.sections.length} Provisions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              if (act.description != null && act.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  act.description!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
              const SizedBox(height: 12),
              // Section Search Filter Box
              TextField(
                controller: _sectionSearchController,
                onChanged: (val) {
                  setState(() {
                    _sectionQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search sections, articles, or keywords in this act...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _sectionQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _sectionSearchController.clear();
                            setState(() => _sectionQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sections / Articles List
        Expanded(
          child: filteredSections.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No matching sections found in this act.'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSections.length,
                  itemBuilder: (context, idx) {
                    final sec = filteredSections[idx];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryNavy, size: 20),
                        ),
                        title: Text(
                          sec.number,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryNavy),
                        ),
                        subtitle: Text(
                          sec.title,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.borderLight),
                                const SizedBox(height: 6),
                                const Text(
                                  'Statutory Provision Text:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  sec.text,
                                  style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textPrimary),
                                ),
                                if (sec.explanation != null && sec.explanation!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldAccent.withValues(alpha: 0.1),
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
                                              'Simplified Ratio / Practical Application:',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sec.explanation!,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                                      tooltip: 'Copy text',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: '${sec.number}: ${sec.title}\n\n${sec.text}'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Section copied to clipboard')),
                                        );
                                      },
                                    ),
                                    BlocBuilder<UserDataBloc, UserDataState>(
                                      builder: (context, userState) {
                                        final isBookmarked = userState is UserDataLoaded &&
                                            userState.bookmarks.any((b) => b.refId == '${act.id}_${sec.number}');
                                        return IconButton(
                                          icon: Icon(
                                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                            size: 20,
                                            color: isBookmarked ? AppColors.goldAccent : AppColors.textSecondary,
                                          ),
                                          tooltip: 'Bookmark Section',
                                          onPressed: () {
                                            context.read<UserDataBloc>().add(
                                                  ToggleBookmarkEvent(
                                                    refType: 'section',
                                                    refId: '${act.id}_${sec.number}',
                                                    title: '${act.shortName} - ${sec.number}',
                                                    subtitle: sec.title,
                                                  ),
                                                );
                                          },
                                        );
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
}
