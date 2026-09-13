import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements_catalog.dart';
import '../data/lesson_catalog.dart';
import '../models/achievement.dart';
import '../models/learner_profile.dart';
import '../models/learner_state.dart';
import '../models/learning_goal.dart';
import '../models/progress.dart';
import '../models/skill_level.dart';
import '../services/storage_service.dart';

/// Provider for the local storage service (asynchronous initialization).
final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.open();
});

/// Holds the in-memory learner state and persists changes.
class LearnerStateNotifier extends StateNotifier<LearnerState> {
  final Ref ref;

  LearnerStateNotifier(this.ref) : super(const LearnerState()) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final storage = await ref.read(storageServiceProvider.future);
    state = storage.loadLearnerState();
  }

  Future<void> _persist() async {
    final storage = await ref.read(storageServiceProvider.future);
    await storage.saveLearnerState(state);
  }

  Future<void> setProfile({
    required String name,
    required LearningGoal goal,
    required SkillLevel level,
  }) async {
    state = state.copyWith(
      profile: LearnerProfile(name: name, goal: goal, level: level),
    );
    await _persist();
  }

  Future<void> addXp(int amount) async {
    state = state.copyWith(
      progress: state.progress.addXp(amount, today: DateTime.now()),
    );
    await _unlockNewAchievements();
    await _persist();
  }

  Future<void> recordAttempt({required bool success}) async {
    state = state.copyWith(
      progress: state.progress.recordAttempt(success: success),
    );
    await _persist();
  }

  Future<void> completeLesson() async {
    state = state.copyWith(
      progress: _recomputeLessonsCompleted(state.progress),
    );
    await _unlockNewAchievements();
    await _persist();
  }

  Future<void> learnSign(String signId) async {
    state = state.copyWith(
      progress: _recomputeLessonsCompleted(state.progress.learnSign(signId)),
    );
    await _unlockNewAchievements();
    await _persist();
  }

  /// Reconciles `lessonsCompleted` with the catalog: a lesson counts once
  /// every one of its signs has been demonstrated. This keeps the counter
  /// accurate regardless of how the signs were practiced (single-sign camera,
  /// full lesson session, etc.) and avoids double counting.
  Progress _recomputeLessonsCompleted(Progress progress) {
    final completed = LessonCatalog.lessons
        .where((lesson) =>
            lesson.signs.every((s) => progress.signsLearned.contains(s.id)))
        .length;
    if (completed == progress.lessonsCompleted) return progress;
    return progress.copyWith(lessonsCompleted: completed);
  }

  /// Unlocks any achievements whose conditions the current progress satisfies.
  Future<void> _unlockNewAchievements() async {
    final progress = state.progress;
    final earned = AchievementCatalog.all
        .where((a) => a.isEarned(
          learnedSigns: progress.signsLearned,
          lessonsCompleted: progress.lessonsCompleted,
          xp: progress.xp,
          streak: progress.streak,
        ))
        .map((a) => a.id)
        .toList();
    final updated = progress.unlockAchievements(earned);
    if (!identical(updated, progress) && updated.achievements != progress.achievements) {
      state = state.copyWith(progress: updated);
    }
  }

  Future<void> reset() async {
    state = const LearnerState();
    final storage = await ref.read(storageServiceProvider.future);
    await storage.clear();
  }
}

/// Provider exposing the current learner state.
final learnerStateProvider =
    StateNotifierProvider<LearnerStateNotifier, LearnerState>((ref) {
  return LearnerStateNotifier(ref);
});

/// Convenience provider for the current progress.
final progressProvider = Provider<Progress>((ref) {
  return ref.watch(learnerStateProvider).progress;
});

/// The achievements the learner has unlocked so far (met conditions).
final earnedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final progress = ref.watch(progressProvider);
  return AchievementCatalog.all
      .where((a) => a.isEarned(
        learnedSigns: progress.signsLearned,
        lessonsCompleted: progress.lessonsCompleted,
        xp: progress.xp,
        streak: progress.streak,
      ))
      .toList();
});