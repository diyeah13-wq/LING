/// A categorical type describing how a sign is physically performed.
enum SignType {
  /// A sign that holds a static handshape (e.g., "water", "hospital").
  static,

  /// A sign that requires movement (e.g., "hello" - waving, "yes" - nodding).
  motion;

  String get label => name;

  static SignType fromName(String name) =>
      SignType.values.firstWhere((t) => t.name == name, orElse: () => SignType.static);
}

/// A single ASL sign with all metadata needed for teaching and recognition.
class Sign {
  final String id;

  /// The English word or phrase this sign represents (e.g., "hello").
  final String text;

  /// What the sign means, in friendly language.
  final String meaning;

  /// A short explanation of how to perform the sign.
  final String howToPerform;

  /// A tip to help remember the sign (mnemonic).
  final String? tip;

  /// Whether the sign involves movement (vs. static).
  final SignType type;

  /// Icon/emoji representation for UI when video/real demonstration isn't available.
  final String emoji;

  /// The label this sign maps to in the on-device recognition model.
  ///
  /// Defaults to [text] lowercased. Override when the id and label differ
  /// (e.g. id "thank-you" maps to model label "thank you").
  final String? _modelLabelOverride;

  String get modelLabel => _modelLabelOverride ?? text.toLowerCase();

  const Sign({
    required this.id,
    required this.text,
    required this.meaning,
    required this.howToPerform,
    this.tip,
    required this.type,
    required this.emoji,
    String? modelLabel,
  }) : _modelLabelOverride = modelLabel;
}
