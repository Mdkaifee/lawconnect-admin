import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import 'comments_sheet.dart';

class CommunityFeedScreen extends StatefulWidget {
  final bool showBackButton;
  const CommunityFeedScreen({super.key, this.showBackButton = true});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String _selectedTab = 'All'; // 'All' | 'My Posts' | 'Following'
  final ScrollController _scrollController = ScrollController();
  final List<String> _tabs = ['All', 'My Posts', 'Following'];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchPosts() {
    context.read<PostBloc>().add(
          const LoadPostsEvent(),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<PostBloc>().state;
    if (state is PostLoaded && state.hasMore) {
      context.read<PostBloc>().add(
            LoadPostsEvent(
              page: state.page + 1,
              isNewLoad: false,
            ),
          );
    }
  }

  void _showCreatePostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    String category = 'Supreme Court';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Law Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category / Court',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Supreme Court', 'High Court', 'Constitution', 'Criminal Law', 'Contract', 'General Law']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Post Title',
                      hintText: 'e.g., SC grants interim relief on bail plea in PMLA case',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      hintText: 'SupremeCourt, PMLA, Bail',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Post Body',
                      hintText: 'Share your analysis, case insights or questions...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                        final rawTags = tagsController.text.trim();
                        final parsedTags = rawTags.isNotEmpty
                            ? rawTags.split(',').map((t) => t.trim().replaceAll('#', '')).where((t) => t.isNotEmpty).toList()
                            : <String>[];

                        context.read<PostBloc>().add(
                              CreatePostEvent(
                                title: titleController.text.trim(),
                                content: contentController.text.trim(),
                                category: category,
                                tags: parsedTags,
                              ),
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post published successfully!'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1E36),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Publish Post', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1E36), size: 22),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: const Text(
          'Law Posts',
          style: TextStyle(
            color: Color(0xFF0F1E36),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: const Color(0xFF0F1E36),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      body: Column(
        children: [
          // Filter Tabs (All, My Posts, Following)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: _tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedTab = tab);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F1E36) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Posts List
          Expanded(
            child: BlocBuilder<UserDataBloc, UserDataState>(
              builder: (context, userState) {
                final bookmarkedIds = userState is UserDataLoaded
                    ? userState.bookmarks.where((b) => b.refType == 'post').map((b) => b.refId).toSet()
                    : <String>{};

                return BlocBuilder<PostBloc, PostState>(
                  builder: (context, state) {
                    if (state is PostLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1E36)));
                    }

                    if (state is PostError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 44, color: Color(0xFFEF4444)),
                            const SizedBox(height: 12),
                            Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _fetchPosts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F1E36),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is PostLoaded) {
                      var displayedPosts = state.posts;
                      if (_selectedTab == 'My Posts') {
                        displayedPosts = displayedPosts.where((p) => p.authorId == currentUserId).toList();
                      }

                      if (displayedPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.article_outlined, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                _selectedTab == 'My Posts'
                                    ? 'You have not created any posts yet.'
                                    : 'No posts found in this feed.',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _fetchPosts(),
                        color: const Color(0xFF0F1E36),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 84),
                          itemCount: displayedPosts.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, idx) {
                            if (idx == displayedPosts.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0F1E36),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final post = displayedPosts[idx];
                            final isSaved = bookmarkedIds.contains(post.id);

                            return PostCard(
                              post: post,
                              isBookmarked: isSaved,
                              onLike: () {
                                context.read<PostBloc>().add(ToggleLikePostEvent(post.id));
                              },
                              onComment: () {
                                CommentsSheet.show(context, postId: post.id, postTitle: post.title);
                              },
                              onBookmark: () {
                                context.read<UserDataBloc>().add(
                                      ToggleBookmarkEvent(
                                        refType: 'post',
                                        refId: post.id,
                                        title: post.title,
                                        subtitle: post.authorName,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
