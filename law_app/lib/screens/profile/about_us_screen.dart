import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _openEmailSupport(BuildContext context) async {
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
            content: Text('Contact: rishikesh4287@gmail.com'),
            backgroundColor: Color(0xFF0F1E36),
          ),
        );
      }
    }
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
          'About Us',
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
          // App Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F1E36),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1E36),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F1E36).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gavel_rounded,
                      color: Color(0xFFC5A880),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Rishikesh Law Hub',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1E36),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Smart Legal Research & Case Law Platform',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Version 1.0.0 (Build 2026)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Creator & Founder Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1E36), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1E36).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A880),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'RY',
                          style: TextStyle(
                            color: Color(0xFF0F1E36),
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rishikesh Yadav',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Founder & Lead Developer',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC5A880),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '1st Year Law Student • Galgotias University',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0x26FFFFFF), height: 1),
                const SizedBox(height: 14),
                const Text(
                  'About the Founder',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC5A880),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rishikesh Yadav is an ambitious, driven 1st-year Law student at Galgotias University with a stellar academic mindset and a passion for Indian jurisprudence, constitutional law, and CLAT excellence. Combining sharp legal acumen with a passion for modern software engineering, Rishikesh designed and developed Rishikesh Law Hub to empower law students, advocates, and judicial aspirants with instant, verified legal intelligence at their fingertips.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDarkBadge('Galgotias University'),
                    _buildDarkBadge('CLAT Aspirant Guide'),
                    _buildDarkBadge('Constitutional Law'),
                    _buildDarkBadge('Legal Tech Pioneer'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About App & Mission
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: Color(0xFF0F1E36), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1E36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rishikesh Law Hub was built with a singular vision: to make legal study and case law research intuitive, fast, and structured for everyone in the legal fraternity. From landmark Supreme Court judgments to comprehensive Bare Acts and personal research notes, everything is organized in one seamless experience.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                _buildFeatureRow(
                  Icons.balance_rounded,
                  'Landmark Judgments',
                  'Supreme Court & High Court cases with bench info, citations, and full text analysis.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  Icons.menu_book_rounded,
                  'Bare Acts & Statutes',
                  'Instant search across IPC, CrPC, CPC, Constitution of India, BNS, and more.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  Icons.edit_note_rounded,
                  'Case Briefs & Study Notes',
                  'Draft, categorize, and organize your personal case notes and argument outlines.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  Icons.forum_rounded,
                  'Legal Community Feed',
                  'Exchange knowledge, ask questions, and discuss ongoing legal developments.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Connect / Support Button
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Have Questions or Suggestions?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1E36),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'We value feedback from students, advocates, and professors to make Law Hub even better.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _openEmailSupport(context),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text(
                      'Contact Rishikesh directly',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1E36),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          const Center(
            child: Text(
              'Crafted with dedication by Rishikesh Yadav\nGalgotias University • Class of 2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _buildDarkBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  static Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0F1E36)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1E36),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
