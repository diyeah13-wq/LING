import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../providers/learner_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/common/xp_badge.dart';

/// Lists all available lessons grouped by category.
class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final progress = ref.watch(progressProvider);
    final completion = ref.watch(lessonCompletionProvider);
    final theme = Theme.of(context);

    const sections = [
      ('alphabet', 'Alphabet & Fingerspelling'),
      ('numbers', 'Numbers'),
      ('essentials', 'Everyday Words & Greetings'),
      ('daily', 'Daily Needs & Essentials'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LingoSpacing.lg,
            vertical: LingoSpacing.md,
          ),
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curriculum',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                    Text(
                      'ASL Lessons',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                XpBadge(xp: progress.xp),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Master signs through video demonstrations and live camera practice.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: LingoSpacing.md),

            for (final section in sections) ...[
              if (lessons.any((lesson) => lesson.category == section.$1)) ...[
                const SizedBox(height: LingoSpacing.md),
                _SectionHeader(title: section.$2),
                const SizedBox(height: LingoSpacing.sm),
                for (final lesson in lessons
                    .where((lesson) => lesson.category == section.$1)) ...[
                  _LessonCard(
                    lesson: lesson,
                    completed: completion[lesson.id] ?? false,
                    learnedSignsCount: lesson.signs
                        .where((s) => progress.signsLearned.contains(s.id))
                        .length,
                    onTap: () => context.push('/learn/${lesson.id}'),
                  ),
                  const SizedBox(height: LingoSpacing.md),
                ],
              ],
            ],
            const SizedBox(height: LingoSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: LingoColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: LingoColors.primary,
              ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool completed;
  final int learnedSignsCount;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.completed,
    required this.learnedSignsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = lesson.signs.length;
    final progressValue = total == 0 ? 0.0 : learnedSignsCount / total;

    return Material(
      color: isDark ? LingoColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(LingoSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LingoRadius.lg),
            border: Border.all(
              color: completed
                  ? LingoColors.secondary.withValues(alpha: 0.5)
                  : isDark
                      ? LingoColors.darkDivider
                      : LingoColors.divider,
              width: completed ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: LingoColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(LingoRadius.md),
                    ),
                    child: Center(
                      child: Text(lesson.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: LingoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (completed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LingoColors.secondary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: LingoColors.secondary,
                                        size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Done',
                                      style: TextStyle(
                                        color: LingoColors.secondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed ? LingoColors.secondary : LingoColors.primary,
                  ),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$learnedSignsCount of $total signs mastered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: LingoColors.accent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${lesson.xpReward} XP',
                        style: const TextStyle(
                          color: LingoColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
