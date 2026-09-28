import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:law_app/blocs/notification/notification_bloc.dart';
import 'package:law_app/core/theme/app_theme.dart';
import 'package:law_app/core/theme/theme_manager.dart';
import 'package:law_app/core/translations/translation.dart';
import 'package:law_app/core/utils/date_formatter.dart';
import 'package:law_app/models/notification_model.dart';
import 'package:law_app/screens/cases/case_detail_screen.dart';
import 'package:law_app/screens/cases/case_search_screen.dart';
import 'package:law_app/screens/acts/acts_list_screen.dart';
import 'package:law_app/screens/updates/updates_screen.dart';
import 'package:law_app/screens/community/community_feed_screen.dart';
import 'package:law_app/screens/profile/public_user_profile_screen.dart';

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

      case 'user':
        if (notif.refId != null && notif.refId!.isNotEmpty && notif.refId != 'general') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PublicUserProfileScreen(userId: notif.refId!)),
          );
        } else {
          _showAnnouncementSheet(notif);
        }
        break;

      case 'general':
      default:
        _showAnnouncementSheet(notif);
        break;
    }
  }

  void _showAnnouncementSheet(NotificationModel notif) {
    final isDark = ThemeManager.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D2D) : Colors.white,
          borderRadius: const BorderRadius.only(
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
                  color: isDark ? const Color(0xFF23354E) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2F4D) : const Color(0xFF0F1E36).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
                    size: 24,
                  ),
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
                          color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              notif.body,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
                  foregroundColor: isDark ? const Color(0xFF090E17) : Colors.white,
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

  Color _getTypeColor(String? type, String? refType, bool isDark) {
    final t = (refType?.isNotEmpty == true ? refType : type)?.toLowerCase() ?? 'general';
    switch (t) {
      case 'case':
      case 'judgment':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB); // Blue
      case 'act':
      case 'bare_act':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669); // Green
      case 'update':
      case 'news':
      case 'legal_update':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706); // Amber
      case 'post':
      case 'community':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED); // Purple
      default:
        return isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36);
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
      listenable: Listenable.merge([Translation.instance, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final bgColor = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
        final surfaceColor = isDark ? const Color(0xFF0F1827) : Colors.white;
        final borderColor = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36);
        final iconColor = isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            surfaceTintColor: surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 20, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              Translation.t('notifications'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textColor,
              ),
            ),
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
                  if (unreadCount == 0) return const SizedBox.shrink();

                  return IconButton(
                    icon: Icon(Icons.done_all_rounded, color: iconColor),
                    tooltip: Translation.t('mark_all_as_read'),
                    onPressed: () {
                      context.read<NotificationBloc>().add(const MarkAllNotificationsAsReadEvent());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(Translation.t('mark_all_as_read')),
                          backgroundColor: isDark ? const Color(0xFF131D2D) : const Color(0xFF0F1E36),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: iconColor),
                onPressed: () {
                  context.read<NotificationBloc>().add(const LoadNotificationsEvent(isRefresh: true));
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: borderColor),
            ),
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                color: surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', Translation.t('all_notifications'), isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('unread', Translation.t('unread_notifications'), isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('case', Translation.t('landmark_judgments'), isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('act', Translation.t('key_bare_acts'), isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('update', Translation.t('verified_legal_updates'), isDark),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Notification List Body
              Expanded(
                child: BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
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
                                backgroundColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
                                foregroundColor: isDark ? const Color(0xFF090E17) : Colors.white,
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
                                          color: isDark
                                              ? const Color(0xFF131D2D)
                                              : const Color(0xFF0F1E36).withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.notifications_off_outlined,
                                          size: 52,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        Translation.t('no_notifications'),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Translation.t('no_notifications_subtitle'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                            return _buildNotificationCard(context, notif, isDark);
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

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _selectedFilter == filterKey;
    final selectedBg = isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36);
    final selectedText = isDark ? const Color(0xFF090E17) : Colors.white;
    final unselectedBg = isDark ? const Color(0xFF131D2D) : const Color(0xFFF1F5F9);
    final unselectedBorder = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBg : unselectedBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? selectedText : unselectedText,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif, bool isDark) {
    final color = _getTypeColor(notif.type, notif.refType, isDark);
    final icon = _getTypeIcon(notif.type, notif.refType);
    final label = _getTypeLabel(notif.type, notif.refType);

    final cardBg = notif.isRead
        ? (isDark ? const Color(0xFF131D2D) : Colors.white)
        : (isDark ? const Color(0xFF18263B) : const Color(0xFFF0F7FF));

    final cardBorder = notif.isRead
        ? (isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0))
        : (isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE));

    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36);
    final bodyColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
            backgroundColor: isDark ? const Color(0xFF131D2D) : const Color(0xFF0F1E36),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBorder,
              width: notif.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
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
                            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: bodyColor,
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
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
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
