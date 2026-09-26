import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../core/theme/app_theme.dart';
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
  final List<String> _categories = ['All', 'Constitution', 'Supreme Court', 'Criminal Law', 'Civil Law', 'General Law'];

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
          LoadPostsEvent(category: _selectedCategory == 'All' ? null : _selectedCategory),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    final state = context.read<PostBloc>().state;
    if (state is PostLoaded && state.hasMore) {
      context.read<PostBloc>().add(
            LoadPostsEvent(
              category: _selectedCategory == 'All' ? null : _selectedCategory,
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
                  decoration: const InputDecoration(
                    labelText: 'Discussion Content',
                    hintText: 'Share your analysis, case insights or questions...',
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Advocate Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.edit, color: AppColors.goldAccent),
        label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                  if (state.posts.isEmpty) {
                    return const Center(child: Text('No community posts in this category.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _fetchPosts(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                      if (idx == state.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2)),
                        );
                      }
                        final post = state.posts[idx];
                        return PostCard(
                        post: post,
                        onLike: () {
                          context.read<PostBloc>().add(ToggleLikePostEvent(post.id));
                        },
                        onComment: () {
                          CommentsSheet.show(context, postId: post.id, postTitle: post.title);
                        },
                        onReport: () => _showReportDialog(context, post.id),
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
