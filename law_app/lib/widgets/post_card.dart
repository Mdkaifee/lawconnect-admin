import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_theme.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onReport;
  final VoidCallback onBookmark;
  final VoidCallback? onFollow;
  final bool isBookmarked;
  final bool bookmarkBusy;
  final bool isFollowing;
  final bool isSelf;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onReport,
    required this.onBookmark,
    this.onFollow,
    this.isBookmarked = false,
    this.bookmarkBusy = false,
    this.isFollowing = false,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAdminAuthor = post.authorType == 'admin';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isAdminAuthor ? AppColors.goldAccent : AppColors.primaryNavy,
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdminAuthor) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Verified Hub',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        post.category,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'follow') onFollow?.call();
                    if (val == 'report') onReport();
                    if (val == 'share') {
                      Share.share('${post.title}\n\n${post.content}\n\n- Shared from Rishikesh Law Hub');
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!isSelf)
                      PopupMenuItem(
                        value: 'follow',
                        child: Row(
                          children: [
                            Icon(
                              isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                              size: 18,
                              color: isFollowing ? const Color(0xFFEF4444) : AppColors.primaryNavy,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isFollowing ? 'Unfollow ${post.authorName}' : 'Follow ${post.authorName}',
                              style: TextStyle(
                                color: isFollowing ? const Color(0xFFEF4444) : AppColors.primaryNavy,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: AppColors.primaryNavy),
                          SizedBox(width: 8),
                          Text('Share Post', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Report Content', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post Title & Content
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                height: 1.5,
              ),
            ),

            // Tags / Categories pills
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: post.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // soft sky blue capsule
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$t',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8), // Royal blue tag text
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 8),

            // Action Metrics Bar (Likes, Comments, Bookmark)
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 19,
                          color: post.isLiked ? AppColors.danger : AppColors.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likesCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onComment,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primaryNavy),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: bookmarkBusy ? null : onBookmark,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: bookmarkBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy))
                        : Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20,
                            color: isBookmarked ? AppColors.goldAccent : AppColors.primaryNavy,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
