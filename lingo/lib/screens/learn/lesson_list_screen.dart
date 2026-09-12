import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/learner_provider.dart';
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
      ('alphabet', 'Alphabet'),
      ('numbers', 'Numbers'),
      ('essentials', 'Everyday words'),
      ('daily', 'Daily needs'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: XpBadge(xp: progress.xp),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg),
          children: [
            Text('Lessons', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Practice each sign and work the camera later.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: LingoSpacing.lg),
            for (final section in sections) ...[
              if (lessons.any((lesson) => lesson.category == section.$1)) ...[
              const SizedBox(height: LingoSpacing.md),
              _SectionLabel(section.$2),
              const SizedBox(height: LingoSpacing.sm),
              for (final lesson
                  in lessons.where((lesson) => lesson.category == section.$1)) ...[
                _LessonTile(
                  lesson: lesson,
                  completed: completion[lesson.id] ?? false,
                  progress: progress,
                  onTap: () => context.go('/learn/${lesson.id}'),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LingoSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: LingoColors.primary,
            ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool completed;
  final dynamic progress;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.completed,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(LingoSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LingoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(LingoRadius.md),
                ),
                child: Center(child: Text(lesson.emoji,
                    style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(lesson.subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle,
                    color: LingoColors.secondary, size: 24)
              else
                Text('${lesson.signs.length} signs',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
