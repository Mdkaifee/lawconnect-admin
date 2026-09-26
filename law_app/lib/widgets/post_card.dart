import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_formatter.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onBookmark;
  final VoidCallback? onTap;
  final bool isBookmarked;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onBookmark,
    this.onTap,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormatter.timeAgo(post.createdAt);
    final subtitleText = '$timeStr • ${post.category}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap ?? onComment,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + User info + Chevron Right
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F1E36),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'R',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName.isNotEmpty ? post.authorName : 'Rishikesh Yadav',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1E36),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Post Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1E36),
                  height: 1.3,
                ),
              ),

              // Tags (shown above excerpt if tags exist)
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.tags.map((tag) {
                    final cleanTag = tag.startsWith('#') ? tag : '#$tag';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cleanTag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Post Content / Excerpt
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Actions Row (Likes, Comments, Bookmark)
              Row(
                children: [
                  // Like
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 17,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Comment
                  InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${post.commentsCount}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bookmark
                  InkWell(
                    onTap: onBookmark,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 20,
                        color: const Color(0xFF0F1E36),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
