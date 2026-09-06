class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;

  /// If non-null, the achievement is earned when this sign is learned.
  final String? requiresSignId;

  /// If non-null, the achievement is earned when this many lessons are completed.
  final int? requiresLessons;

  /// If non-null, the achievement is earned when this many XP points are reached.
  final int? requiresXp;

  /// If non-null, the achievement is earned when this many days of streak are reached.
  final int? requiresStreak;

  /// If non-null, the achievement is earned when this many signs are learned.
  final int? requiresSignsLearned;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.requiresSignId,
    this.requiresLessons,
    this.requiresXp,
    this.requiresStreak,
    this.requiresSignsLearned,
  });

  /// Returns true if the given progress satisfies this achievement's condition.
  bool isEarned({
    required Set<String> learnedSigns,
    required int lessonsCompleted,
    required int xp,
    required int streak,
  }) {
    if (requiresSignId != null && !learnedSigns.contains(requiresSignId)) {
      return false;
    }
    if (requiresLessons != null && lessonsCompleted < requiresLessons!) {
      return false;
    }
    if (requiresXp != null && xp < requiresXp!) {
      return false;
    }
    if (requiresStreak != null && streak < requiresStreak!) {
      return false;
    }
    if (requiresSignsLearned != null &&
        learnedSigns.length < requiresSignsLearned!) {
      return false;
    }
    return true;
  }
}