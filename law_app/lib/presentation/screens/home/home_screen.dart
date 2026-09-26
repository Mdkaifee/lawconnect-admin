import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/legal_update_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../../logic/blocs/update/update_bloc.dart';
import '../../../logic/blocs/update/update_event.dart';
import '../../../logic/blocs/update/update_state.dart';
import '../acts/acts_screen.dart';
import '../cases/case_search_screen.dart';
import '../updates/updates_screen.dart';
import 'widgets/category_grid.dart';
import 'widgets/quote_banner.dart';
import 'widgets/updates_preview.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UpdateBloc>().add(const FetchUpdatesEvent(refresh: true));
  }

  void _onCategorySelected(LawCategory cat) {
    if (cat.slug == 'more') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActsScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaseSearchScreen(initialCategory: cat.slug),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<UpdateBloc>().add(const FetchUpdatesEvent(refresh: true));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting Header
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final name = state is Authenticated ? state.user.name : 'Rishikesh';
                    final firstName = name.split(' ').first;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Good Morning, $firstName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👋', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Learn  •  Explore  •  Grow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryNavy),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const UpdatesScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Search Bar Trigger
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
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textMuted, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Search Case / Section / Act...',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Ambedkar Quote Banner
                const QuoteBanner(),
                const SizedBox(height: 22),

                // Categories Grid
                CategoryGrid(onCategorySelected: _onCategorySelected),
                const SizedBox(height: 22),

                // Latest Legal Updates
                BlocBuilder<UpdateBloc, UpdateState>(
                  builder: (context, state) {
                    List<LegalUpdateModel> updates = [];
                    if (state is UpdatesLoaded) {
                      updates = state.updates;
                    }

                    return UpdatesPreviewList(
                      updates: updates,
                      onViewAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UpdatesScreen()),
                        );
                      },
                      onUpdateTap: (update) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UpdatesScreen()),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
