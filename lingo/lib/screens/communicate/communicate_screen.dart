import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../services/ml/sign_recognition_engine.dart';
import '../camera/detection_camera_screen.dart';

/// Communication mode: turns performed signs into sentences.
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

  void _copyPhrase() {
    if (_phrase.isEmpty) return;
    final text = _phrase.join(' ');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied phrase: "$text"'),
        backgroundColor: LingoColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeWordAt(int index) {
    setState(() => _phrase.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Live Communicate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Supported Vocabulary',
            onPressed: () => _showVocabularyDialog(context),
          ),
          if (_phrase.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white),
              tooltip: 'Copy text',
              onPressed: _copyPhrase,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: _clear,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Phrase output bubble
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Translated Phrase (${_phrase.length} words)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_phrase.isNotEmpty)
                        InkWell(
                          onTap: _clear,
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: LingoColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_phrase.isEmpty)
                    Text(
                      'Perform signs in front of the camera. Recognized words will appear here automatically.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < _phrase.length; i++)
                          Chip(
                            label: Text(_phrase[i]),
                            backgroundColor:
                                LingoColors.primary.withValues(alpha: 0.5),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            deleteIconColor: Colors.white70,
                            onDeleted: () => _removeWordAt(i),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.white24),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            // Live camera feed
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: DetectionCameraFeed(onConfirmed: _append),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVocabularyDialog(BuildContext context) {
    final vocab = LessonCatalog.allSigns;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supported Vocabulary'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LINGO recognizes signs from your curriculum vocabulary:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in vocab)
                        Chip(
                          avatar: Text(s.emoji),
                          label: Text(s.text),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

/// Embedded camera feed that reports confirmed recognitions to CommunicateScreen.
class DetectionCameraFeed extends StatelessWidget {
  final void Function(ConfirmedSign) onConfirmed;
  const DetectionCameraFeed({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return DetectionCameraScreen(
      onConfirmed: onConfirmed,
      embedded: true,
    );
  }
}