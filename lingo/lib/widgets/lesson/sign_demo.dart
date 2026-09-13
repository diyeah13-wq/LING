import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../data/model_vocabulary.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../screens/camera/practice_landing.dart';
import '../common/sign_video_player.dart';
import 'hand_demo.dart';

/// Shows a single sign's demonstration (looping video or animated handshape),
/// how-to explanation, and test launcher.
class SignDetailPage extends ConsumerStatefulWidget {
  final Sign sign;

  const SignDetailPage({super.key, required this.sign});

  @override
  ConsumerState<SignDetailPage> createState() => _SignDetailPageState();
}

class _SignDetailPageState extends ConsumerState<SignDetailPage> {
  int _selectedDemoTab = 0; // 0: Video (if available), 1: Handshape / Diagram

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final supportsCamera = ModelVocabulary.isModelSupported(sign.id);
    final theme = Theme.of(context);
    final learned =
        ref.watch(progressProvider).signsLearned.contains(sign.id);

    final hasVideo = sign.hasVideoReference;
    final hasImage = sign.resolvedReferenceImageAsset != null;
    final showTabs = hasVideo && hasImage;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg, vertical: LingoSpacing.md),
      children: [
        // Category / type chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sign.type == SignType.motion
                  ? LingoColors.primary.withValues(alpha: 0.12)
                  : LingoColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sign.type == SignType.motion
                      ? Icons.motion_photos_on_outlined
                      : Icons.back_hand_outlined,
                  size: 14,
                  color: sign.type == SignType.motion
                      ? LingoColors.primary
                      : LingoColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  sign.type == SignType.motion
                      ? 'Motion sign'
                      : 'Static handshape',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sign.type == SignType.motion
                        ? LingoColors.primary
                        : LingoColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sign text & meaning
        Text(
          sign.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sign.meaning,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
        ),
        if (learned) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: LingoColors.secondary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Mastered in your vocabulary',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: LingoColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Optional Segmented toggle if both video & image exist
        if (showTabs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.videocam_outlined, size: 16),
                    label: Text('Video Demo'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.image_outlined, size: 16),
                    label: Text('Hand Guide'),
                  ),
                ],
                selected: {_selectedDemoTab},
                onSelectionChanged: (set) =>
                    setState(() => _selectedDemoTab = set.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),

        // Demonstration area: Video or Hand Demo
        Center(
          child: (_selectedDemoTab == 0 && hasVideo)
              ? SignVideoPlayer(
                  videoAsset: sign.resolvedReferenceVideoAsset!,
                  height: 250,
                  fallbackImageAsset: sign.resolvedReferenceImageAsset,
                )
              : (hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(LingoRadius.lg),
                      child: Image.asset(
                        sign.resolvedReferenceImageAsset!,
                        width: 240,
                        height: 240,
                        fit: BoxFit.cover,
                        semanticLabel: 'Reference handshape for ${sign.text}',
                      ),
                    )
                  : AnimatedSignDemo(sign: sign, size: 220)),
        ).animate().scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 350.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: LingoSpacing.lg),

        _HowToCard(sign: sign),
        const SizedBox(height: LingoSpacing.lg),
        _PracticeCard(sign: sign, supportsCamera: supportsCamera),
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
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LingoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates_outlined,
                    color: LingoColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'How to perform',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          Text(
            sign.howToPerform,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (sign.tip != null) ...[
            const SizedBox(height: LingoSpacing.md),
            Container(
              padding: const EdgeInsets.all(LingoSpacing.md),
              decoration: BoxDecoration(
                color: LingoColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(LingoRadius.md),
                border: Border.all(
                  color: LingoColors.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: LingoColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sign.tip!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFB45309), // Warm amber text
                        fontWeight: FontWeight.w600,
                        height: 1.4,
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
  final bool supportsCamera;
  const _PracticeCard({required this.sign, required this.supportsCamera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supportsCamera) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.model_training_outlined, size: 20),
        label: const Text('Camera grading coming soon for this sign'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LingoRadius.md),
        gradient: const LinearGradient(
          colors: [LingoColors.primary, Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LingoColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PracticeCameraLanding(sign: sign),
            ),
          );
        },
        icon: const Icon(Icons.videocam_rounded, size: 22, color: Colors.white),
        label: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test with Camera',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'A–F Grade',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingoRadius.md),
          ),
        ),
      ),
    );
  }
}
