import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../logic/blocs/bookmark/bookmark_bloc.dart';
import '../../../logic/blocs/bookmark/bookmark_event.dart';
import '../../../logic/blocs/post/post_bloc.dart';
import '../../../logic/blocs/post/post_event.dart';
import '../../../logic/blocs/post/post_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import 'create_post_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'My Posts', 'Following'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadPosts();
  }

  void _loadPosts() {
    final scope = _tabController.index == 1 ? 'mine' : 'all';
    context.read<PostBloc>().add(FetchPostsEvent(scope: scope));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Law Posts'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: AppColors.primaryNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          if (state is PostLoading) {
            return const LoadingIndicator(message: 'Loading discussions and posts...');
          }

          if (state is PostError) {
            return ErrorView(
              message: state.message,
              onRetry: _loadPosts,
            );
          }

          if (state is PostsLoaded) {
            final posts = state.posts;

            if (posts.isEmpty) {
              return EmptyView(
                icon: Icons.article_outlined,
                title: _tabController.index == 1 ? 'No Posts by You Yet' : 'No Law Posts Available',
                subtitle: 'Tap the + button below to share your case analysis or question.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadPosts(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, post);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryNavy.withAlpha(25),
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'R',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_formatDate(post.createdAt)} • ${post.category}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withAlpha(12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Content
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$t',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.catCriminal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),

          // Actions (Like, Comment, Bookmark)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<PostBloc>().add(LikePostEvent(post.id));
                    },
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: post.isLiked ? Colors.red : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_outline, size: 20, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  context.read<BookmarkBloc>().add(
                        ToggleBookmarkEvent(
                          refType: 'post',
                          refId: post.id,
                          title: post.title,
                          subtitle: post.authorName,
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post bookmarked!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays} days ago';
  }
}
