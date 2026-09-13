import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learner_provider.dart';
import '../../providers/theme_provider.dart';

/// App settings: appearance (theme mode) and account actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.lg,
          vertical: LingoSpacing.md,
        ),
        children: [
          _SectionLabel(title: 'Appearance'),
          const SizedBox(height: LingoSpacing.sm),
          Container(
            padding: const EdgeInsets.all(LingoSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(LingoRadius.lg),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dark_mode_outlined,
                        color: LingoColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Theme',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LingoSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 18),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 18),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 18),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setMode(selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LingoSpacing.lg),
          _SectionLabel(title: 'Account'),
          const SizedBox(height: LingoSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(LingoRadius.lg),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                if (user != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      child: Text(
                        (user.displayName?.isNotEmpty ?? false)
                            ? user.displayName![0].toUpperCase()
                            : (user.email?.isNotEmpty ?? false)
                                ? user.email![0].toUpperCase()
                                : 'L',
                      ),
                    ),
                    title: Text(
                      user.displayName ?? 'LINGO User',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(user.email ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded,
                        color: LingoColors.error),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(color: LingoColors.error),
                    ),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded,
                      color: LingoColors.accent),
                  title: const Text(
                    'Reset progress',
                    style: TextStyle(color: LingoColors.accent),
                  ),
                  subtitle: const Text('Erases XP, lessons, and sign history'),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: LingoSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'This will erase your XP, lessons completed, and mastered signs. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset', style: TextStyle(color: LingoColors.error)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(learnerStateProvider.notifier).reset();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: LingoColors.primary,
          ),
    );
  }
}