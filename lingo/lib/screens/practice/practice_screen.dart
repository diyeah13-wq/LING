import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Placeholder for the practice/quiz mode. Replaced by the camera-driven
/// practice flow in a later stage.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gesture, size: 72, color: LingoColors.primary),
            const SizedBox(height: LingoSpacing.lg),
            Text('Practice mode coming soon',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: LingoSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xl),
              child: Text(
                'Challenge yourself with camera-based sign practice and '
                'earn XP along the way.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}