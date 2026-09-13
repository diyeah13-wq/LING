import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_detection/hand_detection.dart';

import '../../config/theme.dart';
import '../../data/lesson_catalog.dart';
import '../../data/model_vocabulary.dart';
import '../../models/sign.dart';
import '../../providers/learner_provider.dart';
import '../../services/grading/sign_grading_service.dart';
import '../../services/ml/sign_recognition_engine.dart';
import '../../services/ml/tflite_sign_classifier.dart';
import '../../services/ml/tflite_static_sign_classifier.dart';
import '../../widgets/common/sign_video_player.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/practice/grading_result_sheet.dart';

/// Full-screen live sign recognition.
///
/// Two modes:
///  * [expectedSignId] set   → practice/graded test: user signs one target; evaluation
///    sheet with letter grade (A–F), feedback, and XP awarded.
///  * [expectedSignId] null  → communicate: free-form recognition turns
///    performed signs into detected words.
class DetectionCameraScreen extends ConsumerStatefulWidget {
  final String? expectedSignId;

  /// Optional callback invoked for every confirmed recognition (commonly used
  /// by the Communicate free-form mode to stream words out).
  final void Function(ConfirmedSign confirmed)? onConfirmed;

  /// When true, renders only the camera + overlay stack (no Scaffold / status
  /// chrome), so the screen can be embedded inside a parent layout.
  final bool embedded;

  const DetectionCameraScreen({
    super.key,
    this.expectedSignId,
    this.onConfirmed,
    this.embedded = false,
  });

  @override
  ConsumerState<DetectionCameraScreen> createState() =>
      _DetectionCameraScreenState();
}

