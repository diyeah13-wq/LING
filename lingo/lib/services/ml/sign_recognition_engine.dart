import 'dart:async';
import 'dart:collection';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

import 'sign_classification.dart';
import 'sign_classifier.dart';

/// Live state of the recognition pipeline, exposed to the UI each frame.
class RecognitionState {
  /// Hands detected in the most recent frame (for overlay rendering).
  final List<Hand> hands;

  /// Post-rotation, post-downscale size of the detection image. Use as the
  /// source size when mapping [hands] coordinates onto the preview widget.
  final Size imageSize;

  /// Whether at least one hand was detected in this frame.
  bool get hasHand => hands.isNotEmpty;

  /// The most recent classifier prediction (may be below the confirm
  /// threshold).
  final SignClassification? prediction;

  /// Detection pipeline frames-per-second (informational).
  final int fps;

  const RecognitionState({
    this.hands = const [],
    this.imageSize = Size.zero,
    this.prediction,
    this.fps = 0,
  });
}

/// A sign recognition that has cleared the confirmation criteria
/// (confidence threshold + hysteresis).
class ConfirmedSign {
  final SignClassification classification;
  const ConfirmedSign(this.classification);
}

/// Drives the live recognition pipeline:
///
///  1. Feeds each camera frame to the [HandDetector].
///  2. Converts the first detected hand's 21 landmarks into a
///     [LandmarkFrame] and pushes it onto a sliding window (matches the
///     training window of 24 frames).
///  3. On a fixed cadence the [SignClassifier] runs over the buffered window;
///     confidence threshold + hysteresis produce stable confirmations.
class SignRecognitionEngine {
  final HandDetector _detector;
  final SignClassifier _classifier;
  final Set<String>? supportedSignIds;
  final int _windowFrames;

  static const int _windowTarget = 24; // matches training
  static const double _confirmThreshold = 0.55;
  static const int _hysteresisHits = 3;
  static const int _maxDetectDim = 640;

  /// Classifier is re-run at most every [classifyInterval] while a hand is
  /// present.
  final Duration classifyInterval;

  final ListQueue<LandmarkFrame> _window = ListQueue();
  final List<SignClassification> _recent = [];
  int _framesPending = 0;

  List<Hand> _lastHands = const [];
  Size _lastImageSize = Size.zero;
  SignClassification? _lastPrediction;
  bool _disposed = false;

  int _fpsFrames = 0;
  DateTime? _fpsBase;
  int _fps = 0;

  final _stateController = StreamController<RecognitionState>.broadcast();
  final _confirmedController = StreamController<ConfirmedSign>.broadcast();

  /// Creates the engine with an already-initialized [detector] and
  /// [classifier]. [supportedSignIds] restricts predictions to a subset of
  /// sign ids when set.
  SignRecognitionEngine({
    required this._detector,
    required this._classifier,
    this.supportedSignIds,
    this.classifyInterval = const Duration(milliseconds: 120),
    int? windowFrames,
  }) : _windowFrames = windowFrames ?? _windowTarget;

  /// Live [RecognitionState] updates (once per processed frame).
  Stream<RecognitionState> get states => _stateController.stream;

  /// Sign confirmations (stable, thresholded recognitions).
  Stream<ConfirmedSign> get confirmations => _confirmedController.stream;

  /// Processes one camera frame. Safe to call from the camera image stream;
  /// detection runs in the hand_detection isolate.
  Future<void> processCameraFrame(
    CameraImage image, {
    required CameraFrameRotation rotation,
  }) async {
    if (_disposed) return;

    List<Hand> hands;
    try {
      hands = await _detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: _maxDetectDim,
      );
    } catch (_) {
      hands = const [];
    }

    _lastHands = hands;
    _lastImageSize = detectionSize(
      width: image.width,
      height: image.height,
      rotation: rotation,
      maxDim: _maxDetectDim,
    );
    _tickFps();

    if (hands.isNotEmpty) {
      final best = hands.firstWhere(
        (h) => h.hasLandmarks,
        orElse: () => hands.first,
      );
      if (best.hasLandmarks) {
        _pushLandmarks(best);
      }
    } else if (_window.isNotEmpty && _window.length >= _windowFrames) {
      // Hand left frame: run one final classification so UI can clear.
      await _classify();
    }

    _emit();
  }

  void _pushLandmarks(Hand hand) {
    if (hand.landmarks.length < 21) return;
    final flattened = <double>[];
    for (final lm in hand.landmarks) {
      flattened.add(lm.x);
      flattened.add(lm.y);
      flattened.add(lm.z);
    }
    _window.add(LandmarkFrame.fromRaw(flattened));
    while (_window.length > _windowFrames) {
      _window.removeFirst();
    }

    _framesPending++;
    final framesPerClassify =
        (classifyInterval.inMilliseconds ~/ 33).clamp(1, 8);
    if (_framesPending >= framesPerClassify || _window.length >= _windowFrames) {
      _framesPending = 0;
      unawaited(_classify());
    }
  }

  Future<void> _classify() async {
    if (_disposed || _window.isEmpty) return;
    final frames = _window.toList();
    try {
      final result = await _classifier.classify(
        frames: frames,
        supportedSignIds: supportedSignIds,
      );
      if (_disposed) return;

      _lastPrediction = result;

      if (!result.isRecognized ||
          (result.confidence ?? 0) < _confirmThreshold) {
        _recent.clear();
      } else {
        _recent.add(result);
        if (_recent.length > _hysteresisHits) {
          _recent.removeAt(0);
        }
        if (_recent.length >= _hysteresisHits &&
            _recent.every((p) => p.signId == result.signId)) {
          _confirmedController.add(ConfirmedSign(result));
          _recent.clear();
        }
      }
    } catch (_) {
      _lastPrediction = null;
      _recent.clear();
    }
    _emit();
  }

  void _tickFps() {
    _fpsFrames++;
    final now = DateTime.now();
    final base = _fpsBase ?? now;
    if (base == now) return;
    final elapsed = now.difference(base).inMilliseconds;
    if (elapsed >= 1000) {
      _fps = (_fpsFrames * 1000 / elapsed).round();
      _fpsFrames = 0;
      _fpsBase = now;
    }
  }

  void _emit() {
    if (_disposed) return;
    if (_stateController.hasListener) {
      _stateController.add(RecognitionState(
        hands: _lastHands,
        imageSize: _lastImageSize,
        prediction: _lastPrediction,
        fps: _fps,
      ));
    }
  }

  /// Clears buffered landmarks and recent predictions (e.g. between signs).
  void reset() {
    _window.clear();
    _recent.clear();
    _framesPending = 0;
    _lastPrediction = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _detector.dispose();
    await _classifier.dispose();
    await _stateController.close();
    await _confirmedController.close();
  }
}

/// Computes the rotation that presents a camera frame upright to the
/// detection model. Pass the result to
/// `SignRecognitionEngine.processCameraFrame`.
CameraFrameRotation? rotationForCamera({
  required CameraController controller,
  required CameraImage image,
}) {
  return rotationForFrame(
    width: image.width,
    height: image.height,
    sensorOrientation: controller.description.sensorOrientation,
    isFrontCamera:
        controller.description.lensDirection == CameraLensDirection.front,
    deviceOrientation: controller.value.deviceOrientation,
  );
}