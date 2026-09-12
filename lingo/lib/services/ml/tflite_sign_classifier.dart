import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';

import '../../data/model_vocabulary.dart';
import 'sign_classification.dart';
import 'sign_classifier.dart';
import 'sign_feature_extractor.dart';

/// A pre-trained, on-device TFLite GRU classifier for the LINGO sign vocabulary.
///
/// Replaces any prototype/rule-based classifier. It consumes landmark
/// sequences (see [SignFeatureExtractor]) and outputs per-class probabilities
/// for the 13 supported signs.
class TfliteSignClassifier implements SignClassifier {
  final String _assetPath;
  Interpreter? _interpreter;
  List<String>? _labels;

  TfliteSignClassifier({this._assetPath = 'assets/models/lingo_sign_model.tflite'});

  @override
  bool isReady = false;

  @override
  Future<void> load() async {
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    _interpreter = await Interpreter.fromBytes(bytes);
    isReady = true;
  }

  int get _numClasses => _labels?.length ?? 0;

  /// Sets the class labels in the order the model was trained with.
  void setLabels(List<String> labels) {
    _labels = List.unmodifiable(labels);
    _signIds = List.unmodifiable(
      labels.map(ModelVocabulary.signIdForLabel),
    );
  }

  List<String>? _signIds;

  String? _signIdForIndex(int i) =>
      (i >= 0 && i < (_signIds?.length ?? 0)) ? _signIds![i] : null;

  @override
  Set<String> get supportedSigns => _labels?.toSet() ?? const {};

  @override
  Future<SignClassification> classify({
    required List<LandmarkFrame> frames,
    Set<String>? supportedSignIds,
  }) async {
    if (!isReady || _interpreter == null || _labels == null) {
      return const SignClassification(description: 'Model not ready');
    }

    // Convert LandmarkFrame list into the raw nested landmark sequence, then
    // normalize into the model input [24, 126].
    final rawSeq = <List<List<double>>>[];
    for (final f in frames) {
      final frame = <List<double>>[];
      for (int i = 0; i < 21; i++) {
        frame.add([f.x(i), f.y(i), f.z(i)]);
      }
      rawSeq.add(frame);
    }
    final input = SignFeatureExtractor.normalizeSequence(rawSeq);

    final inputTensor = Float32List.fromList(input);

    // Reshape to [1, 24, 126].
    final output = Float32List(_numClasses);
    try {
      _interpreter!.run(
        inputTensor,
        output,
      );
    } catch (e) {
      return SignClassification(description: 'Inference error: $e');
    }

    // Determine predicted class.
    int best = 0;
    double bestConf = -1;
    for (int i = 0; i < output.length; i++) {
      if (output[i] > bestConf) {
        bestConf = output[i];
        best = i;
      }
    }

    if (best < 0 || best >= _labels!.length) {
      return const SignClassification(description: 'No prediction');
    }
    final predictedSignId = _signIdForIndex(best) ?? _labels![best];

    // Optional filtering to a restricted set of allowed signs.
    if (supportedSignIds != null && !supportedSignIds.contains(predictedSignId)) {
      // Find the best prediction among allowed classes.
      double maxAllowedConf = -1;
      int bestAllowed = -1;
      for (int i = 0; i < _labels!.length; i++) {
        final signId = _signIdForIndex(i);
        if (signId != null &&
            supportedSignIds.contains(signId) &&
            output[i] > maxAllowedConf) {
          maxAllowedConf = output[i];
          bestAllowed = i;
        }
      }
      if (bestAllowed >= 0) {
        return SignClassification(
          signId: _signIdForIndex(bestAllowed),
          confidence: maxAllowedConf,
        );
      }
      return const SignClassification(description: 'No supported sign');
    }

    return SignClassification(
      signId: predictedSignId,
      confidence: bestConf.clamp(0.0, 1.0),
      description: 'Predicted "$predictedSignId"',
    );
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    isReady = false;
  }
}