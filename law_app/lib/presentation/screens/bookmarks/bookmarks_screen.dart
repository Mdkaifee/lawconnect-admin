import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../logic/blocs/bookmark/bookmark_bloc.dart';
import '../../../logic/blocs/bookmark/bookmark_event.dart';
import '../../../logic/blocs/bookmark/bookmark_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import '../cases/case_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Cases', 'Sections', 'Posts', 'Notes'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String _getRefType(int index) {
    switch (index) {
      case 0:
        return 'case';
      case 1:
        return 'section';
      case 2:
        return 'post';
      case 3:
        return 'note';
      default:
        return 'case';
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadBookmarks();
  }

  void _loadBookmarks() {
    context.read<BookmarkBloc>().add(
          FetchBookmarksEvent(refType: _getRefType(_tabController.index)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryNavy,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: BlocBuilder<BookmarkBloc, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const LoadingIndicator(message: 'Loading your saved bookmarks...');
          }

          if (state is BookmarkError) {
            return ErrorView(
              message: state.message,
              onRetry: _loadBookmarks,
            );
          }

          if (state is BookmarksLoaded) {
            final bookmarks = state.bookmarks;

            if (bookmarks.isEmpty) {
              return EmptyView(
                icon: Icons.bookmark_border_rounded,
                title: 'No Bookmarked ${_tabs[_tabController.index]}',
                subtitle: 'Tap the bookmark icon on any ${_tabs[_tabController.index].toLowerCase()} to save it here for quick access.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadBookmarks(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookmarks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final b = bookmarks[index];
                  return _buildBookmarkCard(context, b);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, BookmarkModel b) {
    return InkWell(
      onTap: () {
        if (b.refType == 'case') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseDetailScreen(caseId: b.refId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bookmark, color: AppColors.primaryNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (b.subtitle != null && b.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      b.subtitle!,
                      style: const TextStyle(fontSize: 12, color: AppColors.accentGold, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Added on ${b.createdAt.day}/${b.createdAt.month}/${b.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
              onPressed: () {
                context.read<BookmarkBloc>().add(RemoveBookmarkEvent(b.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
