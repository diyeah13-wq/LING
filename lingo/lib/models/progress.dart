/// Tracks a learner's practice history and achievements over time.
class Progress {
  /// Total XP earned.
  final int xp;

  /// Current streak in days.
  final int streak;

  /// Total lessons completed.
  final int lessonsCompleted;

  /// Set of sign IDs the learner has successfully demonstrated at least once.
  final Set<String> signsLearned;

  /// Number of correct recognition attempts.
  final int correctAttempts;

  /// Number of incorrect recognition attempts.
  final int incorrectAttempts;

  /// Daily XP earned, keyed by ISO date string (yyyy-MM-dd).
  final Map<String, int> dailyXp;

  /// Ids of unlocked achievements (see AchievementCatalog).
  final Set<String> achievements;

  const Progress({
    this.xp = 0,
    this.streak = 0,
    this.lessonsCompleted = 0,
    this.signsLearned = const {},
    this.correctAttempts = 0,
    this.incorrectAttempts = 0,
    this.dailyXp = const {},
    this.achievements = const {},
  });

  /// Number of unlocked achievements.
  int get achievementsUnlocked => achievements.length;

  double get accuracy {
    final total = correctAttempts + incorrectAttempts;
    if (total == 0) return 0;
    return correctAttempts / total;
  }

  Progress copyWith({
    int? xp,
    int? streak,
    int? lessonsCompleted,
    Set<String>? signsLearned,
    int? correctAttempts,
    int? incorrectAttempts,
    Map<String, int>? dailyXp,
    Set<String>? achievements,
  }) {
    return Progress(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      signsLearned: signsLearned ?? this.signsLearned,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      dailyXp: dailyXp ?? this.dailyXp,
      achievements: achievements ?? this.achievements,
    );
  }

  /// Adds [amount] XP to the total and to today's daily tally.
  Progress addXp(int amount, {required DateTime today}) {
    final todayKey = _isoDate(today);
    final daily = Map<String, int>.from(dailyXp);
    daily[todayKey] = (daily[todayKey] ?? 0) + amount;
    final updated = copyWith(xp: xp + amount, dailyXp: daily);
    return updated.copyWith(streak: updated._computeStreak(today: today));
  }

  /// Records a single attempt (success = true for correct).
  Progress recordAttempt({required bool success}) {
    return copyWith(
      correctAttempts: correctAttempts + (success ? 1 : 0),
      incorrectAttempts: incorrectAttempts + (success ? 0 : 1),
    );
  }

  /// Marks a lesson as completed and refreshes the streak.
  Progress completeLesson({required DateTime today}) {
    final updated = copyWith(lessonsCompleted: lessonsCompleted + 1);
    return updated.copyWith(streak: updated._computeStreak(today: today));
  }

  /// Marks a sign as learned (demonstrated correctly).
  Progress learnSign(String signId) {
    if (signsLearned.contains(signId)) return this;
    final learned = Set<String>.from(signsLearned)..add(signId);
    return copyWith(signsLearned: learned);
  }

  /// Unlocks all the given achievement ids (does nothing if already unlocked).
  Progress unlockAchievements(Iterable<String> ids) {
    final already = Set<String>.from(achievements);
    final hasNew = ids.any((id) => !already.contains(id));
    if (!hasNew) return this;
    final unlocked = Set<String>.from(achievements)..addAll(ids);
    return copyWith(achievements: unlocked);
  }

  /// Counts consecutive days of Xp-earning activity ending today (or yesterday
  /// if today has none yet), capped at a sane maximum.
  int _computeStreak({required DateTime today}) {
    final keys = dailyXp.keys.where((k) => (dailyXp[k] ?? 0) > 0).toSet();
    if (keys.isEmpty) return 0;

    DateTime cursor = today;
    if (!keys.contains(_isoDate(today))) {
      // No activity today yet — allow the streak to survive until the day ends.
      cursor = DateTime(today.year, today.month, today.day - 1);
    }

    var streak = 0;
    var guard = 0;
    while (guard < 366) {
      final key = _isoDate(cursor);
      if (!keys.contains(key) || (dailyXp[key] ?? 0) <= 0) break;
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      guard++;
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streak': streak,
        'lessonsCompleted': lessonsCompleted,
        'signsLearned': signsLearned.toList(),
        'correctAttempts': correctAttempts,
        'incorrectAttempts': incorrectAttempts,
        'dailyXp': dailyXp,
        'achievements': achievements.toList(),
      };

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      signsLearned: (json['signsLearned'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      correctAttempts: json['correctAttempts'] as int? ?? 0,
      incorrectAttempts: json['incorrectAttempts'] as int? ?? 0,
      dailyXp: (json['dailyXp'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}