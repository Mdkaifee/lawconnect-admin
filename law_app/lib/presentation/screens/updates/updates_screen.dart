import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/legal_update_model.dart';
import '../../../logic/blocs/update/update_bloc.dart';
import '../../../logic/blocs/update/update_event.dart';
import '../../../logic/blocs/update/update_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Latest', 'Supreme Court', 'High Court'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUpdates();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadUpdates();
  }

  void _loadUpdates() {
    final court = _tabs[_tabController.index];
    context.read<UpdateBloc>().add(FetchUpdatesEvent(court: court));
  }

  Future<void> _openSourceUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Updates'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryNavy,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: BlocBuilder<UpdateBloc, UpdateState>(
        builder: (context, state) {
          if (state is UpdateLoading) {
            return const LoadingIndicator(message: 'Loading breaking legal updates...');
          }

          if (state is UpdateError) {
            return ErrorView(
              message: state.message,
              onRetry: _loadUpdates,
            );
          }

          if (state is UpdatesLoaded) {
            final updates = state.updates;

            if (updates.isEmpty) {
              return EmptyView(
                icon: Icons.newspaper_rounded,
                title: 'No Updates for ${_tabs[_tabController.index]}',
                subtitle: 'Check back soon for new case judgments and statutory notifications.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadUpdates(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: updates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = updates[index];
                  final isSC = item.badge == 'SC' || item.court.contains('Supreme');

                  return InkWell(
                    onTap: () {
                      if (item.url.isNotEmpty) {
                        _openSourceUrl(item.url);
                      } else {
                        _showUpdateDetailModal(context, item);
                      }
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSC ? AppColors.badgeSC : AppColors.badgeHC,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                if (item.body.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${_formatTimeAgo(item.publishedAt)} • ${item.source}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (item.url.isNotEmpty) ...[
                                      const Spacer(),
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 14,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showUpdateDetailModal(BuildContext context, LegalUpdateModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.badge,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.source,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              item.body.isNotEmpty ? item.body : 'No additional summary available.',
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
