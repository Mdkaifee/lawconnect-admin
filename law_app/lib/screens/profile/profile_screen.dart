import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../auth/login_screen.dart';
import '../community/community_feed_screen.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';
import 'notes_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFF0F1E36)),
            SizedBox(width: 10),
            Text('About Law Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Law Hub',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F1E36)),
            ),
            SizedBox(height: 4),
            Text('Version 1.0.0 (Build 2026)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            SizedBox(height: 12),
            Text(
              'A modern legal research and study hub for law students, advocates, and legal professionals. Sourced from official court repositories with verified legal updates, acts, and personal briefs.',
              style: TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1E36),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance with Law Hub?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            SizedBox(height: 8),
            Text(
              '• For feedback & queries: support@rishikeshlawhub.in\n• Case judgments are fetched and cached for offline reading.\n• Use the Notes section to draft arguments and case briefs.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1E36),
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F1E36)),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined, color: Color(0xFF0F1E36)),
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: Switch(value: true, activeColor: const Color(0xFF0F1E36), onChanged: (val) {}),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dark_mode_outlined, color: Color(0xFF0F1E36)),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: Switch(value: false, activeColor: const Color(0xFF0F1E36), onChanged: (val) {}),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_outlined, color: Color(0xFF0F1E36)),
              title: const Text('Language: English / Hindi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              onTap: () {},
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
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
                  const SizedBox(height: 12),
                  // Top Profile Header Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Avatar Photo / Initials
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
                                  fontSize: 18,
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

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

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
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => _showSettingsDialog(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => _showHelpDialog(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    onTap: () {
                      CustomConfirmationDialog.show(
                        context,
                        title: 'Confirm Sign Out',
                        message: 'Are you sure you want to log out of Law Hub?',
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
