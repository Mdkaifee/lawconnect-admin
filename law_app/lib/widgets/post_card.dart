import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_theme.dart';
import '../core/translations/translation.dart';
import '../models/post_model.dart';
import 'premium_member_badge.dart';

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
      key: ValueKey(post.id),
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
                          if (post.isAuthorPremium) ...[
                            const SizedBox(width: 5),
                            const PremiumMemberBadge(compact: true),
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
                      final shareParts = [
                        if (post.title.trim().isNotEmpty) post.title.trim(),
                        if (post.content.trim().isNotEmpty) post.content.trim(),
                        if (post.content.trim().isEmpty && post.imageData != null) 'Shared a photo',
                        '- Shared from Rishikesh Law Hub',
                      ];
                      Share.share(shareParts.join('\n\n'));
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

            // Post content (Text only / Photo + text)
            if (post.content.trim().isNotEmpty)
              Text(
                post.content.trim(),
                style: TextStyle(
                  fontSize: 13.5,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),

            // Post Image (Photo only / Photo + text)
            if (post.imageData != null && post.imageData!.isNotEmpty) ...[
              if (post.content.trim().isNotEmpty) const SizedBox(height: 12),
              _PostImage(imageData: post.imageData!),
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

class _PostImage extends StatefulWidget {
  final String imageData;

  const _PostImage({required this.imageData});

  @override
  State<_PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<_PostImage> {
  static final Map<int, Uint8List> _decodedCache = {};
  Uint8List? _bytes;
  bool _isNetwork = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void didUpdateWidget(covariant _PostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) {
      _processImage();
    }
  }

  void _processImage() {
    final raw = widget.imageData.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      _isNetwork = true;
      _bytes = null;
      _hasError = false;
      return;
    }

    _isNetwork = false;
    final hash = raw.hashCode;
    if (_decodedCache.containsKey(hash)) {
      _bytes = _decodedCache[hash];
      _hasError = false;
      return;
    }

    try {
      String cleanBase64 = raw;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      final decoded = base64Decode(cleanBase64);
      if (_decodedCache.length > 50) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[hash] = decoded;
      _bytes = decoded;
      _hasError = false;
    } catch (_) {
      _hasError = true;
      _bytes = null;
    }
  }

  void _openFullScreenViewer(BuildContext context) {
    if (_hasError || (_bytes == null && !_isNetwork)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: _isNetwork
                  ? Image.network(widget.imageData.trim(), fit: BoxFit.contain)
                  : Image.memory(_bytes!, fit: BoxFit.contain, gaplessPlayback: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageLoadingPlaceholder(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      color: AppTheme.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: AppTheme.primaryOrGold(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreenViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 450, minHeight: 100),
          child: _isNetwork
              ? Image.network(
                  widget.imageData.trim(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : _imageLoadingPlaceholder(context),
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppTheme.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36)),
                  ),
                )
              : (_bytes != null
                  ? Image.memory(
                      _bytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      gaplessPlayback: true,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                          wasSynchronouslyLoaded || frame != null
                              ? child
                              : _imageLoadingPlaceholder(context),
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppTheme.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36)),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

