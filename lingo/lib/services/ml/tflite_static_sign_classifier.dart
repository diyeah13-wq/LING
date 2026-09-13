import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';

import 'sign_classification.dart';
import 'sign_classifier.dart';
import 'sign_feature_extractor.dart';

/// On-device classifier for one-frame ASL alphabet and number handshapes.
class TfliteStaticSignClassifier implements SignClassifier {
  final String _assetPath;
  Interpreter? _interpreter;
  List<String> _labels = const [];

  TfliteStaticSignClassifier({
    this._assetPath = 'assets/models/lingo_static_sign_model.tflite',
  });

  @override
  bool isReady = false;

  @override
  Future<void> load() async {
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    _interpreter = await Interpreter.fromBytes(bytes);
    isReady = true;
  }

  /// Labels must match the exported model's output order.
  void setLabels(List<String> labels) {
    _labels = List.unmodifiable(labels);
  }

  @override
  Set<String> get supportedSigns => _labels.map(_signIdForLabel).toSet();

  String _signIdForLabel(String label) {
    return RegExp(r'^\d$').hasMatch(label) ? 'number-$label' : 'letter-$label';
  }

  @override
  Future<SignClassification> classify({
    required List<LandmarkFrame> frames,
    Set<String>? supportedSignIds,
  }) async {
    if (!isReady || _interpreter == null || _labels.isEmpty || frames.isEmpty) {
      return const SignClassification(description: 'Model not ready');
    }

    final rawFrame = List.generate(
      21,
      (i) => [frames.last.x(i), frames.last.y(i), frames.last.z(i)],
      growable: false,
    );
    final input = Float32List.fromList(
      SignFeatureExtractor.normalizeFrame(rawFrame),
    );
    final output = Float32List(_labels.length);
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      return SignClassification(description: 'Inference error: $e');
    }

    var best = -1;
    var bestConfidence = -1.0;
    for (var i = 0; i < output.length; i++) {
      final signId = _signIdForLabel(_labels[i]);
      if ((supportedSignIds == null || supportedSignIds.contains(signId)) &&
          output[i] > bestConfidence) {
        best = i;
        bestConfidence = output[i];
      }
    }
    if (best < 0) {
      return const SignClassification(description: 'No supported sign');
    }
    return SignClassification(
      signId: _signIdForLabel(_labels[best]),
      confidence: bestConfidence.clamp(0.0, 1.0),
      description: 'Predicted "${_labels[best]}"',
    );
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    isReady = false;
  }
}