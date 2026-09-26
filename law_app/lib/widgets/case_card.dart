import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/case_model.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseItem;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final bool isBookmarkLoading;
  final bool compact;

  const CaseCard({
    super.key,
    required this.caseItem,
    required this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
    this.isBookmarkLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactCard(context);
    final isSupremeCourt = caseItem.courtType == 'Supreme Court' || caseItem.court.toLowerCase().contains('supreme');
    final formattedDate = _formatDate(caseItem.dateOfJudgment);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tags row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSupremeCourt ? AppColors.primaryNavy.withValues(alpha: 0.08) : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 13,
                          color: isSupremeCourt ? AppColors.primaryNavy : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          caseItem.courtType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSupremeCourt ? AppColors.primaryNavy : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (caseItem.isFeatured) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Landmark',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onBookmark != null || isBookmarkLoading)
                    isBookmarkLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldAccent),
                          )
                        : IconButton(
                            tooltip: isBookmarked ? 'Bookmarked' : 'Bookmark',
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? AppColors.goldAccent : AppColors.textMuted,
                              size: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onBookmark,
                          ),
                ],
              ),
              const SizedBox(height: 10),

              // Case Title
              Text(
                caseItem.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Citation / Year
              if (caseItem.citation != null && caseItem.citation!.isNotEmpty)
                Text(
                  caseItem.citation!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                  ),
                ),

              // Snippet / Summary
              if (caseItem.summary != null && caseItem.summary!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  caseItem.summary!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (formattedDate != null) ...[
                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (caseItem.hasCourtCopy) ...[
                          const Icon(Icons.picture_as_pdf_outlined, size: 13, color: AppColors.success),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Court Copy Available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Read Full Judgment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryNavy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final tags = caseItem.tags.isNotEmpty
        ? caseItem.tags.take(2).toList()
        : <String>['Constitutional Law', caseItem.isFeatured ? 'Basic Structure' : 'Amendment'];
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseItem.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.18, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                  const SizedBox(height: 4),
                  Text(caseItem.citation ?? 'Citation unavailable', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(caseItem.court, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEAF4FB), borderRadius: BorderRadius.circular(6)),
                      child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 32, left: 8), child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  String? _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }
}
