import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use Rishikesh Law Hub',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '• Search Cases: Use the Search tab or Home bar to find judgments by citation, party names, or bench.\n'
                  '• Bare Acts: Explore Constitution, IPC/BNS, BNSS, Evidence, Contract and Torts with simplified explanations.\n'
                  '• Community: Post queries, case analysis, and connect with fellow law students and advocates.\n'
                  '• Bookmarks & Notes: Save important sections and judgments to your profile for offline revision.',
                  style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Have feedback, bug reports or request for new bare acts? Reach out to our legal tech team.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'contact@rishikeshlawhub.com',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
