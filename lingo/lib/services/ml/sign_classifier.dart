import 'sign_classification.dart';

abstract class SignClassifier {
  /// Classifies a single hand-landmark frame, or a short buffered sequence
  /// of frames, and returns the recognized sign.
  ///
  /// - [frames]: a non-empty list of landmark frames. For static signs a
  ///   single frame is enough; for motion signs the most recent N frames
  ///   should be passed so the classifier can observe movement.
  /// - [supportedSignIds]: optional filter restricting the classes the
  ///   classifier may predict (used in lesson practice mode).
  ///
  /// Implementations must be pure (stateless per call) — any smoothing or
  /// hysteresis should be handled by the caller.
  Future<SignClassification> classify({
    required List<LandmarkFrame> frames,
    Set<String>? supportedSignIds,
  });

  /// The set of sign IDs this classifier can recognize.
  Set<String> get supportedSigns;

  /// Whether the classifier is loaded and ready.
  bool get isReady;

  /// Releases any native model resources.
  Future<void> dispose();
}