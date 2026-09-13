import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../data/achievements_catalog.dart';
import '../../models/achievement.dart';
import '../../providers/learner_provider.dart';
import '../../widgets/common/xp_badge.dart';

/// Shows the learner's progress: XP, level, streak, lessons, signs learned,
/// accuracy, and interactive achievements.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LingoSpacing.lg,
            vertical: LingoSpacing.md,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                    Text('Your Progress',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22),
                      color: theme.textTheme.bodyMedium?.color,
                      tooltip: 'Settings',
                      onPressed: () => context.push('/settings'),
                    ),
                    XpBadge(xp: progress.xp),
                  ],
                ),
              ],
            ),
            const SizedBox(height: LingoSpacing.lg),
            _LevelCard(xp: progress.xp),
            const SizedBox(height: LingoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.stars_rounded,
                    color: LingoColors.accent,
                    value: '${progress.xp}',
                    label: 'Total XP',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: LingoSpacing.md),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFF97316),
                    value: '${progress.streak}',
                    label: 'Day Streak',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LingoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.school_rounded,
                    color: LingoColors.primary,
                    value: '${progress.lessonsCompleted}',
                    label: 'Lessons Done',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: LingoSpacing.md),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.back_hand_rounded,
                    color: LingoColors.secondary,
                    value: '${progress.signsLearned.length}',
                    label: 'Signs Mastered',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LingoSpacing.md),
            _MetricCard(
              icon: Icons.track_changes_rounded,
              color: const Color(0xFF8B5CF6),
              value: '${(progress.accuracy * 100).round()}%',
              label: 'Overall Practice Accuracy',
              isDark: isDark,
            ),
            const SizedBox(height: LingoSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Achievements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: LingoColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AchievementsGrid(
              unlocked: progress.achievements,
            ),
            const SizedBox(height: LingoSpacing.xxl),
          ],
        ),
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
      padding: const EdgeInsets.all(LingoSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LingoColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: LingoColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Center(
              child: Text(
                '$level',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: LingoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level Learner',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$intoLevel / ${XpLevels.xpPerLevel} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$toNext XP to reach Level ${level + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: unlocked
          ? LingoColors.accent.withValues(alpha: 0.12)
          : isDark
              ? LingoColors.darkSurface
              : Colors.white,
      borderRadius: BorderRadius.circular(LingoRadius.md),
      child: InkWell(
        onTap: () => _showAchievementDetail(context),
        borderRadius: BorderRadius.circular(LingoRadius.md),
        child: Container(
          padding: const EdgeInsets.all(LingoSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LingoRadius.md),
            border: Border.all(
              color: unlocked
                  ? LingoColors.accent.withValues(alpha: 0.5)
                  : isDark
                      ? LingoColors.darkDivider
                      : theme.dividerColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 28,
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
                  fontWeight: FontWeight.w700,
                  color: unlocked
                      ? (isDark ? Colors.white : LingoColors.textPrimary)
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    unlocked ? 'Unlocked 🎉' : 'Locked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? LingoColors.secondary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(achievement.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? LingoColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(
          color: isDark ? LingoColors.darkDivider : theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: LingoSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}