import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Communication mode: turn performed signs into text.
///
/// This prototype supports a limited vocabulary. The UI is clearly labeled
/// as a prototype.
class CommunicateScreen extends StatelessWidget {
  const CommunicateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communicate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About the prototype',
            onPressed: () => _showPrototypeDialog(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 72, color: LingoColors.secondary),
            const SizedBox(height: LingoSpacing.lg),
            Text('Communication mode coming soon',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: LingoSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xl),
              child: Text(
                'Perform supported signs in front of your camera and turn '
                'them into text.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrototypeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prototype notice'),
        content: const Text(
            'LINGO Communicate is a prototype with a limited vocabulary. '
            'It is not a full ASL translation app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}