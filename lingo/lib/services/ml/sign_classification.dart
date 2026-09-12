/// Result of a single sign recognition attempt.
class SignClassification {
  /// The recognized sign ID (e.g., "hello"). Null if no sign was recognized.
  final String? signId;

  /// Confidence score in [0, 1]. Null if no sign was recognized.
  final double? confidence;

  /// Human-readable description of what was detected.
  final String description;

  const SignClassification({
    this.signId,
    this.confidence,
    this.description = '',
  });

  bool get isRecognized => signId != null;
}

/// A single frame of hand-landmark input for the classifier.
///
/// Landmarks are (x, y, z) normalized coordinates for each of the 21
/// MediaPipe hand landmarks, in the order defined by
/// `HandLandmarkType` (wrist, thumb, index, ...).
class LandmarkFrame {
  final List<double> flattened;

  static const int landmarkDimension = 21 * 3;

  const LandmarkFrame({required this.flattened});

  factory LandmarkFrame.fromRaw(List<double> raw) {
    assert(raw.length == landmarkDimension,
        'Expected 63 values (21x3), got ${raw.length}');
    return LandmarkFrame(flattened: List.unmodifiable(raw));
  }

  double x(int landmarkIndex) => flattened[landmarkIndex * 3];
  double y(int landmarkIndex) => flattened[landmarkIndex * 3 + 1];
  double z(int landmarkIndex) => flattened[landmarkIndex * 3 + 2];
}

/// Definition of a recognition result after a sign gesture is performed.
class RecognitionOutput {
  final SignClassification classification;
  final bool matchedExpected;
  final double confidence;

  const RecognitionOutput({
    required this.classification,
    required this.matchedExpected,
    required this.confidence,
  });
}