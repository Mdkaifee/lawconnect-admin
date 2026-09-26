import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/case/case_bloc.dart';
import '../../blocs/act/act_bloc.dart';
import '../../blocs/update/update_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cases/case_search_screen.dart';
import '../cases/case_detail_screen.dart';
import '../acts/act_detail_screen.dart';
import '../acts/acts_list_screen.dart';
import '../updates/updates_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/case_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primaryNavy),
                child: Align(alignment: Alignment.bottomLeft, child: Text('Rishikesh Law Hub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              ),
              ListTile(leading: const Icon(Icons.menu_book_rounded), title: const Text('Acts & Sections'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ActsListScreen())); }),
              ListTile(leading: const Icon(Icons.newspaper_rounded), title: const Text('Legal Updates'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdatesScreen())); }),
              ListTile(leading: const Icon(Icons.person_rounded), title: const Text('Profile'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primaryNavy),
          onPressed: () => Scaffold.of(context).openDrawer(),
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
                    image: AssetImage('assets/sci.jpeg'),
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
                      onPressed: () {
                        // Switch to acts tab or navigate
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
