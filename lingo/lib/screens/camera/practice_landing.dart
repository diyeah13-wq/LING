import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/sign.dart';
import '../../widgets/lesson/hand_demo.dart';

/// Placeholder landing screen for camera practice.
///
/// Stage 5 uses this as a stub while the camera pipeline is built out. It
/// shows the sign to practice and explains that camera practice works on
/// mobile devices.
class PracticeCameraLanding extends ConsumerWidget {
  final Sign sign;

  const PracticeCameraLanding({super.key, required this.sign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Practice: ${sign.text}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LingoSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam,
                  size: 72, color: LingoColors.primary),
              const SizedBox(height: LingoSpacing.lg),
              Text('Camera practice is coming soon',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: LingoSpacing.md),
              Text(
                'The full camera-based sign recognition flow is under '
                'construction. On a mobile device you\'ll be able to perform '
                'this sign in front of your camera and get instant feedback.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LingoSpacing.xl),
              AnimatedSignDemo(sign: sign, size: 140),
              const SizedBox(height: LingoSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to sign'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}