import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Small chip that shows a learner's XP with a star icon.
class XpBadge extends StatelessWidget {
  final int xp;
  final bool compact;

  const XpBadge({super.key, required this.xp, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? LingoSpacing.sm : LingoSpacing.md,
        vertical: compact ? LingoSpacing.xs : LingoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LingoColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: LingoColors.accent, size: 16),
          SizedBox(width: compact ? 2 : 4),
          Text(
            '$xp',
            style: TextStyle(
              color: LingoColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}