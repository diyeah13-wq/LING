import '../models/achievement.dart';

/// The full set of achievements a learner can unlock.
class AchievementCatalog {
  AchievementCatalog._();

  static const List<Achievement> all = [
    Achievement(
      id: 'first-lesson',
      title: 'Hello, friend',
      description: 'Complete your first lesson',
      emoji: '👋',
      requiresLessons: 1,
    ),
    Achievement(
      id: 'first-sign',
      title: 'First signs',
      description: 'Demonstrate your first sign correctly',
      emoji: '🤟',
      requiresSignId: 'hello',
    ),
    Achievement(
      id: 'xp-100',
      title: 'Century',
      description: 'Earn 100 XP',
      emoji: '💯',
      requiresXp: 100,
    ),
    Achievement(
      id: 'streak-3',
      title: 'On a roll',
      description: 'Keep a 3-day streak',
      emoji: '🔥',
      requiresStreak: 3,
    ),
    Achievement(
      id: 'signs-10',
      title: 'Almost fluent',
      description: 'Learn 10 signs',
      emoji: '🏅',
      requiresSignsLearned: 10,
    ),
    Achievement(
      id: 'all-signs',
      title: 'Vocabulary champion',
      description: 'Learn all 12 signs in the app',
      emoji: '🏆',
      requiresSignsLearned: 12,
    ),
  ];

  /// Looks up an achievement by id, or null if not found.
  static Achievement? byId(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }
}