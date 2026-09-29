import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
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
  final PageStorageBucket _feedPageStorageBucket = PageStorageBucket();
  final List<String> _categories = ['All', 'My Posts', 'Friends'];
  final Set<String> _followedAuthorIds = {};
  bool _loadingMorePosts = false;
  int _activeMutations = 0;
  int _lastRenderedPage = 0;

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

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post and its comments will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final completer = Completer<void>();
    setState(() => _activeMutations++);
    try {
      context.read<PostBloc>().add(DeletePostEvent(post.id, completer: completer));
      await completer.future;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _activeMutations = (_activeMutations - 1).clamp(0, 999).toInt());
    }
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
          SnackBar(
            content: Text(Translation.t('cannot_follow_self')),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
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
    if (_activeMutations > 0) return;
    setState(() => _activeMutations++);
    try {
      final repository = context.read<UserDataRepository>();
      if (isBookmarked) {
        await repository.removeBookmark(post.id);
      } else {
        final firstLine = post.content.trim().split('\n').first;
        await repository.addBookmark(
          refType: 'post',
          refId: post.id,
          title: firstLine.isNotEmpty ? firstLine.substring(0, firstLine.length > 80 ? 80 : firstLine.length) : 'Photo post',
          subtitle: 'Community post',
        );
      }
      if (mounted) {
        context.read<UserDataBloc>().add(RefreshUserDataSilentlyEvent());
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isBookmarked ? Translation.t('removed_from_bookmarks') : Translation.t('bookmarked_successfully'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translation.t('unable_update_bookmark'))));
      }
    } finally {
      if (mounted) setState(() => _activeMutations = (_activeMutations - 1).clamp(0, 999).toInt());
    }
  }

  void _onScroll() {
    if (_loadingMorePosts) return;
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<PostBloc>().state;
    if (state is PostLoaded && state.hasMore) {
      _loadingMorePosts = true;
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
    final contentController = TextEditingController();
    String? imageData;
    String? imageMimeType;
    bool isPublishing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(ctx).size.width * 0.05, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(22, 20, 18, 8),
          contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: AppTheme.primaryOrGold(ctx).withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(Icons.edit_note_rounded, color: AppTheme.primaryOrGold(ctx)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(Translation.t('new_legal_discussion'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimaryColor(ctx)))),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width * 0.80,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.58),
              child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
                          if (image == null || !ctx.mounted) return;
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            imageData = base64Encode(bytes);
                            imageMimeType = image.mimeType ?? 'image/jpeg';
                          });
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 82, maxWidth: 1600);
                          if (image == null || !ctx.mounted) return;
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            imageData = base64Encode(bytes);
                            imageMimeType = image.mimeType ?? 'image/jpeg';
                          });
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
                if (imageData != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Image.memory(
                            base64Decode(imageData!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_outlined, color: AppTheme.textSecondaryColor(ctx), size: 36)),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            tooltip: 'Remove photo',
                            style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                            onPressed: () => setDialogState(() {
                              imageData = null;
                              imageMimeType = null;
                            }),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: Translation.t('write_post_hint')),
                ),
              ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translation.t('cancel')),
            ),
            ElevatedButton(
              onPressed: isPublishing
                  ? null
                  : () async {
                      if (!(contentController.text.trim().isNotEmpty || imageData != null)) return;
                      final completer = Completer<PostModel>();
                      setDialogState(() => isPublishing = true);
                      context.read<PostBloc>().add(
                        CreatePostEvent(
                          title: '',
                          content: contentController.text.trim(),
                          category: '',
                          imageData: imageData,
                          imageMimeType: imageMimeType,
                          completer: completer,
                        ),
                      );
                      try {
                        await completer.future;
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translation.t('post_published')), backgroundColor: AppColors.success));
                      } catch (error) {
                        if (!ctx.mounted) return;
                        setDialogState(() => isPublishing = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger));
                      }
                    },
              child: isPublishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(Translation.t('publish')),
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
            onPressed: _activeMutations > 0 ? null : _fetchPosts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _activeMutations > 0 ? null : () => _showCreatePostDialog(context),
        backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(Icons.add, color: isDark ? AppColors.primaryNavyDark : Colors.white),
      ),
      body: Stack(
        children: [
          Column(
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
                        if (_activeMutations > 0) return;
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
                              ? (isDark ? const Color(0xFF9A4F16) : AppColors.danger)
                              : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? const Color(0xFF9A4F16) : AppColors.danger)
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
              buildWhen: (previous, current) {
                if (previous is PostLoaded && current is PostLoaded) {
                  return previous.posts.length != current.posts.length ||
                      previous.selectedCategory != current.selectedCategory ||
                      previous.page != current.page;
                }
                return true;
              },
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
                  if (state.page > _lastRenderedPage) {
                    _lastRenderedPage = state.page;
                    _loadingMorePosts = false;
                  }
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

                  return PageStorage(
                    bucket: _feedPageStorageBucket,
                    child: RefreshIndicator(
                      color: primaryOrGold,
                      onRefresh: () async => _fetchPosts(),
                      child: ListView.builder(
                      key: PageStorageKey<String>('community-posts-$_selectedCategory'),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: displayPosts.length + (state.hasMore && _selectedCategory != 'Friends' ? 1 : 0),
                      findChildIndexCallback: (Key key) {
                        if (key is ValueKey<String>) {
                          final id = key.value.replaceFirst('post-row-', '');
                          final idx = displayPosts.indexWhere((p) => p.id == id);
                          return idx != -1 ? idx : null;
                        }
                        return null;
                      },
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

                        return BlocSelector<PostBloc, PostState, PostModel>(
                          selector: (postState) {
                            if (postState is PostLoaded) {
                              for (final p in postState.posts) {
                                if (p.id == post.id) return p;
                              }
                            }
                            return post;
                          },
                          builder: (context, currentPost) {
                            return BlocSelector<UserDataBloc, UserDataState, bool>(
                              selector: (userState) => userState is UserDataLoaded && userState.isBookmarked(currentPost.id),
                              builder: (context, isBookmarked) {
                                return KeyedSubtree(
                                  key: ValueKey<String>('post-row-${currentPost.id}'),
                                  child: PostCard(
                                    post: currentPost,
                                    isSelf: isSelf,
                                    currentUserPhotoUrl: currentUserPhotoUrl,
                                    isFollowing: isFollowing,
                                    isBookmarked: isBookmarked,
                                    onFollow: () => _toggleFollow(currentPost),
                                    onAuthorTap: () => _openAuthorProfile(currentPost),
                                    onBookmark: () => _togglePostBookmark(currentPost, isBookmarked),
                                    onLike: () => _togglePostLike(currentPost.id),
                                    onComment: () => CommentsSheet.show(context, postId: currentPost.id, postTitle: currentPost.title),
                                    onReport: () => _showReportDialog(context, currentPost.id),
                                    onDelete: isSelf ? () => _deletePost(currentPost) : null,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
            ],
          ),
          if (_activeMutations > 0)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.24),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryOrGold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _togglePostLike(String postId) async {
    if (_activeMutations > 0) return;
    final completer = Completer<Map<String, dynamic>>();
    setState(() => _activeMutations++);
    try {
      context.read<PostBloc>().add(ToggleLikePostEvent(postId, completer: completer));
      await completer.future;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _activeMutations = (_activeMutations - 1).clamp(0, 999).toInt());
    }
  }
}
