import 'package:flutter/material.dart';

class PremiumMemberBadge extends StatelessWidget {
  final bool compact;

  const PremiumMemberBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F9F8F);
    final size = compact ? 20.0 : 24.0;
    return Tooltip(
      message: 'Premium member',
      child: Semantics(
        label: 'Premium member',
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.48)),
            ),
            child: Icon(Icons.workspace_premium_rounded, size: compact ? 14 : 17, color: accent),
          ),
        ),
      ),
    );
  }
}
