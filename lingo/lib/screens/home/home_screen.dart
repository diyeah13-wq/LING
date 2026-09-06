import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/learner_provider.dart';
import '../../widgets/common/xp_badge.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/mascot/mascot_messages.dart';

/// Landing screen shown after onboarding. Presents the main learner actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerStateProvider);
    final profile = state.profile;
    final progress = state.progress;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg),
          children: [
            const SizedBox(height: LingoSpacing.sm),
            _buildHeader(context, theme, profile?.name ?? 'Learner', progress.xp),
            const SizedBox(height: LingoSpacing.md),
            _buildMascotGreeting(theme, profile?.name),
            const SizedBox(height: LingoSpacing.lg),
            _buildQuickStats(theme, progress),
            const SizedBox(height: LingoSpacing.lg),
            _buildActionGrid(context, theme),
            const SizedBox(height: LingoSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, String name, int xp) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_timeOfDayGreeting()}', style: theme.textTheme.bodyMedium),
            Text(name, style: theme.textTheme.headlineSmall),
          ],
        ),
        const Spacer(),
        XpBadge(xp: xp),
      ],
    );
  }

  Widget _buildMascotGreeting(ThemeData theme, String? name) {
    return Row(
      children: [
        const Mascot(mood: MascotMood.greeting, size: 72),
        const SizedBox(width: LingoSpacing.md),
        Expanded(
          child: Text(
            MascotMessages.greeting(name),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ThemeData theme, progress) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            color: const Color(0xFFF97316),
            value: '${progress.streak}',
            label: 'Day streak',
          ),
        ),
        const SizedBox(width: LingoSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book,
            color: LingoColors.primary,
            value: '${progress.lessonsCompleted}',
            label: 'Lessons',
          ),
        ),
        const SizedBox(width: LingoSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.verified,
            color: LingoColors.secondary,
            value: '${progress.signsLearned.length}',
            label: 'Signs',
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start learning', style: theme.textTheme.titleMedium),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.school,
          color: LingoColors.primary,
          title: 'Learn signs',
          subtitle: 'Structured lessons & demonstrations',
          onTap: () => context.go('/learn'),
        ),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.videocam,
          color: const Color(0xFF8B5CF6),
          title: 'Practice with camera',
          subtitle: 'Sign into your phone camera',
          onTap: () => context.go('/practice'),
        ),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.campaign,
          color: LingoColors.secondary,
          title: 'Communicate',
          subtitle: 'Turn signs into text (limited vocab)',
          onTap: () => context.go('/communicate'),
        ),
      ],
    );
  }

  String _timeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: LingoSpacing.sm),
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(LingoRadius.md),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}