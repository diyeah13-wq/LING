import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/common/lingo_button.dart';
import '../../widgets/lesson/sign_demo.dart';
import '../practice/practice_session_screen.dart';

/// Detailed view of a single lesson with its signs.
class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonProvider(lessonId));
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg),
        children: [
          Row(
            children: [
              Text(lesson.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(lesson.subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.lg),
          _LessonProgressBar(
            lesson: lesson,
            learnedSigns: progress.signsLearned,
          ),
          const SizedBox(height: LingoSpacing.lg),
          for (final sign in lesson.signs) ...[
            _SignSection(sign: sign),
            const SizedBox(height: LingoSpacing.md),
          ],
          const SizedBox(height: LingoSpacing.sm),
          Text(
            'Lesson XP reward: ${lesson.xpReward}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: LingoSpacing.lg),
          LingoButton(
            label: 'Practice this lesson',
            icon: const Icon(Icons.videocam_outlined,
                size: 20, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeSessionScreen(lessonId: lesson.id),
                ),
              );
            },
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

  const _LessonProgressBar({
    required this.lesson,
    required this.learnedSigns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learnedInLesson =
        lesson.signs.where((s) => learnedSigns.contains(s.id)).length;
    final total = lesson.signs.length;
    final progressValue = total == 0 ? 0.0 : learnedInLesson / total;

    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(LingoRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lesson progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: LingoSpacing.sm),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: LingoSpacing.sm),
          Text(
            '$learnedInLesson of $total signs learned',
            style: theme.textTheme.bodyMedium,
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
    final learned = ref.watch(progressProvider).signsLearned.contains(sign.id);

    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: () => _showSignDetail(context, sign),
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(LingoSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LingoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(sign.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sign.text,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (sign.type == SignType.motion)
                      Text(
                        'Motion sign',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (learned)
                const Icon(Icons.check_circle,
                    color: LingoColors.secondary, size: 20)
              else
                const Icon(Icons.play_circle_outline,
                    color: LingoColors.primary, size: 26),
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
          appBar: AppBar(title: Text(sign.text)),
          body: SignDetailPage(sign: sign),
        ),
      ),
    );
  }
}