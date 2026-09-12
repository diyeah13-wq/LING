import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lesson_catalog.dart';
import '../data/model_vocabulary.dart';
import '../models/lesson.dart';
import '../models/sign.dart';
import 'learner_provider.dart';

/// All lessons in the catalog.
final lessonsProvider = Provider<List<Lesson>>((ref) => LessonCatalog.lessons);

/// The ordered labels of the on-device recognition model.
final modelLabelsProvider =
    Provider<List<String>>((ref) => ModelVocabulary.labels);

/// Sign IDs that the recognition model supports (camera-practicable).
final modelSupportedSignIdsProvider = Provider<Set<String>>((ref) {
  final supported = LessonCatalog.allSigns
      .where((s) => ModelVocabulary.isModelSupported(s.id))
      .map((s) => s.id);
  return supported.toSet();
});

/// A single lesson by id.
final lessonProvider = Provider.family<Lesson?, String>((ref, id) {
  return LessonCatalog.lessonById(id);
});

/// A single sign by id.
final signProvider = Provider.family<Sign?, String>((ref, id) {
  return LessonCatalog.signById(id);
});

/// The full supported vocabulary (lowercase words).
final supportedVocabularyProvider = Provider<Set<String>>((ref) {
  return LessonCatalog.supportedVocabulary;
});

/// Whether a lesson's all signs have been demonstrated correctly at least once.
class LessonCompletionNotifier extends StateNotifier<Map<String, bool>> {
  final Ref ref;

  LessonCompletionNotifier(this.ref) : super({}) {
    _recompute();
    ref.listen(learnerStateProvider, (_, next) => _recompute());
  }

  void _recompute() {
    final learned = ref.read(learnerStateProvider).progress.signsLearned;
    final result = <String, bool>{};
    for (final lesson in LessonCatalog.lessons) {
      result[lesson.id] =
          lesson.signs.every((sign) => learned.contains(sign.id));
    }
    state = result;
  }
}

final lessonCompletionProvider =
    StateNotifierProvider<LessonCompletionNotifier, Map<String, bool>>((ref) {
  return LessonCompletionNotifier(ref);
});

/// Computes how far along the current user has progressed through the sign
/// vocabulary (0.0 to 1.0).
final vocabularyProgressProvider = Provider<double>((ref) {
  final progress = ref.watch(progressProvider);
  final total = LessonCatalog.allSigns.length;
  if (total == 0) return 0;
  return progress.signsLearned.length / total;
});

/// The next sign a user hasn't learned yet, for practice recommendations.
final nextUnlearnedSignProvider = Provider<Sign?>((ref) {
  final learned = ref.read(progressProvider).signsLearned;
  for (final sign in LessonCatalog.allSigns) {
    if (!learned.contains(sign.id)) return sign;
  }
  return null;
});