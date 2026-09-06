/// App-wide constants.
class AppConstants {
  AppConstants._();

  // App metadata
  static const String appName = 'LINGO';
  static const String tagline = 'Learn ASL. Sign your world.';

  // Gamification
  static const int xpPerCorrectSign = 20;
  static const int xpPerIncorrectSign = 5;
  static const int xpPerLessonCompletion = 50;
  static const int xpStreakBonus = 10;

  // Camera / ML
  static const int handTrackingFrameInterval = 3;
  static const double recognitionConfidenceThreshold = 0.6;
  static const Duration recognitionHysteresis = Duration(milliseconds: 600);
  static const int maxHands = 1;

  // Recognition pipeline
  static const int landmarkFrameBufferSize = 24;
  static const int predictionEveryFrames = 4;
}

/// Simple XP -> level mapping. A new level requires every 100 XP.
class XpLevels {
  XpLevels._();

  static const int xpPerLevel = 100;

  static int levelForXp(int xp) => xp ~/ xpPerLevel + 1;

  /// XP earned within the current level (0..xpPerLevel).
  static int xpIntoLevel(int xp) => xp % xpPerLevel;

  /// XP needed to reach the next level.
  static int xpToNextLevel(int xp) => xpPerLevel - xpIntoLevel(xp);
}