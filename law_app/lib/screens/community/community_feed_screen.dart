import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../blocs/user_data/user_data_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../models/post_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_data_repository.dart';
import '../../widgets/post_card.dart';
import 'comments_sheet.dart';
import '../profile/public_user_profile_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  final bool showBackButton;
  const CommunityFeedScreen({super.key, this.showBackButton = false});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = ['All', 'My Posts', 'Friends'];
  final Set<String> _bookmarkBusyPostIds = {};
  final Set<String> _followedAuthorIds = {};

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
    try {
      final backendList = await context.read<PostRepository>().getFollowingAuthors();
      if (mounted) {
        setState(() {
          _followedAuthorIds
            ..clear()
            ..addAll(backendList);
        });
      }
    } catch (_) {}
  }

  void _fetchPosts() {
    context.read<PostBloc>().add(
          LoadPostsEvent(
            mine: _selectedCategory == 'My Posts',
            following: _selectedCategory == 'Friends',
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
            content: Text(Translation.t('cannot_follow_self')),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final targetId = post.authorId.isNotEmpty ? post.authorId : post.authorName;
    final isAlreadyFollowing = _followedAuthorIds.contains(targetId);

    try {
      if (post.authorId.isNotEmpty) {
        final res = await context.read<PostRepository>().toggleFollowAuthor(post.authorId);
        if (res['following'] is List) {
          final serverList = (res['following'] as List).map((e) => e.toString()).toList();
          if (mounted) {
            setState(() {
              _followedAuthorIds
                ..clear()
                ..addAll(serverList);
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAlreadyFollowing
                  ? Translation.t('removed_user_from_friends')
                  : Translation.t('follow_request_sent'),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F1E36),
          ),
        );

        // If currently on Following tab, re-fetch feed dynamically from backend
        if (_selectedCategory == 'Friends') {
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
          SnackBar(content: Text(isBookmarked ? Translation.t('removed_from_bookmarks') : Translation.t('bookmarked_successfully'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translation.t('unable_update_bookmark'))));
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
              following: _selectedCategory == 'Friends',
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
          title: Text(Translation.t('new_legal_discussion'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: Translation.t('category')),
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
                  decoration: InputDecoration(labelText: Translation.t('title_subject')),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: Translation.t('write_post_hint')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translation.t('cancel')),
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
                    SnackBar(content: Text(Translation.t('post_published')), backgroundColor: AppColors.success),
                  );
                }
              },
              child: Text(Translation.t('publish')),
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
        title: Text(Translation.t('report_post'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translation.t('report_reason_prompt')),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(hintText: Translation.t('report_hint')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translation.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                context.read<PostBloc>().add(
                      ReportPostEvent(postId: postId, reason: reasonController.text.trim()),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Translation.t('report_submitted'))),
                );
              }
            },
            child: Text(Translation.t('submit_report')),
          ),
        ],
      ),
    );
  }

  void _openAuthorProfile(PostModel post) {
    if (post.authorId.isEmpty || post.authorType == 'admin') return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(userId: post.authorId, fallbackName: post.authorName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;
    final currentUserId = currentUser?.id;
    final currentUserName = currentUser?.name;
    final currentUserPhotoUrl = currentUser?.photoUrl;
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor(context),
        foregroundColor: textPrimary,
        surfaceTintColor: AppTheme.appBarColor(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(Translation.t('law_posts'), style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryOrGold),
            onPressed: _fetchPosts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(Icons.add, color: isDark ? AppColors.primaryNavyDark : Colors.white),
      ),
      body: Column(
        children: [
          // Top Category Tabs with Equal Width
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: cardBg,
            child: Row(
              children: _categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final isSelected = _selectedCategory == cat;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: idx == 0 ? 0 : 4,
                      right: idx == _categories.length - 1 ? 0 : 4,
                    ),
                    child: InkWell(
                      onTap: () {
                        if (_selectedCategory != cat) {
                          setState(() => _selectedCategory = cat);
                          _fetchPosts();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.goldAccent : AppColors.primaryNavy)
                              : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.goldAccent : AppColors.primaryNavy)
                                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat == 'All'
                                ? Translation.t('all')
                                : cat == 'My Posts'
                                    ? Translation.t('my_posts_filter')
                                    : Translation.t('friends'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? AppColors.primaryNavyDark : Colors.white)
                                  : textPrimary,
                            ),
                          ),
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
            child: BlocBuilder<PostBloc, PostState>(
              builder: (context, state) {
                if (state is PostLoading) {
                  return Center(child: CircularProgressIndicator(color: primaryOrGold));
                }

                if (state is PostError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(state.message, style: TextStyle(color: textPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchPosts, child: Text(Translation.t('retry'))),
                      ],
                    ),
                  );
                }

                if (state is PostLoaded) {
                  final allPosts = state.posts;
                  final displayPosts = _selectedCategory == 'Friends'
                      ? allPosts
                          .where((p) =>
                              _followedAuthorIds.contains(p.authorId))
                          .toList()
                      : allPosts;

                  if (displayPosts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == 'Friends'
                                  ? Translation.t('no_friends_posts')
                                  : Translation.t('no_community_posts'),
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
                    color: primaryOrGold,
                    onRefresh: () async => _fetchPosts(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: displayPosts.length + (state.hasMore && _selectedCategory != 'Friends' ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx == displayPosts.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: primaryOrGold, strokeWidth: 2),
                            ),
                          );
                        }
                        final post = displayPosts[idx];
                        final isSelf = (currentUserId != null && currentUserId == post.authorId) ||
                            (currentUserName != null &&
                                currentUserName.isNotEmpty &&
                                currentUserName.toLowerCase() == post.authorName.toLowerCase());
                        final isFollowing = _followedAuthorIds.contains(post.authorId);

                        return BlocBuilder<UserDataBloc, UserDataState>(
                          builder: (context, userState) {
                            final isBookmarked = userState is UserDataLoaded && userState.isBookmarked(post.id);
                            return PostCard(
                              post: post,
                              isSelf: isSelf,
                              currentUserPhotoUrl: currentUserPhotoUrl,
                              isFollowing: isFollowing,
                              isBookmarked: isBookmarked,
                              bookmarkBusy: _bookmarkBusyPostIds.contains(post.id),
                              onFollow: () => _toggleFollow(post),
                              onAuthorTap: () => _openAuthorProfile(post),
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
