import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/update/update_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
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
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: AppTheme.textPrimaryColor(context),
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        title: Text(
          Translation.t('legal_updates_news'),
          style: TextStyle(
            color: AppTheme.textPrimaryColor(context),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryOrGold),
            onPressed: _fetchUpdates,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cardBg,
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
                          selectedColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
                          checkmarkColor: isDark ? AppColors.primaryNavyDark : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.primaryNavyDark : Colors.white)
                                : AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: cardBg,
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? AppColors.goldAccent : AppColors.primaryNavy)
                                : AppTheme.borderColor(context),
                          ),
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
                          selectedColor: isDark
                              ? AppColors.goldAccent.withValues(alpha: 0.3)
                              : AppColors.goldAccent.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.goldAccentLight : AppColors.primaryNavy)
                                : AppTheme.textSecondaryColor(context),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11.5,
                          ),
                          backgroundColor: cardBg,
                          side: BorderSide(
                            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor(context),
                          ),
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
                  return Center(child: CircularProgressIndicator(color: primaryOrGold));
                }

                if (state is UpdateError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(state.message, style: TextStyle(color: AppTheme.textPrimaryColor(context))),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchUpdates, child: Text(Translation.t('retry'))),
                      ],
                    ),
                  );
                }

                if (state is UpdateLoaded) {
                  if (state.updates.isEmpty) {
                    return Center(
                      child: Text(
                        Translation.t('no_legal_updates'),
                        style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: primaryOrGold,
                    onRefresh: () async => _fetchUpdates(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.updates.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx == state.updates.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: primaryOrGold, strokeWidth: 2)),
                          );
                        }
                        final u = state.updates[idx];
                        return _buildUpdateCard(u, context);
                      },
                    ),
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

  Widget _buildUpdateCard(UpdateModel u, BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);

    return Card(
      elevation: 0,
      color: AppTheme.cardColor(context),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor(context)),
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
                    color: isDark
                        ? AppColors.goldAccent.withValues(alpha: 0.15)
                        : AppColors.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    u.category,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: primaryOrGold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    u.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                if (u.verificationStatus == 'verified') ...[
                  const Icon(Icons.verified, size: 15, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(Translation.t('verified'), style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              u.title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
                height: 1.3,
              ),
            ),
            if (u.summary != null && u.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                u.summary!,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.45,
                ),
              ),
            ],
            if (u.sourceUrl != null && u.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openSourceUrl(u.sourceUrl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Translation.t('read_official_source'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.goldAccentLight : AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: isDark ? AppColors.goldAccentLight : AppColors.goldAccent,
                    ),
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
