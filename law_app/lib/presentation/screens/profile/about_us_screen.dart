import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/scales_logo.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Center(child: ScalesLogo(size: 80)),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: GoogleFonts.merriweather(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.appTagline,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Mission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rishikesh Law Hub was founded to make legal knowledge, landmark judgments, bare acts, and legal precedents accessible, structured, and easy to understand for every law student, advocate, and aspiring legal professional across India.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '"${AppConstants.profileQuoteTop}"',
                          style: GoogleFonts.merriweather(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.profileQuoteTopAuthor,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
