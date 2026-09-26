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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.scale_rounded, color: AppColors.goldAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Rishikesh Law Hub',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final name = state is Authenticated ? state.user.name : 'Advocate';
                        return Text(
                          'Namaste, $name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search judgments, bare acts, and legal precedents',
                      style: TextStyle(fontSize: 13, color: AppColors.goldAccentLight),
                    ),
                    const SizedBox(height: 16),

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
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textMuted, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search case name, citation, or keywords...',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                              ),
                            ),
                            Icon(Icons.tune_rounded, color: AppColors.primaryNavy, size: 20),
                          ],
                        ),
                      ),
                    ),
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

