import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post/post_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../models/comment_model.dart';
import '../../repositories/post_repository.dart';

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
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final postRepo = RepositoryProvider.of<PostRepository>(context);
      final items = await postRepo.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        context.read<PostBloc>().add(AddCommentEvent(postId: widget.postId, content: text));
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
          SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                const Text(
                  'Legal Discussion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
                : _comments.isEmpty
                    ? const Center(
                        child: Text('No comments yet. Be the first advocate to reply!'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, idx) {
                          final c = _comments[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: c.authorType == 'admin' ? AppColors.goldAccent : AppColors.primaryNavy,
                                  child: Text(
                                    c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.authorName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryNavy),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.content,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add your legal perspective...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.primaryNavy),
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
