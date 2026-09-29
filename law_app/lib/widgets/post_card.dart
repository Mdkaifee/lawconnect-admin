import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_theme.dart';
import '../core/translations/translation.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onReport;
  final VoidCallback onBookmark;
  final VoidCallback? onFollow;
  final VoidCallback? onAuthorTap;
  final bool isBookmarked;
  final bool bookmarkBusy;
  final bool isFollowing;
  final bool isSelf;
  final String? currentUserPhotoUrl;
  final bool likeBusy;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onReport,
    required this.onBookmark,
    this.onFollow,
    this.onAuthorTap,
    this.isBookmarked = false,
    this.bookmarkBusy = false,
    this.isFollowing = false,
    this.isSelf = false,
    this.currentUserPhotoUrl,
    this.likeBusy = false,
    this.onDelete,
  });

  String _formatDateTime(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primaryOrGold = AppTheme.primaryOrGold(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final cardBg = AppTheme.cardColor(context);
    final isAdminAuthor = post.authorType == 'admin';
    final formattedTime = _formatDateTime(post.createdAt);
    final effectivePhotoUrl = (post.authorPhotoUrl != null && post.authorPhotoUrl!.isNotEmpty)
        ? post.authorPhotoUrl
        : (isSelf ? currentUserPhotoUrl : null);

    return Card(
      elevation: 0,
      color: cardBg,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.borderColor(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Row(
              children: [
                GestureDetector(
                  onTap: isAdminAuthor ? null : onAuthorTap,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isAdminAuthor
                        ? AppColors.goldAccent
                        : (isDark ? AppColors.surfaceDarkElevated : AppColors.primaryNavy),
                    backgroundImage: (effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty)
                        ? NetworkImage(effectivePhotoUrl)
                        : null,
                    child: (effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty)
                        ? null
                        : (isSelf
                            ? Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: isDark ? AppColors.goldAccentLight : Colors.white,
                              )
                            : Text(
                                post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A',
                                style: TextStyle(
                                  color: isDark && !isAdminAuthor ? AppColors.goldAccentLight : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )),
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.goldAccentLight : AppColors.primaryNavy).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.goldAccentLight : AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                          if (isAdminAuthor) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(alpha: isDark ? 0.3 : 0.2),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const SizedBox.shrink(),
                          if (formattedTime.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(fontSize: 11, color: Colors.transparent),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formattedTime,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  color: cardBg,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'follow') onFollow?.call();
                    if (val == 'report') onReport();
                    if (val == 'share') {
                      Share.share('${post.title}\n\n${post.content}\n\n- Shared from Rishikesh Law Hub');
                    }
                    if (val == 'delete') onDelete?.call();
                  },
                  itemBuilder: (ctx) => [
                    if (isSelf && onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), const SizedBox(width: 8), Text('Delete post', style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600))]),
                      ),
                    if (!isSelf)
                      PopupMenuItem(
                        value: 'follow',
                        child: Row(
                          children: [
                            Icon(
                              isFollowing ? Icons.people_alt_outlined : Icons.person_add_outlined,
                              size: 18,
                              color: isFollowing ? AppColors.success : primaryOrGold,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isFollowing ? 'Friend: ${post.authorName}' : 'Send request to ${post.authorName}',
                              style: TextStyle(
                                color: isFollowing ? AppColors.success : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: primaryOrGold),
                          const SizedBox(width: 8),
                          Text(Translation.t('share_post'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Text(Translation.t('report_content'), style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post content
            if (post.content.isNotEmpty) Text(
              post.content,
              style: TextStyle(
                fontSize: 13.5,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            if (post.imageData != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(post.imageData!), fit: BoxFit.cover, width: double.infinity),
              ),
            ],

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
                      color: isDark
                          ? AppColors.goldAccent.withValues(alpha: 0.15)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.goldAccentLight : const Color(0xFF1D4ED8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),
            Divider(height: 1, color: AppTheme.dividerColor(context)),
            const SizedBox(height: 8),

            // Action Metrics Bar (Likes, Comments, Bookmark)
            Row(
              children: [
                InkWell(
                  onTap: likeBusy ? null : onLike,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        likeBusy
                            ? SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrGold))
                            : Icon(
                                post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 19,
                                color: post.isLiked ? AppColors.danger : primaryOrGold,
                              ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
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
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: primaryOrGold),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentsCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
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
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrGold))
                        : Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20,
                            color: isBookmarked ? AppColors.goldAccent : primaryOrGold,
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
