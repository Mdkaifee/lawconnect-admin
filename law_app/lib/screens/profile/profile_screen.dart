import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/utils/url_helper.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../auth/login_screen.dart';
import '../community/community_feed_screen.dart';
import 'about_us_screen.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

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
          const SnackBar(
            content: Text('Contact support: rishikesh4287@gmail.com'),
            backgroundColor: Color(0xFF0F1E36),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          final userName = user?.name.isNotEmpty == true ? user!.name : 'Rishikesh Yadav';
          final college = user?.college ?? 'Galgotias University';

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
                            color: const Color(0xFF0F1E36),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F1E36),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Law Student | Future Advocate',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                college,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Menu Items List (matching exact mockup)
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmark_border_rounded,
                    title: 'My Posts',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CommunityFeedScreen(showBackButton: true)),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'My Notes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotesScreen(showBackButton: true)),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Bookmarks',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BookmarksScreen(showBackButton: true)),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Reading History',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_outline_rounded,
                    title: 'Users',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UsersScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: () => UrlHelper.openInAppUrl(
                      context,
                      'https://rishikesh-law-hub-admin.onrender.com/privacy-policy',
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => _openGmailSupport(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    onTap: () {
                      CustomConfirmationDialog.show(
                        context,
                        title: 'Confirm Sign Out',
                        message: 'Are you sure you want to log out of Rishikesh Law Hub?',
                        confirmText: 'Log Out',
                        cancelText: 'Cancel',
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
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(icon, color: const Color(0xFF0F1E36), size: 22),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1E36),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 20, endIndent: 20),
      ],
    );
  }
}
