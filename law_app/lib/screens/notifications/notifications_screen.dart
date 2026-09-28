import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/notification_model.dart';
import '../cases/case_detail_screen.dart';
import '../cases/case_search_screen.dart';
import '../acts/acts_list_screen.dart';
import '../updates/updates_screen.dart';
import '../community/community_feed_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotificationsEvent());
  }

  void _handleNotificationTap(NotificationModel notif) {
    // Mark as read
    if (!notif.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(notif.id));
    }

    final targetType = (notif.refType?.isNotEmpty == true ? notif.refType : notif.type)?.toLowerCase() ?? 'general';

    switch (targetType) {
      case 'case':
      case 'judgment':
        if (notif.refId != null && notif.refId!.isNotEmpty && notif.refId != 'general') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: notif.refId!)),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaseSearchScreen()),
          );
        }
        break;

      case 'act':
      case 'bare_act':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActsListScreen()),
        );
        break;

      case 'update':
      case 'news':
      case 'legal_update':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpdatesScreen()),
        );
        break;

      case 'post':
      case 'community':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommunityFeedScreen(showBackButton: true)),
        );
        break;

      case 'general':
      default:
        _showAnnouncementSheet(notif);
        break;
    }
  }

  void _showAnnouncementSheet(NotificationModel notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1E36).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFF0F1E36), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translation.t('legal_announcement'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC5A880),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.timeAgo(notif.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              notif.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1E36),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              notif.body,
              style: TextStyle(
                fontSize: 14.5,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  Translation.t('close'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type, String? refType) {
    final t = (refType?.isNotEmpty == true ? refType : type)?.toLowerCase() ?? 'general';
    switch (t) {
      case 'case':
      case 'judgment':
        return Icons.gavel_rounded;
      case 'act':
      case 'bare_act':
        return Icons.menu_book_rounded;
      case 'update':
      case 'news':
      case 'legal_update':
        return Icons.campaign_rounded;
      case 'post':
      case 'community':
        return Icons.forum_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getTypeColor(String? type, String? refType) {
    final t = (refType?.isNotEmpty == true ? refType : type)?.toLowerCase() ?? 'general';
    switch (t) {
      case 'case':
      case 'judgment':
        return const Color(0xFF2563EB); // Blue
      case 'act':
      case 'bare_act':
        return const Color(0xFF059669); // Green
      case 'update':
      case 'news':
      case 'legal_update':
        return const Color(0xFFD97706); // Amber
      case 'post':
      case 'community':
        return const Color(0xFF7C3AED); // Purple
      default:
        return const Color(0xFF0F1E36); // Navy
    }
  }

  String _getTypeLabel(String? type, String? refType) {
    final t = (refType?.isNotEmpty == true ? refType : type)?.toLowerCase() ?? 'general';
    switch (t) {
      case 'case':
      case 'judgment':
        return Translation.t('landmark_judgments');
      case 'act':
      case 'bare_act':
        return Translation.t('key_bare_acts');
      case 'update':
      case 'news':
      case 'legal_update':
        return Translation.t('verified_legal_updates');
      case 'post':
      case 'community':
        return Translation.t('posts');
      default:
        return Translation.t('legal_announcement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F1E36),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              Translation.t('notifications'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F1E36),
              ),
            ),
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
                  if (unreadCount == 0) return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(Icons.done_all_rounded, color: Color(0xFF0F1E36)),
                    tooltip: Translation.t('mark_all_as_read'),
                    onPressed: () {
                      context.read<NotificationBloc>().add(const MarkAllNotificationsAsReadEvent());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(Translation.t('mark_all_as_read')),
                          backgroundColor: const Color(0xFF0F1E36),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F1E36)),
                onPressed: () {
                  context.read<NotificationBloc>().add(const LoadNotificationsEvent(isRefresh: true));
                },
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', Translation.t('all_notifications')),
                      const SizedBox(width: 8),
                      _buildFilterChip('unread', Translation.t('unread_notifications')),
                      const SizedBox(width: 8),
                      _buildFilterChip('case', Translation.t('landmark_judgments')),
                      const SizedBox(width: 8),
                      _buildFilterChip('act', Translation.t('key_bare_acts')),
                      const SizedBox(width: 8),
                      _buildFilterChip('update', Translation.t('verified_legal_updates')),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Notification List Body
              Expanded(
                child: BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F1E36)),
                        ),
                      );
                    }

                    if (state is NotificationError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(state.message, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(const LoadNotificationsEvent());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F1E36),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(Translation.t('view_all')),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is NotificationLoaded) {
                      var items = state.notifications;

                      // Apply active filter
                      if (_selectedFilter == 'unread') {
                        items = items.where((i) => !i.isRead).toList();
                      } else if (_selectedFilter != 'all') {
                        items = items.where((i) {
                          final type = (i.refType?.isNotEmpty == true ? i.refType : i.type)?.toLowerCase();
                          return type == _selectedFilter;
                        }).toList();
                      }

                      if (items.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<NotificationBloc>().add(const LoadNotificationsEvent(isRefresh: true));
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F1E36).withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.notifications_off_outlined,
                                          size: 52,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        Translation.t('no_notifications'),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F1E36),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Translation.t('no_notifications_subtitle'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<NotificationBloc>().add(const LoadNotificationsEvent(isRefresh: true));
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = items[index];
                            return _buildNotificationCard(context, notif);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F1E36) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif) {
    final color = _getTypeColor(notif.type, notif.refType);
    final icon = _getTypeIcon(notif.type, notif.refType);
    final label = _getTypeLabel(notif.type, notif.refType);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        context.read<NotificationBloc>().add(DeleteNotificationEvent(notif.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translation.t('notification_dismissed')),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F1E36),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
              width: notif.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Title, Body, Category & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Text(
                          DateFormatter.timeAgo(notif.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: const Color(0xFF0F1E36),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread Indicator Dot
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
