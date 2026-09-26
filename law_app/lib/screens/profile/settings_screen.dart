import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1E36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('English (Default)', style: TextStyle(fontWeight: FontWeight.w600)),
                value: 'English',
                groupValue: _selectedLanguage,
                activeColor: const Color(0xFF0F1E36),
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('Hindi (हिंदी)', style: TextStyle(fontWeight: FontWeight.w600)),
                value: 'Hindi',
                groupValue: _selectedLanguage,
                activeColor: const Color(0xFF0F1E36),
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline judgment cache cleared successfully'),
        backgroundColor: Color(0xFF0F1E36),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F1E36),
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F1E36)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0F1E36),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader('PREFERENCES'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: const Text(
                    'Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  subtitle: const Text(
                    'Daily legal updates & new judgments',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFF0F1E36),
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  subtitle: const Text(
                    'Easier reading for long legal briefs',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: _darkModeEnabled,
                  activeColor: const Color(0xFF0F1E36),
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: const Text(
                    'Language',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  subtitle: Text(
                    _selectedLanguage,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                  onTap: _showLanguageDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('STORAGE & DATA'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: const Text(
                    'Clear Cached Judgments',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  subtitle: const Text(
                    'Free up local device storage (4.2 MB)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                  onTap: _clearCache,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('ABOUT & LEGAL'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.verified_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: Text(
                    'App Version',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  trailing: Text(
                    'v1.0.0 (Build 2026)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: Color(0xFF0F1E36), size: 22),
                  title: Text(
                    'Terms of Service',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F1E36)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
