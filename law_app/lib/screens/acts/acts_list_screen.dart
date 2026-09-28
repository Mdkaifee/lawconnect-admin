import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/act/act_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/act_card.dart';
import 'act_detail_screen.dart';

class ActsListScreen extends StatefulWidget {
  const ActsListScreen({super.key});

  @override
  State<ActsListScreen> createState() => _ActsListScreenState();
}

class _ActsListScreenState extends State<ActsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedType = 'All';
  final List<String> _typeFilters = ['All', 'Central', 'State'];

  @override
  void initState() {
    super.initState();
    _fetchActs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchActs() {
    context.read<ActBloc>().add(
          LoadActsEvent(
            query: _searchController.text.trim(),
            type: _selectedType == 'All' ? null : _selectedType,
          ),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<ActBloc>().state;
    if (state is ActListLoaded && state.hasMore) {
      context.read<ActBloc>().add(
            LoadActsEvent(
              query: _searchController.text.trim(),
              type: _selectedType == 'All' ? null : _selectedType,
              page: state.page + 1,
              isNewLoad: false,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bare Acts & Codes',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
            onPressed: _fetchActs,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchActs(),
                  decoration: InputDecoration(
                    hintText: 'Search Bare Acts (e.g. BNS, Contract, Constitution)...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryNavy),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchActs();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _typeFilters.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type == 'All' ? 'All Acts' : '$type Acts'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                            _fetchActs();
                          }
                        },
                        selectedColor: AppColors.primaryNavy,
                        checkmarkColor: Colors.white,
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
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ActBloc, ActState>(
              builder: (context, state) {
                if (state is ActLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                }

                if (state is ActError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchActs, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                if (state is ActListLoaded) {
                  if (state.acts.isEmpty) {
                    return const Center(
                      child: Text('No Bare Acts found matching criteria.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _fetchActs(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: state.acts.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                      if (idx == state.acts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2)),
                        );
                      }
                        final act = state.acts[idx];
                        return ActCard(
                        act: act,
                          onTap: () {
                            Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ActDetailScreen(actId: act.id, actName: act.name),
                            ),
                            );
                          },
                        );
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
}

