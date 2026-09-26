import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../auth/login_screen.dart';
import 'notes_screen.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Advocate Profile'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Advocate User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.college ?? 'Galgotias University',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldAccent),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Navigation Options
                _buildOptionTile(
                  context,
                  icon: Icons.bookmark_rounded,
                  iconColor: AppColors.goldAccent,
                  title: 'Saved Bookmarks',
                  subtitle: 'Judgments, sections & case references',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),

                _buildOptionTile(
                  context,
                  icon: Icons.edit_note_rounded,
                  iconColor: Colors.blue.shade700,
                  title: 'Case Study Notes',
                  subtitle: 'Personal insights & legal briefs',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),

                _buildOptionTile(
                  context,
                  icon: Icons.history_rounded,
                  iconColor: Colors.purple.shade700,
                  title: 'Reading History',
                  subtitle: 'Recently viewed legal documents',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Logout Button with Custom Confirmation Dialog
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      CustomConfirmationDialog.show(
                        context,
                        title: 'Confirm Logout',
                        message: 'Are you sure you want to sign out of your Rishikesh Law Hub account?',
                        confirmText: 'Sign Out',
                        cancelText: 'Cancel',
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.danger,
                        onConfirm: () {
                          context.read<AuthBloc>().add(LogoutEvent());
                        },
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.primaryNavy),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
