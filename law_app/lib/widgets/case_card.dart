import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/case_model.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseItem;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const CaseCard({
    super.key,
    required this.caseItem,
    required this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
      }
    } catch (_) {}
    return raw.split('T').first;
  }

  @override
  Widget build(BuildContext context) {
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
                  if (onBookmark != null)
                    IconButton(
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
                  if (formattedDate.isNotEmpty) ...[
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (caseItem.hasCourtCopy) ...[
                    const Icon(Icons.picture_as_pdf_outlined, size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    const Text(
                      'Court Copy Available',
                      style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'Read Full Judgment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
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
}
