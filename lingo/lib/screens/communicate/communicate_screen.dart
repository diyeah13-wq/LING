import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../services/ml/sign_recognition_engine.dart';
import '../camera/detection_camera_screen.dart';

/// Communication mode: turns performed signs into spoken text.
///
/// This is a live-camera prototype. Confirmed recognitions are appended to a
/// text stream so the user builds up a sentence from the supported ASL signs.
class CommunicateScreen extends ConsumerStatefulWidget {
  const CommunicateScreen({super.key});

  @override
  ConsumerState<CommunicateScreen> createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends ConsumerState<CommunicateScreen> {
  final List<String> _phrase = [];

  void _append(ConfirmedSign confirmed) {
    final signId = confirmed.classification.signId;
    if (signId == null) return;
    final text = LessonCatalog.signById(signId)?.text ?? signId;
    setState(() => _phrase.add(text));
  }

  void _clear() => setState(() => _phrase.clear());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Communicate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About the prototype',
            onPressed: () => _showPrototypeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear phrase',
            onPressed: _phrase.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Phrase output strip.
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(LingoSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _phrase.isEmpty
                  ? Text(
                      'Recognized signs will appear here. Perform a supported '
                      'sign in front of the camera.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white60),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final word in _phrase)
                          Chip(
                            label: Text(word),
                            backgroundColor:
                                LingoColors.primary.withValues(alpha: 0.4),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
            ),
            // Live camera with free recognition.
            Expanded(
              child: DetectionCameraFeed(onConfirmed: _append),
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

/// A camera feed that continuously recognizes signs and reports confirmations
/// to the parent (used by [CommunicateScreen]). Uses the embedded mode of
/// [DetectionCameraScreen] so it renders only the camera + overlay.
class DetectionCameraFeed extends StatelessWidget {
  final void Function(ConfirmedSign) onConfirmed;
  const DetectionCameraFeed({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DetectionCameraScreen(
        onConfirmed: onConfirmed,
        embedded: true,
      ),
    );
  }
}