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
import '../../services/ml/sign_recognition_engine.dart';
import '../../services/ml/tflite_sign_classifier.dart';
import '../../services/ml/tflite_static_sign_classifier.dart';
import '../../widgets/mascot/mascot.dart';

/// Full-screen live sign recognition.
///
/// Two modes:
///  * [expectedSignId] set   → practice: user signs one target; XP awarded
///    when a confirmed recognition matches.
///  * [expectedSignId] null   → communicate: free-form recognition turns
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
    );

    _stateSub = _engine!.states.listen(
      (s) {
        if (mounted) setState(() => _state = s);
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
    if (!mounted) return;
    setState(() => _lastConfirmed = confirmed);

    widget.onConfirmed?.call(confirmed);

    final signId = confirmed.classification.signId;
    if (signId == null) return;

    if (_isPractice) {
      final expected = widget.expectedSignId;
      if (expected == null || _busy) return;
      _busy = true;
      try {
        final notifier = ref.read(learnerStateProvider.notifier);
        if (signId == expected) {
          await notifier.learnSign(expected);
          await notifier.addXp(15);
          await notifier.recordAttempt(success: true);
          _celebrate();
        } else {
          await notifier.recordAttempt(success: false);
        }
      } finally {
        _busy = false;
      }
    }
  }

  void _celebrate() {
    if (_lastConfirmed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Correct! +15 XP',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: LingoColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),
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
          Positioned(top: 0, left: 0, right: 0, child: _StatusBar(widget: this)),
        // Mascot in top-right corner (full-screen mode only).
        if (!widget.embedded)
          Positioned(
            top: 8,
            right: 12,
            child: _MascotCorner(state: _state, lastConfirmed: _lastConfirmed),
          ),
        // Bottom hint (full-screen mode only).
        if (!widget.embedded)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _BottomHint(widget: this),
          ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final _DetectionCameraScreenState widget;
  const _StatusBar({required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = widget.widget.expectedSignId;
    final expectedSign = expected != null ? LessonCatalog.signById(expected) : null;
    final state = widget._state;
    final confirmed = widget._lastConfirmed;

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
              if (expectedSign != null) ...[
                Text(expectedSign.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  expectedSign != null
                      ? 'Sign "${expectedSign.text}"'
                      : 'Communicate — perform a sign',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              if (state.fps > 0)
                Text('${state.fps} fps',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LivePill(state: state),
              const Spacer(),
              if (confirmed != null && confirmed.classification.isRecognized)
                Text(
                  'Detected: ${_textFor(confirmed.classification.signId)} · ${_gradeFor(confirmed.classification.confidence)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: LingoColors.secondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _textFor(String? id) {
    if (id == null) return '—';
    return LessonCatalog.signById(id)?.text ?? id;
  }

  String _gradeFor(double? confidence) {
    final score = confidence ?? 0;
    if (score >= .90) return 'A';
    if (score >= .80) return 'B';
    if (score >= .70) return 'C';
    if (score >= .60) return 'D';
    return 'F';
  }
}

class _LivePill extends StatelessWidget {
  final RecognitionState state;
  const _LivePill({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.prediction;
    final hasPrediction = p != null && p.isRecognized;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.hasHand ? Icons.back_hand : Icons.pan_tool_alt_outlined,
            size: 18,
            color: state.hasHand ? LingoColors.primary : Colors.white60,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hasPrediction
                  ? LessonCatalog.signById(p.signId!)?.text ?? p.signId!
                  : state.hasHand
                      ? 'Looking…'
                      : 'No hand detected',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'Hold your hand up and perform the sign',
          style: TextStyle(color: Colors.white70),
        ),
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
      ),
      child: Mascot(size: 48, mood: mood),
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
