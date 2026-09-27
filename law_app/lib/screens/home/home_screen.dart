import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/act/act_bloc.dart';
import '../../blocs/update/update_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/url_helper.dart';
import '../cases/case_search_screen.dart';
import '../cases/case_detail_screen.dart';
import '../acts/act_detail_screen.dart';
import '../acts/acts_list_screen.dart';
import '../community/community_feed_screen.dart';
import '../profile/about_us_screen.dart';
import '../profile/bookmarks_screen.dart';
import '../profile/history_screen.dart';
import '../profile/notes_screen.dart';
import '../profile/settings_screen.dart';
import '../../widgets/case_card.dart';
import '../../widgets/custom_confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CaseBloc>().add(LoadCuratedLandmarksEvent());
    context.read<ActBloc>().add(const LoadActsEvent());
    context.read<UpdateBloc>().add(const LoadUpdatesEvent());
    context.read<PostBloc>().add(const LoadPostsEvent());
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
  }

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

  Widget _buildDrawerMenuItem(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state is Authenticated ? state.user : null;
              final userName = user?.name.isNotEmpty == true ? user!.name : 'Rishikesh Yadav';
              final college = user?.college ?? 'Galgotias University';

              return SingleChildScrollView(
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
                            width: 54,
                            height: 54,
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name & Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F1E36),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Law Student | Future Advocate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  college,
                                  style: const TextStyle(
                                    fontSize: 11.5,
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

                    // Menu Items List (matching exact profile screen)
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.bookmark_border_rounded,
                      title: 'My Posts',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CommunityFeedScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'My Notes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotesScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Bookmarks',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookmarksScreen(showBackButton: true)),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Reading History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pop(context);
                        UrlHelper.openInAppUrl(
                          context,
                          'https://rishikesh-law-hub-admin.onrender.com/privacy-policy',
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _openGmailSupport(context);
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                        );
                      },
                    ),
                    _buildDrawerMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      onTap: () {
                        Navigator.pop(context);
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
              );
            },
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryNavy),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
              final name = state is Authenticated ? state.user.name : 'Advocate';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Good Morning,', style: TextStyle(fontSize: 11, color: AppColors.primaryNavy)),
                Row(children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryNavy)),
                  const SizedBox(width: 3),
                  const Icon(Icons.waving_hand_rounded, size: 13, color: AppColors.goldAccent),
                ]),
                const Text('Learn • Explore • Grow', style: TextStyle(fontSize: 9, color: AppColors.primaryNavy)),
              ]);
            }),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryNavy),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CaseBloc>().add(LoadCuratedLandmarksEvent());
          context.read<ActBloc>().add(const LoadActsEvent());
          context.read<UpdateBloc>().add(const LoadUpdatesEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Greeting & Quick Search
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Search Bar
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CaseSearchScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textMuted, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search case name, citation, or keywords...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Reference-style quote and court banner.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/sci.png'),
                    fit: BoxFit.cover,
                    opacity: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '“The Constitution is not a mere lawyers’ document, it is a vehicle of life, and its spirit is always the spirit of the age.”\n\n— Dr. B.R. Ambedkar',
                          style: TextStyle(color: AppColors.primaryNavy, fontSize: 12, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Reference-style legal category grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: const [
                    _HomeCategory(icon: Icons.menu_book_rounded, label: 'Constitution', color: Colors.blue),
                    _HomeCategory(icon: Icons.gavel_rounded, label: 'Criminal Law', color: Colors.orange),
                    _HomeCategory(icon: Icons.handshake_rounded, label: 'Contract', color: Colors.green),
                    _HomeCategory(icon: Icons.account_balance_rounded, label: 'Torts', color: Colors.indigo),
                    _HomeCategory(icon: Icons.family_restroom_rounded, label: 'Family Law', color: Colors.deepPurple),
                    _HomeCategory(icon: Icons.work_outline_rounded, label: 'Labour Law', color: Colors.redAccent),
                    _HomeCategory(icon: Icons.eco_outlined, label: 'Environment', color: Colors.teal),
                    _HomeCategory(icon: Icons.more_horiz_rounded, label: 'More', color: Colors.pinkAccent),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bare Acts Quick Access
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Key Bare Acts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActsListScreen()),
                        );
                        if (mounted) context.read<ActBloc>().add(const LoadActsEvent());
                      },
                      child: const Text('View All', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              BlocBuilder<ActBloc, ActState>(
                builder: (context, state) {
                  if (state is ActListLoaded && state.acts.isNotEmpty) {
                    return SizedBox(
                      height: 105,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.acts.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, idx) {
                          final act = state.acts[idx];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ActDetailScreen(actId: act.id, actName: act.name)),
                              );
                            },
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.book_outlined, color: AppColors.goldAccent, size: 22),
                                  const SizedBox(height: 6),
                                  Text(
                                    act.shortName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.primaryNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${act.sectionsCount} Sections',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  if (state is ActInitial || state is ActLoading) {
                    return const SizedBox(
                      height: 105,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
                    );
                  }
                  if (state is ActError) {
                    return const SizedBox(
                      height: 105,
                      child: Center(child: Text('Unable to load bare acts', style: TextStyle(color: AppColors.textMuted))),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              // Landmark Judgments Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Landmark Judgments',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              BlocBuilder<CaseBloc, CaseState>(
                builder: (context, state) {
                  if (state is CaseLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primaryNavy),
                      ),
                    );
                  }
                  if (state is CaseSearchSuccess && state.items.isNotEmpty) {
                    return Column(
                      children: state.items.take(4).map((c) {
                        return CaseCard(
                          caseItem: c,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: c.id)),
                            );
                          },
                        );
                      }).toList(),
                    );
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No landmark judgments available right now.'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Verified Legal Updates Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Verified Legal Updates',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<UpdateBloc, UpdateState>(
                builder: (context, state) {
                  if (state is UpdateLoaded && state.updates.isNotEmpty) {
                    return Column(
                      children: state.updates.take(3).map((u) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.article_outlined, color: AppColors.primaryNavy, size: 22),
                            ),
                            title: Text(
                              u.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${u.source} • ${u.category}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HomeCategory({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 5),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
      ],
    );
  }
}
