import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/lesson/sign_demo.dart';
import '../practice/practice_session_screen.dart';

/// Detailed view of a single lesson with its signs and video reference indicators.
class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonProvider(lessonId));
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    final total = lesson.signs.length;
    final learnedInLesson =
        lesson.signs.where((s) => progress.signsLearned.contains(s.id)).length;
    final isFullyMastered = total > 0 && learnedInLesson == total;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg),
        children: [
          // Hero Lesson Banner
          Container(
            padding: const EdgeInsets.all(LingoSpacing.md + 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEEF2FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(LingoRadius.lg),
              border: Border.all(
                color: isDark ? LingoColors.darkDivider : LingoColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: LingoColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(lesson.emoji,
                        style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: LingoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(lesson.subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LingoSpacing.md),

          // Progress Bar Card
          _LessonProgressBar(
            lesson: lesson,
            learnedSigns: progress.signsLearned,
            isFullyMastered: isFullyMastered,
          ),
          const SizedBox(height: LingoSpacing.lg),

          // Signs list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Signs in this lesson ($total)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: LingoColors.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${lesson.xpReward} XP',
                    style: const TextStyle(
                      color: LingoColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),

          for (final sign in lesson.signs) ...[
            _SignSection(sign: sign),
            const SizedBox(height: LingoSpacing.sm + 2),
          ],

          const SizedBox(height: LingoSpacing.lg),

          // Primary Practice Action Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LingoRadius.md),
              gradient: const LinearGradient(
                colors: [LingoColors.primary, Color(0xFF6366F1)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: LingoColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.videocam_rounded,
                  size: 22, color: Colors.white),
              label: const Text(
                'Practice Lesson with Camera',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PracticeSessionScreen(lessonId: lesson.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LingoRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: LingoSpacing.xxl),
        ],
      ),
    );
  }
}

class _LessonProgressBar extends StatelessWidget {
  final Lesson lesson;
  final Set<String> learnedSigns;
  final bool isFullyMastered;

  const _LessonProgressBar({
    required this.lesson,
    required this.learnedSigns,
    required this.isFullyMastered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final learnedInLesson =
        lesson.signs.where((s) => learnedSigns.contains(s.id)).length;
    final total = lesson.signs.length;
    final progressValue = total == 0 ? 0.0 : learnedInLesson / total;

    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? LingoColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(
          color: isFullyMastered
              ? LingoColors.secondary.withValues(alpha: 0.4)
              : isDark
                  ? LingoColors.darkDivider
                  : LingoColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lesson Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$learnedInLesson of $total learned',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFullyMastered
                      ? LingoColors.secondary
                      : LingoColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyMastered ? LingoColors.secondary : LingoColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignSection extends ConsumerWidget {
  final Sign sign;

  const _SignSection({required this.sign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final learned = ref.watch(progressProvider).signsLearned.contains(sign.id);

    return Material(
      color: isDark ? LingoColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: () => _showSignDetail(context, sign),
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LingoRadius.lg),
            border: Border.all(
              color: learned
                  ? LingoColors.secondary.withValues(alpha: 0.3)
                  : isDark
                      ? LingoColors.darkDivider
                      : LingoColors.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LingoColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(sign.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sign.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (sign.hasVideoReference) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: LingoColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_fill,
                                    color: LingoColors.primary, size: 10),
                                SizedBox(width: 3),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    color: LingoColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sign.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (learned)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: LingoColors.secondary,
                    size: 16,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignDetail(BuildContext context, Sign sign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              sign.text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SignDetailPage(sign: sign),
        ),
      ),
    );
  }
}