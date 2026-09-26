import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/update/update_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/update_model.dart';
import '../../core/utils/url_helper.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  String _selectedCourt = 'All';
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

  final List<String> _courts = ['All', 'Supreme Court', 'High Court'];
  final List<String> _categories = ['All', 'Judgments', 'Government Notifications', 'Amendments', 'New Rules'];

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchUpdates() {
    context.read<UpdateBloc>().add(
          LoadUpdatesEvent(
            court: _selectedCourt == 'All' ? null : _selectedCourt,
            category: _selectedCategory == 'All' ? null : _selectedCategory,
          ),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<UpdateBloc>().state;
    if (state is UpdateLoaded && state.hasMore) {
      context.read<UpdateBloc>().add(
            LoadUpdatesEvent(
              court: _selectedCourt == 'All' ? null : _selectedCourt,
              category: _selectedCategory == 'All' ? null : _selectedCategory,
              page: state.page + 1,
              isNewLoad: false,
            ),
          );
    }
  }

  void _openSourceUrl(String? url) => UrlHelper.openInAppUrl(context, url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Legal Updates & News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUpdates,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _courts.map((court) {
                      final isSelected = _selectedCourt == court;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(court),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCourt = court);
                              _fetchUpdates();
                            }
                          },
                          selectedColor: AppColors.primaryNavy,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primaryNavy,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.borderLight),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = selected ? cat : 'All');
                            _fetchUpdates();
                          },
                          selectedColor: AppColors.goldAccent.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11.5,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? AppColors.goldAccent : AppColors.borderLight),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Updates List
          Expanded(
            child: BlocBuilder<UpdateBloc, UpdateState>(
              builder: (context, state) {
                if (state is UpdateLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                }

                if (state is UpdateError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchUpdates, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                if (state is UpdateLoaded) {
                  if (state.updates.isEmpty) {
                    return const Center(child: Text('No legal updates found.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.updates.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == state.updates.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2)),
                        );
                      }
                      final u = state.updates[idx];
                      return _buildUpdateCard(u);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(UpdateModel u) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    u.category,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  u.source,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (u.verificationStatus == 'verified') ...[
                  const Icon(Icons.verified, size: 15, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Text('Verified', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              u.title,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.primaryNavy, height: 1.3),
            ),
            if (u.summary != null && u.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                u.summary!,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.45),
              ),
            ],
            if (u.sourceUrl != null && u.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openSourceUrl(u.sourceUrl),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read Official Source',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 14, color: AppColors.goldAccent),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
