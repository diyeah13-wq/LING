import '../models/sign.dart';

/// The ordered vocabulary the on-device recognition model supports.
///
/// This is the single source of truth for:
///   * the TFLite model's output labels (`class_map.json` produced by the
///     training pipeline in `ml_work/`)
///   * which signs can be camera-practiced
///   * the limited Communicator vocabulary
///
/// The order MUST match the class map used to train the exported TFLite model
/// so that output index -> sign mapping stays correct.
class ModelVocabulary {
  ModelVocabulary._();

  /// Static alphabet and number labels in the exported model's order.
  static const List<String> staticLabels = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  ];

  /// Sign-agnostic model labels in the exact training order (13 classes).
  static const List<String> labels = [
    'hello',
    'thank you',
    'please',
    'sorry',
    'goodbye',
    'yes',
    'no',
    'help',
    'water',
    'food',
    'doctor',
    'hospital',
    'where',
  ];

  /// Maps a model label to its canonical sign id in the lesson catalog.
  static String signIdForLabel(String label) =>
      label == 'thank you' ? 'thank-you' : label;

  /// Maps a canonical sign id (from [Sign.id]) to its model label.
  static String labelForSignId(String signId) =>
      signId == 'thank-you' ? 'thank you' : signId;

  /// Whether a sign is supported by the recognition model.
  static bool isModelSupported(String signId) =>
      labels.contains(labelForSignId(signId));

  /// Human-readable phrase used in glanceable UI chips.
  static String displayLabel(String label) => label;
}