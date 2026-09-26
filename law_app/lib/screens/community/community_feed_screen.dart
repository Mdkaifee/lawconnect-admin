import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/post/post_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_data_repository.dart';
import '../../widgets/post_card.dart';
import 'comments_sheet.dart';

class CommunityFeedScreen extends StatefulWidget {
  final bool showBackButton;
  const CommunityFeedScreen({super.key, this.showBackButton = false});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = ['All', 'My Posts', 'Following'];
  final Set<String> _bookmarkBusyPostIds = {};
  final Set<String> _followedAuthorIds = {'Adv. Ananya Sharma', 'Law Hub Editorial'};

  @override
  void initState() {
    super.initState();
    _loadFollowedAuthors();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowedAuthors() async {
    // 1. Load local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('followed_authors');
      if (list != null && list.isNotEmpty && mounted) {
        setState(() => _followedAuthorIds.addAll(list));
      }
    } catch (_) {}

    // 2. Fetch live following list from backend
    if (!mounted) return;
    try {
      final backendList = await context.read<PostRepository>().getFollowingAuthors();
      if (backendList.isNotEmpty && mounted) {
        setState(() => _followedAuthorIds.addAll(backendList));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('followed_authors', _followedAuthorIds.toList());
      }
    } catch (_) {}
  }

  void _fetchPosts() {
    context.read<PostBloc>().add(
          LoadPostsEvent(
            mine: _selectedCategory == 'My Posts',
            following: _selectedCategory == 'Following',
          ),
        );
  }

  Future<void> _toggleFollow(PostModel post) async {
    final currentUser = context.read<AuthRepository>().currentUser;
    final currentUserId = currentUser?.id;
    final currentUserName = currentUser?.name;

    // DO NOT ALLOW TO FOLLOW MYSELF
    if ((currentUserId != null && currentUserId == post.authorId) ||
        (currentUserName != null && currentUserName.isNotEmpty && currentUserName.toLowerCase() == post.authorName.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot follow yourself'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final targetId = post.authorId.isNotEmpty ? post.authorId : post.authorName;
    final isAlreadyFollowing = _followedAuthorIds.contains(targetId) || _followedAuthorIds.contains(post.authorName);

    // Optimistic UI update
    setState(() {
      if (isAlreadyFollowing) {
        _followedAuthorIds.remove(targetId);
        _followedAuthorIds.remove(post.authorName);
      } else {
        _followedAuthorIds.add(targetId);
        _followedAuthorIds.add(post.authorName);
      }
    });

    try {
      // Call backend dynamic follow endpoint
      if (post.authorId.isNotEmpty) {
        final res = await context.read<PostRepository>().toggleFollowAuthor(post.authorId);
        if (res['following'] is List) {
          final serverList = (res['following'] as List).map((e) => e.toString()).toList();
          if (mounted) {
            setState(() => _followedAuthorIds.addAll(serverList));
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('followed_authors', _followedAuthorIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAlreadyFollowing ? 'Unfollowed ${post.authorName}' : 'You are now following ${post.authorName}',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F1E36),
          ),
        );

        // If currently on Following tab, re-fetch feed dynamically from backend
        if (_selectedCategory == 'Following') {
          _fetchPosts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _togglePostBookmark(PostModel post, bool isBookmarked) async {
    if (_bookmarkBusyPostIds.contains(post.id)) return;
    setState(() => _bookmarkBusyPostIds.add(post.id));
    try {
      final repository = context.read<UserDataRepository>();
      if (isBookmarked) {
        await repository.removeBookmark(post.id);
      } else {
        await repository.addBookmark(
          refType: 'post',
          refId: post.id,
          title: post.title,
          subtitle: post.category,
        );
      }
      if (mounted) {
        context.read<UserDataBloc>().add(LoadUserDataEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isBookmarked ? 'Post removed from bookmarks' : 'Post bookmarked')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update bookmark')));
      }
    } finally {
      if (mounted) setState(() => _bookmarkBusyPostIds.remove(post.id));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<PostBloc>().state;
    if (state is PostLoaded && state.hasMore) {
      context.read<PostBloc>().add(
            LoadPostsEvent(
              category: null,
              mine: _selectedCategory == 'My Posts',
              following: _selectedCategory == 'Following',
              page: state.page + 1,
              isNewLoad: false,
            ),
          );
    }
  }

  void _showCreatePostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'General Law';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Legal Discussion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Constitution', 'Supreme Court', 'Criminal Law', 'Civil Law', 'General Law']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title / Subject'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Write your post / legal query...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                  context.read<PostBloc>().add(
                        CreatePostEvent(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          category: category,
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post published successfully!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String postId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Post', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe why you are reporting this content:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Misleading citation, spam, etc.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                context.read<PostBloc>().add(
                      ReportPostEvent(postId: postId, reason: reasonController.text.trim()),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted for moderator review.')),
                );
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthRepository>().currentUser?.id;
    final currentUserName = context.read<AuthRepository>().currentUser?.name;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Law Posts', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
            onPressed: _fetchPosts,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppColors.primaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Category Pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                          _fetchPosts();
                        }
                      },
                      selectedColor: AppColors.primaryNavy,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primaryNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xfff3f7fa),
                      side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.borderLight),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Posts List
          Expanded(
            child: BlocBuilder<PostBloc, PostState>(
              builder: (context, state) {
                if (state is PostLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                }

                if (state is PostError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchPosts, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                if (state is PostLoaded) {
                  final allPosts = state.posts;
                  final displayPosts = _selectedCategory == 'Following'
                      ? allPosts
                          .where((p) =>
                              _followedAuthorIds.contains(p.authorId) ||
                              _followedAuthorIds.contains(p.authorName))
                          .toList()
                      : allPosts;

                  if (displayPosts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedCategory == 'Following'
                                  ? Icons.people_outline_rounded
                                  : Icons.forum_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == 'Following'
                                  ? 'You are not following any authors with recent posts yet.\nTap the 3-dot menu on any post to follow legal authors!'
                                  : 'No community posts in this category.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textMuted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _fetchPosts(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: displayPosts.length + (state.hasMore && _selectedCategory != 'Following' ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx == displayPosts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2),
                            ),
                          );
                        }
                        final post = displayPosts[idx];
                        final isSelf = (currentUserId != null && currentUserId == post.authorId) ||
                            (currentUserName != null &&
                                currentUserName.isNotEmpty &&
                                currentUserName.toLowerCase() == post.authorName.toLowerCase());
                        final isFollowing = _followedAuthorIds.contains(post.authorId) ||
                            _followedAuthorIds.contains(post.authorName);

                        return BlocBuilder<UserDataBloc, UserDataState>(
                          builder: (context, userState) {
                            final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(post.id);
                            return PostCard(
                              post: post,
                              isSelf: isSelf,
                              isFollowing: isFollowing,
                              isBookmarked: isBookmarked,
                              bookmarkBusy: _bookmarkBusyPostIds.contains(post.id),
                              onFollow: () => _toggleFollow(post),
                              onBookmark: () => _togglePostBookmark(post, isBookmarked),
                              onLike: () => context.read<PostBloc>().add(ToggleLikePostEvent(post.id)),
                              onComment: () => CommentsSheet.show(context, postId: post.id, postTitle: post.title),
                              onReport: () => _showReportDialog(context, post.id),
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
