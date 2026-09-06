import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../screens/camera/practice_landing.dart';
import 'hand_demo.dart';

/// Shows a single sign's meaning, a simple demonstration, and how-to.
///
/// The demonstration is a lightweight animated hand illustration. This widget
/// is deliberately structured so a future video player / Lottie animation can
/// replace the custom painting without changing the rest of the app.
class SignDetailPage extends ConsumerWidget {
  final Sign sign;

  const SignDetailPage({super.key, required this.sign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final learned =
        ref.watch(progressProvider).signsLearned.contains(sign.id);

    return ListView(
      padding: const EdgeInsets.all(LingoSpacing.lg),
      children: [
        // Center the demo and let it animate on open.
        Center(
          child: AnimatedSignDemo(
            sign: sign,
            size: 200,
          ).animate().scale(
                begin: Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ),
        const SizedBox(height: LingoSpacing.lg),
        Text(
          sign.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: LingoSpacing.sm),
        Text(
          sign.meaning,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
        if (learned) ...[
          const SizedBox(height: LingoSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: LingoColors.secondary, size: 18),
              const SizedBox(width: 6),
              Text('Learned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: LingoColors.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
        const SizedBox(height: LingoSpacing.xl),
        _HowToCard(sign: sign),
        const SizedBox(height: LingoSpacing.xl),
        _PracticeCard(sign: sign),
        const SizedBox(height: LingoSpacing.xxl),
      ],
    );
  }
}

class _HowToCard extends StatelessWidget {
  final Sign sign;
  const _HowToCard({required this.sign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LingoSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: LingoColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('How to sign', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          Text(sign.howToPerform, style: theme.textTheme.bodyMedium),
          if (sign.tip != null) ...[
            const SizedBox(height: LingoSpacing.md),
            Container(
              padding: const EdgeInsets.all(LingoSpacing.md),
              decoration: BoxDecoration(
                color: LingoColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(LingoRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: LingoColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sign.tip!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LingoColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PracticeCard extends ConsumerWidget {
  final Sign sign;
  const _PracticeCard({required this.sign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PracticeCameraLanding(
              sign: sign,
            ),
          ),
        );
      },
      icon: const Icon(Icons.videocam, size: 20),
      label: const Text('Practice this sign'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }
}