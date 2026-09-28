import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/translations/translation.dart';
import '../../core/utils/url_helper.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/app_version_text.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationService.instance.isEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService.instance.setEnabled(value, context.read<AuthRepository>());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Translation.t(value ? 'notifications_enabled' : 'notifications_disabled')),
        backgroundColor: const Color(0xFF0F1E36),
      ),
    );
  }

  void _showLanguageDialog() {
    final isDark = ThemeManager.instance.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131D2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          Translation.t('select_language'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLanguage>(
              contentPadding: EdgeInsets.zero,
              title: Text(
                Translation.t('english_default'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36),
                ),
              ),
              value: AppLanguage.english,
              groupValue: Translation.instance.language,
              activeColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
              onChanged: (val) async {
                if (val == null) return;
                await Translation.instance.setLanguage(val);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
            ),
            RadioListTile<AppLanguage>(
              contentPadding: EdgeInsets.zero,
              title: Text(
                Translation.t('hindi'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36),
                ),
              ),
              value: AppLanguage.hindi,
              groupValue: Translation.instance.language,
              activeColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
              onChanged: (val) async {
                if (val == null) return;
                await Translation.instance.setLanguage(val);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Translation.t('cache_cleared')),
        backgroundColor: const Color(0xFF0F1E36),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteAccount() {
    CustomConfirmationDialog.show(
      context,
      title: Translation.t('delete_account_title'),
      message: Translation.t('delete_account_confirm_message'),
      confirmText: Translation.t('delete'),
      cancelText: Translation.t('cancel'),
      icon: Icons.delete_forever_rounded,
      iconColor: const Color(0xFFDC2626),
      onConfirm: () {
        context.read<AuthBloc>().add(
              const DeleteAccountEvent(reason: 'User requested account deletion from app settings'),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Translation.instance, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final cardColor = isDark ? const Color(0xFF131D2D) : Colors.white;
        final borderColor = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36);
        final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final iconColor = isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36);
        final dividerColor = isDark ? const Color(0xFF1E2F4D) : const Color(0xFFF1F5F9);

        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            }
            if (state is Unauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF0F1827) : Colors.white,
              foregroundColor: textColor,
              surfaceTintColor: isDark ? const Color(0xFF0F1827) : Colors.white,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                Translation.t('settings'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: borderColor),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildSectionHeader(Translation.t('preferences'), subtitleColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(Icons.notifications_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('push_notifications'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        subtitle: Text(
                          Translation.t('push_notifications_subtitle'),
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                        value: _notificationsEnabled,
                        activeColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
                        onChanged: _setNotificationsEnabled,
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      SwitchListTile(
                        secondary: Icon(Icons.dark_mode_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('dark_mode'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        subtitle: Text(
                          Translation.t('dark_mode_subtitle'),
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                        value: isDark,
                        activeColor: isDark ? AppColors.goldAccentLight : const Color(0xFF0F1E36),
                        onChanged: (value) async {
                          await ThemeManager.instance.toggleDarkMode(value);
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.language_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('language'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        subtitle: Text(
                          Translation.instance.currentLanguageLabel,
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                        trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
                        onTap: _showLanguageDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(Translation.t('storage_data'), subtitleColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.cleaning_services_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('clear_cached_judgments'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        subtitle: Text(
                          Translation.t('clear_cached_judgments_subtitle'),
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                        trailing: Icon(Icons.delete_outline_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
                        onTap: _clearCache,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(Translation.t('account_management'), subtitleColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E141D) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF5A2328) : const Color(0xFFFECACA)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFFDC2626), size: 22),
                    title: Text(
                      Translation.t('delete_account'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFFDC2626)),
                    ),
                    subtitle: Text(
                      Translation.t('delete_account_subtitle'),
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFDC2626), size: 20),
                    onTap: _confirmDeleteAccount,
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(Translation.t('about_legal'), subtitleColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.verified_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('app_version'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        trailing: AppVersionText(
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subtitleColor),
                        ),
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.shield_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('privacy_policy'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
                        onTap: () => UrlHelper.openInAppUrl(context, ApiConstants.privacyPolicyUrl),
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.description_outlined, color: iconColor, size: 22),
                        title: Text(
                          Translation.t('terms_of_service'),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                        ),
                        trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
                        onTap: () => UrlHelper.openInAppUrl(context, ApiConstants.termsOfServiceUrl),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
