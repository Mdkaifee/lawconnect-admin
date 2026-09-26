import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../common_widgets/custom_dialog.dart';
import '../auth/login_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../notes/notes_screen.dart';
import '../posts/posts_screen.dart';
import 'about_us_screen.dart';
import 'help_support_screen.dart';
import 'reading_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context) {
    CustomConfirmDialog.show(
      context,
      title: 'Confirm Log Out',
      message: 'Are you sure you want to log out of Rishikesh Law Hub?',
      confirmText: 'Log Out',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<AuthBloc>().add(LogoutEvent());
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;
        final name = user?.name ?? 'Rishikesh Yadav';
        final headline = user?.headline ?? 'Law Student | Future Advocate';
        final college = user?.college ?? 'Galgotias University';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile & Settings'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'R',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              headline,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              college,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu Items
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.article_outlined,
                        title: 'My Posts',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PostsScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.note_alt_outlined,
                        title: 'My Notes',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotesScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.bookmark_outline,
                        title: 'Bookmarks',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.history_rounded,
                        title: 'Reading History',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'About Us',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom Quote Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppConstants.profileQuoteBottom,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.merriweather(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withAlpha(230),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.profileQuoteBottomAuthor,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primaryNavy, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, color: AppColors.borderLight);
  }
}
