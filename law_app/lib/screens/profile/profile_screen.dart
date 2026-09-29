import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/url_helper.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../community/community_feed_screen.dart';
import 'about_us_screen.dart';
import 'bookmarks_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';
import '../notifications/notifications_screen.dart';
import '../messages/messages_screen.dart';
import '../messages/ai_chat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openGmailSupport(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'rishikesh4287@gmail.com',
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translation.t('contact_support_email')),
            backgroundColor: const Color(0xFF0F1E36),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Translation.instance, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final bgColor = isDark ? const Color(0xFF090E17) : Colors.white;
        final borderColor = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36);
        final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final iconColor = isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36);
        final dividerColor = isDark ? const Color(0xFF1E2F4D) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state is Authenticated ? state.user : null;
              final userName = user?.name.isNotEmpty == true ? user!.name : 'User';
              final college = user?.college.trim() ?? '';
              final headline = user?.headline.trim() ?? '';
              final photoUrl = user?.photoUrl;

              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Top Profile Header Row (Avatar + Name + Subtitle)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Profile Avatar
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF1B283D) : const Color(0xFF0F1E36),
                                border: Border.all(color: borderColor, width: 2),
                                image: photoUrl != null && photoUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          color: isDark ? AppColors.goldAccentLight : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Name & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                userName,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: textColor),
                                              ),
                                            ),
                                            if (user?.isChatPaid == true) ...[
                                              const SizedBox(width: 5),
                                              const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF14B8A6)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (user != null)
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, size: 20, color: iconColor),
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (headline.isNotEmpty)
                                    Text(
                                      headline,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: textMuted,
                                      ),
                                    ),
                                  if (college.isNotEmpty)
                                    Text(
                                      college,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Divider(height: 1, color: dividerColor),

                      // Menu Items List
                      _buildMenuItem(
                        context,
                        icon: Icons.bookmark_border_rounded,
                        title: Translation.t('my_posts'),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CommunityFeedScreen(showBackButton: true)),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.assignment_outlined,
                        title: Translation.t('my_notes'),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotesScreen(showBackButton: true)),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.bookmark_outline_rounded,
                        title: Translation.t('bookmarks'),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BookmarksScreen(showBackButton: true)),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.history_rounded,
                        title: Translation.t('reading_history'),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.people_outline_rounded,
                        title: Translation.t('users'),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UsersScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.forum_outlined,
                        title: Translation.t('messages'),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MessagesScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Legal Chat',
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AiChatScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: Translation.t('notifications'),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: Translation.t('settings'),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.shield_outlined,
                        title: Translation.t('privacy_policy'),
                        isDark: isDark,
                        onTap: () => UrlHelper.openInAppUrl(
                          context,
                          'https://rishikesh-law-hub-admin.onrender.com/privacy-policy',
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: Translation.t('help_support'),
                        isDark: isDark,
                        onTap: () => _openGmailSupport(context),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: Translation.t('about_us'),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: Translation.t('log_out'),
                        isDark: isDark,
                        textColor: const Color(0xFFEF4444),
                        iconColor: const Color(0xFFEF4444),
                        onTap: () {
                          CustomConfirmationDialog.show(
                            context,
                            title: Translation.t('confirm_sign_out'),
                            message: Translation.t('confirm_sign_out_message'),
                            confirmText: Translation.t('log_out'),
                            cancelText: Translation.t('cancel'),
                            icon: Icons.logout_rounded,
                            iconColor: const Color(0xFFEF4444),
                            onConfirm: () {
                              context.read<AuthBloc>().add(LogoutEvent());
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
  }) {
    final defaultIconColor = iconColor ?? (isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36));
    final defaultTextColor = textColor ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36));
    final dividerColor = isDark ? const Color(0xFF1E2F4D) : const Color(0xFFF1F5F9);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(icon, color: defaultIconColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: defaultTextColor,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
          onTap: onTap,
        ),
        Divider(height: 1, color: dividerColor, indent: 20, endIndent: 20),
      ],
    );
  }
}
