import '../models/sign.dart';

/// The ordered vocabulary the on-device recognition model supports.
///
/// This is the single source of truth for:
///   * the TFLite model's output labels (`assets/ml/labels.txt`)
///   * which signs can be camera-practiced
///   * the limited Communicator vocabulary
///
/// The order MUST match `labels.txt` produced by the training pipeline in
/// `ml/` so that output index -> sign mapping stays correct.
class ModelVocabulary {
  ModelVocabulary._();

  static const List<String> labels = [
    'hello',
    'thank you',
    'please',
    'sorry',
    'yes',
    'no',
    'help',
    'where',
    'water',
    'food',
    'doctor',
    'hospital',
  ];

  /// Maps a model label to its canonical sign id in the lesson catalog.
  static String signIdForLabel(String label) => label;

  /// Maps a canonical sign id (from [Sign.id]) to its model label.
  static String labelForSignId(String signId) =>
      signId == 'thank-you' ? 'thank you' : signId;

  /// Whether a sign is supported by the recognition model.
  static bool isModelSupported(String signId) =>
      labels.contains(labelForSignId(signId));

  /// Human-readable phrase used in glanceable UI chips.
  static String displayLabel(String label) => label;
}