import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_detection/hand_detection.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../data/model_vocabulary.dart';
import '../../models/lesson.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../services/grading/sign_grading_service.dart';
import '../../services/ml/sign_recognition_engine.dart';
import '../../services/ml/tflite_sign_classifier.dart';
import '../../services/ml/tflite_static_sign_classifier.dart';
import '../../widgets/common/sign_video_player.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/mascot/mascot_messages.dart';

/// Multi-sign practice session for a full lesson with graded completion.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const PracticeSessionScreen({super.key, required this.lessonId});

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  SignRecognitionEngine? _engine;
  StreamSubscription<RecognitionState>? _stateSub;
  StreamSubscription<ConfirmedSign>? _confirmSub;

  bool _initializing = true;
  String? _initError;
  RecognitionState _state = const RecognitionState();

  int _currentIndex = 0;
  int _correctCount = 0;
  int _attemptCount = 0;
  final List<double> _confidences = [];
  bool _showCelebration = false;
  bool _sessionComplete = false;
  bool _busy = false;

  /// Last wrong sign we already showed a hint for; repeated confirmations of
  /// the same wrong sign while it's held are ignored so the message doesn't
  /// spam (and attempts aren't double-counted).
  String? _lastWrongSignId;

  Lesson get _lesson => LessonCatalog.lessonById(widget.lessonId)!;
  List<Sign> get _signs => _lesson.signs;
  Sign get _currentSign => _signs[_currentIndex];
  bool get _isLastSign => _currentIndex >= _signs.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _confirmSub?.cancel();
    _controller?.dispose();
    _engine?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(controller);
    }
  }

  Future<void> _boot() async {
    setState(() {
      _initializing = true;
      _initError = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No camera available.');
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await _initController(controller);

      final detector = await HandDetector.create(
        mode: HandMode.boxesAndLandmarks,
        detectorConf: 0.6,
        maxDetections: 1,
      );
      final isStatic = _signs.every((sign) => sign.type == SignType.static);
      final classifier = isStatic
          ? (TfliteStaticSignClassifier()
            ..setLabels(ModelVocabulary.staticLabels))
          : (TfliteSignClassifier()..setLabels(ModelVocabulary.labels));
      await classifier.load();

      final supportedIds = _signs
          .map((s) => s.id)
          .where((id) => classifier.supportedSigns.contains(id))
          .toSet();

      _engine = SignRecognitionEngine(
        detector: detector,
        classifier: classifier,
        supportedSignIds: supportedIds.isEmpty ? null : supportedIds,
        // Static lessons (alphabet/numbers) confirm on a gentler threshold.
        confirmThreshold: isStatic ? 0.42 : 0.55,
      );

      _stateSub = _engine!.states.listen(
        (s) {
          if (mounted) setState(() => _state = s);
        },
        onError: (Object _) {},
      );
      _confirmSub = _engine!.confirmations.listen(_onConfirmed);

      setState(() => _initializing = false);
    } catch (e) {
      setState(() {
        _initError = 'Camera could not be started: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _initController(CameraController controller) async {
    if (controller.value.isInitialized) return;
    await controller.initialize();
    await controller.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    final engine = _engine;
    if (engine == null || _sessionComplete) return;
    final controller = _controller;
    if (controller == null) return;
    final rotation = rotationForCamera(controller: controller, image: image);
    await engine.processCameraFrame(
      image,
      rotation: rotation ?? CameraFrameRotation.cw90,
    );
  }

  Future<void> _onConfirmed(ConfirmedSign confirmed) async {
    if (!mounted || _busy || _sessionComplete) return;
    final signId = confirmed.classification.signId;
    if (signId == null) return;

    _busy = true;
    try {
      final notifier = ref.read(learnerStateProvider.notifier);
      final confidence = confirmed.classification.confidence ?? 0.8;

      if (signId == _currentSign.id) {
        // Correct match!
        _confidences.add(confidence);
        await notifier.learnSign(signId);
        await notifier.addXp(20);
        await notifier.recordAttempt(success: true);

        setState(() {
          _correctCount++;
          _attemptCount++;
          _showCelebration = true;
        });

        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() => _showCelebration = false);
        _advance();
      } else {
        // Wrong sign performed. Only react to a distinct wrong sign so the
        // hint doesn't repeat while the same wrong letter is held.
        if (signId == _lastWrongSignId) {
          return;
        }
        _lastWrongSignId = signId;
        await notifier.recordAttempt(success: false);
        setState(() => _attemptCount++);
        _showHint(signId);
      }
    } finally {
      _busy = false;
    }
  }

  void _advance() {
    _lastWrongSignId = null;
    if (_isLastSign) {
      setState(() => _sessionComplete = true);
      ref.read(learnerStateProvider.notifier).completeLesson();
    } else {
      setState(() => _currentIndex++);
      _engine?.reset();
    }
  }

  void _showHint(String detectedSignId) {
    final detected =
        LessonCatalog.signById(detectedSignId)?.text ?? detectedSignId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detected "$detected". Try performing "${_currentSign.text}" again!',
        ),
        backgroundColor: LingoColors.accent,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVideoDemo() {
    showSignVideoModal(context, _currentSign);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initializing
            ? const _LoadingView()
            : _initError != null
                ? _ErrorView(message: _initError!, onRetry: _boot)
                : _sessionComplete
                    ? _buildComplete()
                    : _buildPractice(),
      ),
    );
  }

  Widget _buildPractice() {
    final controller = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview.
        Center(child: CameraPreview(controller)),
        // Framing guide outline
        Center(
          child: Container(
            width: 280,
            height: 380,
            decoration: BoxDecoration(
              border: Border.all(
                color: _state.hasHand
                    ? LingoColors.secondary.withValues(alpha: 0.6)
                    : Colors.white24,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        // Skeleton overlay.
        if (_state.hasHand)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CameraHandOverlayPainter(
                  hands: _state.hands,
                  imageSize: _state.imageSize,
                  mirrorHorizontally: true,
                ),
              ),
            ),
          ),
        // Top: progress + sign info.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _SessionHeader(
            lesson: _lesson,
            currentIndex: _currentIndex,
            total: _signs.length,
            sign: _currentSign,
            state: _state,
            onClose: () => Navigator.of(context).maybePop(),
          ),
        ),
        // Mascot celebration on correct sign.
        if (_showCelebration)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: _MascotCelebration(sign: _currentSign),
            ),
          ),
        // Bottom bar with Video Peek button and hints.
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed: _showVideoDemo,
                  icon: const Icon(Icons.ondemand_video,
                      size: 18, color: Colors.white),
                  label: Text(
                    'Watch "${_currentSign.text}" Demo',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _state.hasHand
                      ? 'Hold "${_currentSign.text}" steady…'
                      : 'Show your hand inside the frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComplete() {
    final theme = Theme.of(context);
    final summary = SignGradingService.evaluateSession(
      lessonTitle: _lesson.title,
      totalSigns: _signs.length,
      correctSigns: _correctCount,
      totalAttempts: _attemptCount > 0 ? _attemptCount : _signs.length,
      confidences: _confidences,
      baseXp: _lesson.xpReward,
    );

    final grade = summary.overallGrade;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LingoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 88, mood: MascotMood.celebrating)
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: LingoSpacing.md),
            Text(
              MascotMessages.lessonComplete(_lesson.title),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: LingoSpacing.md),

            // Grade Badge Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: grade.color.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: grade.color.withValues(alpha: 0.2),
                          border: Border.all(color: grade.color, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            grade.letter,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: grade.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Grade: ${grade.letter}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            grade.label,
                            style: TextStyle(
                              color: grade.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Accuracy',
                        value: '${summary.accuracyPercentage}%',
                        color: LingoColors.secondary,
                      ),
                      _StatColumn(
                        label: 'Signs',
                        value: '$_correctCount / ${_signs.length}',
                        color: Colors.white,
                      ),
                      _StatColumn(
                        label: 'Total XP',
                        value: '+${summary.totalXpEarned}',
                        color: LingoColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: LingoSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _correctCount = 0;
                        _attemptCount = 0;
                        _confidences.clear();
                        _sessionComplete = false;
                        _lastWrongSignId = null;
                      });
                      _engine?.reset();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Practice Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LingoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final Lesson lesson;
  final int currentIndex;
  final int total;
  final Sign sign;
  final RecognitionState state;
  final VoidCallback onClose;

  const _SessionHeader({
    required this.lesson,
    required this.currentIndex,
    required this.total,
    required this.sign,
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prediction = state.prediction;
    final hasPred = prediction != null && prediction.isRecognized;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Exit practice',
              ),
              const SizedBox(width: 12),
              Text(sign.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign "${sign.text}"',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sign ${currentIndex + 1} of $total · ${lesson.title}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.hasHand)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LingoColors.secondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LingoColors.secondary, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: LingoColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Hand tracked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentIndex + 1) / total,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(LingoColors.primary),
            minHeight: 5,
            borderRadius: BorderRadius.circular(6),
          ),
          if (hasPred) ...[
            const SizedBox(height: 8),
            Text(
              'Recognizing: ${LessonCatalog.signById(prediction.signId!)?.text ?? prediction.signId!} (${(prediction.confidence! * 100).round()}%)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _MascotCelebration extends StatelessWidget {
  final Sign sign;
  const _MascotCelebration({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LingoColors.secondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: LingoColors.secondary.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(size: 48, mood: MascotMood.celebrating),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Correct! +20 XP',
                style: TextStyle(
                  color: LingoColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '${sign.text} mastered',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: LingoColors.primary),
          SizedBox(height: LingoSpacing.md),
          Text('Starting practice camera…',
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LingoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 56),
            const SizedBox(height: LingoSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: LingoSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
