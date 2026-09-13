import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learner_provider.dart';
import '../../widgets/common/xp_badge.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/mascot/mascot_messages.dart';
import '../camera/practice_landing.dart';
import '../practice/practice_session_screen.dart';

/// Landing screen shown after onboarding. Presents the main learner actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerStateProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final profile = state.profile;
    final progress = state.progress;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName = _resolveDisplayName(profile?.name, authUser?.displayName);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LingoSpacing.lg,
            vertical: LingoSpacing.md,
          ),
          children: [
            _buildHeader(context, theme, displayName, progress.xp),
            const SizedBox(height: LingoSpacing.lg),
            _buildHeroBanner(context, theme, displayName, isDark),
            const SizedBox(height: LingoSpacing.lg),
            _buildQuickStats(theme, progress, isDark),
            const SizedBox(height: LingoSpacing.xl),
            _buildActionGrid(context, theme, isDark),
            const SizedBox(height: LingoSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Prefers the onboarded profile name, then the account display name.
  String _resolveDisplayName(String? localName, String? accountName) {
    if (localName != null && localName.trim().isNotEmpty) {
      return localName.trim();
    }
    if (accountName != null && accountName.trim().isNotEmpty) {
      return accountName.trim();
    }
    return 'Learner';
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, String name, int xp) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LingoColors.primary, Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LingoColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'L',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_timeOfDayGreeting()},',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          color: theme.textTheme.bodyMedium?.color,
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
        XpBadge(xp: xp),
      ],
    );
  }

  Widget _buildHeroBanner(
      BuildContext context, ThemeData theme, String? name, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md + 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(
          color: LingoColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Mascot(mood: MascotMood.greeting, size: 68),
          const SizedBox(width: LingoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to LINGO!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LingoColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MascotMessages.greeting(name),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, dynamic progress, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            color: const Color(0xFFF97316),
            value: '${progress.streak}',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: LingoSpacing.sm + 4),
        Expanded(
          child: _StatCard(
            icon: Icons.school,
            color: LingoColors.primary,
            value: '${progress.lessonsCompleted}',
            label: 'Lessons',
          ),
        ),
        const SizedBox(width: LingoSpacing.sm + 4),
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            color: LingoColors.secondary,
            value: '${progress.signsLearned.length}',
            label: 'Signs',
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Practice & Learn',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.menu_book_rounded,
          color: LingoColors.primary,
          title: 'Learn ASL Lessons',
          subtitle: 'Step-by-step vocabulary & video guides',
          badgeText: 'Curriculum',
          onTap: () => context.go('/learn'),
        ),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.videocam_rounded,
          color: const Color(0xFF8B5CF6),
          title: 'Camera Practice Hub',
          subtitle: 'Test your signs with live A–F grading',
          badgeText: 'AI Graded',
          onTap: () => _showPracticeHub(context),
        ),
        const SizedBox(height: LingoSpacing.md),
        _ActionTile(
          icon: Icons.chat_bubble_rounded,
          color: LingoColors.secondary,
          title: 'Communicate Mode',
          subtitle: 'Free-form live sign-to-text translation',
          badgeText: 'Live Stream',
          onTap: () => context.go('/communicate'),
        ),
      ],
    );
  }

  void _showPracticeHub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? LingoColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Practice Mode',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Select how you would like to test your ASL signing:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _HubOption(
                  icon: Icons.play_lesson_outlined,
                  color: LingoColors.primary,
                  title: 'Full Lesson Practice',
                  subtitle: 'Cycle through lesson signs with graded completion',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickLessonToPractice(context);
                  },
                ),
                const SizedBox(height: 12),
                _HubOption(
                  icon: Icons.grade_outlined,
                  color: const Color(0xFF8B5CF6),
                  title: 'Test a Specific Sign',
                  subtitle: 'Get instant letter grade (A–F) and AI feedback',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickSignToTest(context);
                  },
                ),
                const SizedBox(height: 12),
                _HubOption(
                  icon: Icons.campaign_outlined,
                  color: LingoColors.secondary,
                  title: 'Free-form Communicate',
                  subtitle: 'Perform any sign without a target',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/communicate');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickLessonToPractice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final lessons = LessonCatalog.lessons;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? LingoColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Lesson',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lessons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final l = lessons[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      leading: Text(l.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(l.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${l.signs.length} signs'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PracticeSessionScreen(lessonId: l.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickSignToTest(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final signs = LessonCatalog.allSigns;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? LingoColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Sign to Test',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Instant letter grading (A+, A, B, C, D) with AI coaching',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: signs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = signs[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      leading: Text(s.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(s.text,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(s.meaning, maxLines: 1),
                      trailing: const Icon(Icons.videocam_outlined,
                          color: LingoColors.primary),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PracticeCameraLanding(sign: s),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }
}

class _HubOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubOption({
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? LingoColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(
          color: isDark ? LingoColors.darkDivider : LingoColors.divider,
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
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
  final String badgeText;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              color: isDark ? LingoColors.darkDivider : LingoColors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(LingoRadius.md),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}