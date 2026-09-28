import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/translation.dart';
import '../../models/comment_model.dart';
import '../../repositories/post_repository.dart';
import '../profile/public_user_profile_screen.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String postTitle;

  const CommentsSheet({super.key, required this.postId, required this.postTitle});

  static void show(BuildContext context, {required String postId, required String postTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(postId: postId, postTitle: postTitle),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  int _page = 1;
  int _total = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({int page = 1, bool append = false}) async {
    if (append && _isLoadingMore) return;
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
    });
    try {
      final postRepo = RepositoryProvider.of<PostRepository>(context);
      final result = await postRepo.getComments(widget.postId, page: page, limit: _limit);
      if (mounted) {
        setState(() {
          _comments = append ? [..._comments, ...result.items] : result.items;
          _page = result.page;
          _total = result.total;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 120) return;
    if (_comments.length < _total) {
      _loadComments(page: _page + 1, append: true);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final postRepo = RepositoryProvider.of<PostRepository>(context);
      final comment = await postRepo.addComment(widget.postId, text);
      if (mounted) {
        // The comment was already persisted above. Only update the feed count;
        // dispatching AddCommentEvent here would POST the same comment again.
        context.read<PostBloc>().add(CommentAddedLocallyEvent(widget.postId));
        setState(() {
          _comments.add(comment);
          _commentController.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Translation.t('failed_post_comment')}: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardColor(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 20, color: primaryOrGold),
                const SizedBox(width: 8),
                Text(
                  Translation.t('legal_discussion'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.dividerColor(context)),

          // Comments List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryOrGold))
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          Translation.t('no_comments_yet'),
                          style: TextStyle(color: AppTheme.textSecondaryColor(context)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length + (_comments.length < _total ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (idx == _comments.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator(color: primaryOrGold, strokeWidth: 2)),
                            );
                          }
                          final c = _comments[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: c.authorType == 'admin' || c.authorId.isEmpty
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PublicUserProfileScreen(userId: c.authorId, fallbackName: c.authorName),
                                            ),
                                          ),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: c.authorType == 'admin'
                                        ? AppColors.goldAccent
                                        : (isDark ? AppColors.surfaceDarkElevated : AppColors.primaryNavy),
                                    backgroundImage: c.authorPhotoUrl?.trim().isNotEmpty == true ? NetworkImage(c.authorPhotoUrl!.trim()) : null,
                                    child: c.authorPhotoUrl?.trim().isNotEmpty == true
                                        ? null
                                        : Text(
                                            c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'A',
                                            style: TextStyle(
                                              color: isDark && c.authorType != 'admin' ? AppColors.goldAccentLight : Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.borderColor(context)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.authorName,
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primaryOrGold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.content,
                                          style: TextStyle(fontSize: 13, color: textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: Translation.t('add_legal_perspective'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fillColor: AppTheme.backgroundColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: primaryOrGold, strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded, color: primaryOrGold),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
