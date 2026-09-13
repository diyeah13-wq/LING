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

  /// Bundled reference image used in the lesson screen, when available.
  final String? referenceImageAsset;

  String? get resolvedReferenceImageAsset =>
      referenceImageAsset ?? _wordReferenceImages[id];

  /// Bundled reference video clip used for real-life demonstration.
  final String? referenceVideoAsset;

  String? get resolvedReferenceVideoAsset =>
      referenceVideoAsset ?? _wordReferenceVideos[id];

  bool get hasVideoReference => resolvedReferenceVideoAsset != null;

  static const _wordReferenceImages = <String, String>{
    'hello': 'assets/references/words/hello.jpg',
    'thank-you': 'assets/references/words/thank-you.jpg',
    'please': 'assets/references/words/please.jpg',
    'sorry': 'assets/references/words/sorry.jpg',
    'goodbye': 'assets/references/words/goodbye.jpg',
    'yes': 'assets/references/words/yes.jpg',
    'no': 'assets/references/words/no.jpg',
    'help': 'assets/references/words/help.jpg',
    'where': 'assets/references/words/where.jpg',
    'water': 'assets/references/words/water.jpg',
    'food': 'assets/references/words/food.jpg',
    'doctor': 'assets/references/words/doctor.jpg',
    'hospital': 'assets/references/words/hospital.jpg',
  };

  static const _wordReferenceVideos = <String, String>{
    'hello': 'assets/references/videos/hello.mp4',
    'thank-you': 'assets/references/videos/thank-you.mp4',
    'please': 'assets/references/videos/please.mp4',
    'sorry': 'assets/references/videos/sorry.mp4',
    'goodbye': 'assets/references/videos/goodbye.mp4',
    'yes': 'assets/references/videos/yes.mp4',
    'no': 'assets/references/videos/no.mp4',
    'help': 'assets/references/videos/help.mp4',
    'where': 'assets/references/videos/where.mp4',
    'water': 'assets/references/videos/water.mp4',
    'food': 'assets/references/videos/food.mp4',
    'doctor': 'assets/references/videos/doctor.mp4',
    'hospital': 'assets/references/videos/hospital.mp4',
  };

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
    this.referenceImageAsset,
    this.referenceVideoAsset,
    String? modelLabel,
  }) : _modelLabelOverride = modelLabel;
}