class _DetectionCameraScreenState extends ConsumerState<DetectionCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  SignRecognitionEngine? _engine;
  StreamSubscription<RecognitionState>? _stateSub;
  StreamSubscription<ConfirmedSign>? _confirmSub;

  bool _initializing = true;
  String? _initError;
  RecognitionState _state = const RecognitionState();
  ConfirmedSign? _lastConfirmed;
  bool _busy = false;
  bool _gradingSheetActive = false;

  bool get _isPractice => widget.expectedSignId != null;

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
      // Prefer the front camera for selfie-style signing.
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      await _buildEngine();

      final controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await _initController(controller);

      setState(() => _initializing = false);
    } catch (e) {
      setState(() {
        _initError = 'Camera could not be started: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _buildEngine() async {
    final detector = await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      detectorConf: 0.6,
      maxDetections: 1,
    );
    final expected = widget.expectedSignId == null
        ? null
        : LessonCatalog.signById(widget.expectedSignId!);
    final isStatic = expected?.type == SignType.static;
    final classifier = isStatic
        ? (TfliteStaticSignClassifier()
          ..setLabels(ModelVocabulary.staticLabels))
        : (TfliteSignClassifier()..setLabels(ModelVocabulary.labels));
    await classifier.load();

    final supported = _isPractice
        ? {widget.expectedSignId!}
        : LessonCatalog.allSigns
            .where((s) => classifier.supportedSigns.contains(s.id))
            .map((s) => s.id)
            .toSet();

    _engine = SignRecognitionEngine(
      detector: detector,
      classifier: classifier,
      supportedSignIds: supported.isEmpty ? null : supported,
      // Static handshapes (alphabet/numbers) are easier for the on-device
      // model than motion signs, so grade them with a gentler threshold.
      confirmThreshold: isStatic ? 0.42 : 0.55,
    );

    _stateSub = _engine!.states.listen(
      (s) {
        if (mounted && !_gradingSheetActive) setState(() => _state = s);
      },
      onError: (Object _) {},
    );
    _confirmSub = _engine!.confirmations.listen(_onConfirmed);
  }

  Future<void> _initController(CameraController controller) async {
    if (controller.value.isInitialized) return;
    await controller.initialize();
    await controller.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_gradingSheetActive) return;
    final engine = _engine;
    if (engine == null) return;
    final controller = _controller;
    if (controller == null) return;
    final rotation = rotationForCamera(controller: controller, image: image);
    await engine.processCameraFrame(
      image,
      rotation: rotation ?? CameraFrameRotation.cw90,
    );
  }

  Future<void> _onConfirmed(ConfirmedSign confirmed) async {
    if (!mounted || _busy || _gradingSheetActive) return;
    setState(() => _lastConfirmed = confirmed);

    widget.onConfirmed?.call(confirmed);

    final signId = confirmed.classification.signId;
    if (signId == null) return;

    if (_isPractice) {
      final expectedId = widget.expectedSignId;
      if (expectedId == null) return;
      final expectedSign = LessonCatalog.signById(expectedId);
      if (expectedSign == null) return;

      _busy = true;
      try {
        final confidence = confirmed.classification.confidence ?? 0.0;
        final result = SignGradingService.evaluate(
          targetSign: expectedSign,
          detectedSignId: signId,
          confidence: confidence,
        );

        final notifier = ref.read(learnerStateProvider.notifier);
        await notifier.recordAttempt(success: result.isMatch);
        if (result.isMatch) {
          await notifier.learnSign(expectedId);
          if (result.xpEarned > 0) {
            await notifier.addXp(result.xpEarned);
          }
        }

        if (!mounted) return;
        setState(() => _gradingSheetActive = true);

        await GradingResultSheet.show(
          context,
          result: result,
          onTryAgain: () {
            setState(() {
              _gradingSheetActive = false;
              _lastConfirmed = null;
            });
            _engine?.reset();
          },
          onContinue: () {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          },
        );
      } finally {
        _busy = false;
        if (mounted) {
          setState(() => _gradingSheetActive = false);
        }
      }
    }
  }

  void _showVideoDemo() {
    final expected = widget.expectedSignId;
    if (expected == null) return;
    final sign = LessonCatalog.signById(expected);
    if (sign == null) return;
    showSignVideoModal(context, sign);
  }

  @override
  Widget build(BuildContext context) {
    final content = _initializing
        ? const _LoadingView()
        : _initError != null
            ? _ErrorView(message: _initError!, onRetry: _boot)
            : _buildLive();

    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: content),
    );
  }

  Widget _buildLive() {
    final controller = _controller!;
    final expectedSign = widget.expectedSignId != null
        ? LessonCatalog.signById(widget.expectedSignId!)
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
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
        // Live landmark overlay.
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
        // Top status panel (full-screen mode only).
        if (!widget.embedded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StatusBar(
              widget: this,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
        // Mascot in top-right corner (full-screen mode only).
        if (!widget.embedded)
          Positioned(
            top: 14,
            right: 14,
            child: _MascotCorner(state: _state, lastConfirmed: _lastConfirmed),
          ),
        // Bottom controls & video hint button (full-screen mode only).
        if (!widget.embedded)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expectedSign != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: _showVideoDemo,
                      icon: const Icon(Icons.ondemand_video,
                          size: 18, color: Colors.white),
                      label: const Text(
                        'Watch Reference Demo',
                        style: TextStyle(
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
                _BottomHint(widget: this),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final _DetectionCameraScreenState widget;
  final VoidCallback onBack;

  const _StatusBar({required this.widget, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = widget.widget.expectedSignId;
    final expectedSign =
        expected != null ? LessonCatalog.signById(expected) : null;
    final state = widget._state;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 72, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          if (expectedSign != null) ...[
            Text(expectedSign.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expectedSign != null
                      ? 'Sign "${expectedSign.text}"'
                      : 'Communicate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  expectedSign != null
                      ? 'Hold sign steady inside the frame'
                      : 'Free-form ASL recognition',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  SizedBox(width: 5),
                  Text(
                    'Hand detected',
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
    );
  }
}

class _BottomHint extends StatelessWidget {
  final _DetectionCameraScreenState widget;
  const _BottomHint({required this.widget});

  @override
  Widget build(BuildContext context) {
    final state = widget._state;
    final pred = state.prediction;
    final hasPrediction = pred != null && pred.isRecognized;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.hasHand ? Icons.back_hand : Icons.pan_tool_alt_outlined,
            size: 16,
            color: state.hasHand ? LingoColors.secondary : Colors.white60,
          ),
          const SizedBox(width: 8),
          Text(
            hasPrediction
                ? 'Recognizing: ${LessonCatalog.signById(pred.signId!)?.text ?? pred.signId!} (${(pred.confidence! * 100).round()}%)'
                : state.hasHand
                    ? 'Analyzing hand motion…'
                    : 'Show your hand clearly to the camera',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotCorner extends StatelessWidget {
  final RecognitionState state;
  final ConfirmedSign? lastConfirmed;
  const _MascotCorner({required this.state, required this.lastConfirmed});

  @override
  Widget build(BuildContext context) {
    MascotMood mood;
    if (lastConfirmed != null && lastConfirmed!.classification.isRecognized) {
      mood = MascotMood.celebrating;
    } else if (state.hasHand) {
      mood = MascotMood.encouraging;
    } else {
      mood = MascotMood.neutral;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Mascot(size: 44, mood: mood),
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
          Text('Starting camera…', style: TextStyle(color: Colors.white)),
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
