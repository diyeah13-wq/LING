import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/grading/sign_grading_service.dart';
import '../common/sign_video_player.dart';

/// Modal bottom sheet that presents a graded sign test evaluation with detailed breakdown.
class GradingResultSheet extends StatelessWidget {
  final SignEvaluationResult result;
  final VoidCallback onTryAgain;
  final VoidCallback onContinue;

  const GradingResultSheet({
    super.key,
    required this.result,
    required this.onTryAgain,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required SignEvaluationResult result,
    required VoidCallback onTryAgain,
    required VoidCallback onContinue,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => GradingResultSheet(
        result: result,
        onTryAgain: onTryAgain,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grade = result.grade;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? LingoColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grade Badge
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: grade.color.withValues(alpha: 0.15),
              border: Border.all(color: grade.color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: grade.color.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                grade.letter,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: grade.color,
                ),
              ),
            ),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 12),
          Text(
            grade.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: grade.color,
            ),
          ),
          const SizedBox(height: 4),

          // Target vs detected
          Text(
            'Target: "${result.targetSign.text}" ${result.targetSign.emoji}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Accuracy meter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Match Confidence',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${result.accuracyPercentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: grade.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: result.confidence,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(grade.color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Feedback message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: grade.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: grade.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  grade.isPassing
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: grade.color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.feedback,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (result.xpEarned > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded,
                    color: LingoColors.accent, size: 20),
                const SizedBox(width: 6),
                Text(
                  '+${result.xpEarned} XP Earned!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: LingoColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              if (result.targetSign.hasVideoReference)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showSignVideoModal(context, result.targetSign);
                    },
                    icon: const Icon(Icons.ondemand_video, size: 18),
                    label: const Text('Watch Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (result.targetSign.hasVideoReference)
                const SizedBox(width: 10),
              if (!grade.isPassing)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTryAgain();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LingoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContinue();
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LingoColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
