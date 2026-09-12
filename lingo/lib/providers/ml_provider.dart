import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model_vocabulary.dart';
import '../services/ml/sign_classifier.dart';
import '../services/ml/tflite_sign_classifier.dart';

/// A single shared, lazy-loaded classifier instance app-wide.
///
/// The model was trained with a fixed class order; labels are taken from
/// [ModelVocabulary.labels] so index -> sign mapping stays aligned with the
/// rest of the app.
final signClassifierProvider = Provider<SignClassifier>((ref) {
  final classifier = TfliteSignClassifier()
    ..setLabels(ModelVocabulary.labels);
  ref.onDispose(classifier.dispose);
  return classifier;
});

/// Future that resolves once the classifier is loaded & ready.
final signClassifierReadyProvider = FutureProvider<bool>((ref) async {
  final classifier = ref.watch(signClassifierProvider);
  if (!classifier.isReady) {
    await classifier.load();
  }
  return classifier.isReady;
});