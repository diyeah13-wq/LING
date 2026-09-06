import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../data/achievements_catalog.dart';
import '../../models/achievement.dart';
import '../../providers/learner_provider.dart';

/// Shows the learner's progress: XP, level, streak, lessons, signs learned,
/// accuracy, and achievements.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: ListView(
        padding: const EdgeInsets.all(LingoSpacing.lg),
        children: [
          Text('Progress', style: theme.textTheme.headlineMedium),
          const SizedBox(height: LingoSpacing.lg),
          _LevelCard(xp: progress.xp),
          const SizedBox(height: LingoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.star,
                  color: LingoColors.accent,
                  value: '${progress.xp}',
                  label: 'XP',
                ),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFF97316),
                  value: '${progress.streak}',
                  label: 'Day streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.menu_book,
                  color: LingoColors.primary,
                  value: '${progress.lessonsCompleted}',
                  label: 'Lessons',
                ),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: _MetricCard(
                  icon: Icons.back_hand,
                  color: LingoColors.secondary,
                  value: '${progress.signsLearned.length}',
                  label: 'Signs learned',
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          _MetricCard(
            icon: Icons.track_changes,
            color: Colors.purple,
            value: '${(progress.accuracy * 100).round()}%',
            label: 'Accuracy',
          ),
          const SizedBox(height: LingoSpacing.xl),
          Row(
            children: [
              Text('Achievements', style: theme.textTheme.titleMedium),
              const SizedBox(width: LingoSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: LingoColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${progress.achievements.length}/${AchievementCatalog.all.length}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 12, color: LingoColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          _AchievementsGrid(
            unlocked: progress.achievements,
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int xp;

  const _LevelCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = XpLevels.levelForXp(xp);
    final intoLevel = XpLevels.xpIntoLevel(xp);
    final toNext = XpLevels.xpToNextLevel(xp);
    final progressValue =
        XpLevels.xpPerLevel == 0 ? 0.0 : intoLevel / XpLevels.xpPerLevel;

    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LingoColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LingoRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$level',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: LingoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level $level',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$toNext XP to level ${level + 1}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final Set<String> unlocked;

  const _AchievementsGrid({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: LingoSpacing.md,
        mainAxisSpacing: LingoSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: AchievementCatalog.all.length,
      itemBuilder: (context, index) {
        final achievement = AchievementCatalog.all[index];
        final isUnlocked = unlocked.contains(achievement.id);
        return _AchievementTile(
          achievement: achievement,
          unlocked: isUnlocked,
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LingoSpacing.sm),
      decoration: BoxDecoration(
        color: unlocked
            ? LingoColors.accent.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(LingoRadius.md),
        border: Border.all(
          color: unlocked
              ? LingoColors.accent.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.emoji,
            style: TextStyle(
              fontSize: 24,
              color: unlocked ? null : Colors.black26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: LingoSpacing.md),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}