import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_detection/hand_detection.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../models/lesson.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../services/ml/sign_recognition_engine.dart';
import '../../services/ml/tflite_sign_classifier.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/mascot/mascot_messages.dart';

/// Multi-sign practice session for a full lesson.
///
/// Cycles through every sign in the lesson, showing a target card + camera
/// feed. When a sign is confirmed correctly the user earns XP and the
/// session advances. A completion summary is shown at the end.
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
  bool _showCelebration = false;
  bool _sessionComplete = false;
  bool _busy = false;

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

      final controller = CameraController(cam, ResolutionPreset.medium,
          enableAudio: false);
      _controller = controller;
      await _initController(controller);

      final detector = await HandDetector.create(
        mode: HandMode.boxesAndLandmarks,
        detectorConf: 0.6,
        maxDetections: 1,
      );
      final classifier = TfliteSignClassifier();
      await classifier.load();

      final supportedIds =
          _signs.map((s) => s.id).where((id) => classifier.supportedSigns.contains(id)).toSet();

      _engine = SignRecognitionEngine(
        detector: detector,
        classifier: classifier,
        supportedSignIds: supportedIds.isEmpty ? null : supportedIds,
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
      if (signId == _currentSign.id) {
        // Correct!
        await notifier.learnSign(signId);
        await notifier.addXp(20);
        await notifier.recordAttempt(success: true);
        setState(() {
          _correctCount++;
          _attemptCount++;
          _showCelebration = true;
        });
        // Wait for celebration then advance.
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        setState(() => _showCelebration = false);
        _advance();
      } else {
        // Wrong sign.
        await notifier.recordAttempt(success: false);
        setState(() => _attemptCount++);
        _showHint();
      }
    } finally {
      _busy = false;
    }
  }

  void _advance() {
    if (_isLastSign) {
      setState(() => _sessionComplete = true);
      ref.read(learnerStateProvider.notifier).completeLesson();
    } else {
      setState(() => _currentIndex++);
      _engine?.reset();
    }
  }

  void _showHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(MascotMessages.incorrect(_currentSign.text)),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          ),
        ),
        // Mascot reaction.
        if (_showCelebration)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: _MascotCelebration(sign: _currentSign),
            ),
          ),
        // Bottom hint.
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _state.hasHand
                    ? 'Hold "${_currentSign.text}" steady…'
                    : 'Show your hand to the camera',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplete() {
    final theme = Theme.of(context);
    final learned = ref.watch(progressProvider).signsLearned;
    final learnedInLesson =
        _signs.where((s) => learned.contains(s.id)).length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LingoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 100, mood: MascotMood.celebrating),
            const SizedBox(height: LingoSpacing.lg),
            Text(
              MascotMessages.lessonComplete(_lesson.title),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: LingoSpacing.md),
            Text(
              '$_correctCount / ${_signs.length} signs learned',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: LingoSpacing.sm),
            LinearProgressIndicator(
              value: learnedInLesson / _signs.length,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(LingoColors.secondary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: LingoSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to lesson'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final Lesson lesson;
  final int currentIndex;
  final int total;
  final Sign sign;
  final RecognitionState state;

  const _SessionHeader({
    required this.lesson,
    required this.currentIndex,
    required this.total,
    required this.sign,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prediction = state.prediction;
    final hasPred = prediction != null && prediction.isRecognized;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(sign.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign "${sign.text}"',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      '${currentIndex + 1} of $total',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentIndex + 1) / total,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(LingoColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                state.hasHand ? Icons.back_hand : Icons.pan_tool_alt_outlined,
                size: 18,
                color: state.hasHand ? LingoColors.primary : Colors.white60,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hasPred
                      ? LessonCatalog.signById(prediction.signId!)?.text ??
                          prediction.signId!
                      : state.hasHand
                          ? 'Looking…'
                          : 'No hand detected',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(size: 64, mood: MascotMood.celebrating),
          const SizedBox(height: 8),
          Text(
            MascotMessages.correct(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '+20 XP',
            style: TextStyle(
              color: LingoColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          Text('Setting up practice…',
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