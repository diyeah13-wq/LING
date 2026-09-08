import 'dart:math' as math;

/// Feature extraction that mirrors the Python training pipeline exactly.
///
/// Each input frame provides 21 raw landmarks (x,y,z) per sampled frame.
/// We convert each frame to a translation- and scale-invariant representation:
///   - translate so the wrist (landmark 0) is at the origin
///   - scale by palm size = ||wrist - middleMCP(landmark 9)||
///   - keep z relative to wrist
/// Then we append frame-to-frame velocity (deltas).
///
/// Output shape: [N_FRAMES, 21*3*2 = 126] — matches the exported TFLite model.
class SignFeatureExtractor {
  static const int numLandmarks = 21;
  static const int numFrames = 24;
  static const int featuresPerLandmark = 3;
  static const int staticDim = numLandmarks * featuresPerLandmark; // 63
  static const int totalDim = staticDim * 2; // 63 + 63 velocity = 126

  /// Landmark index of the wrist (origin for translation).
  static const int wristIndex = 0;

  /// Landmark index of the middle-finger MCP (used for palm scale).
  static const int palmScaleIndex = 9;

  /// Normalizes a full sequence of raw landmark sets into the model input.
  ///
  /// [seqRaw] is a list where each element is a list of 21 [List<double>]
  /// triples (x, y, z) in image/pixel coordinate space. Any frame whose first
  /// landmark is not present (e.g., all zeros / no hand) stays zero.
  ///
  /// Returns a flat [List<double]> of length [numFrames] * [totalDim].
  static List<double> normalizeSequence(List<List<List<double>>> seqRaw,
      {int targetFrames = numFrames}) {
    // Resample/pad so we always have exactly targetFrames frames.
    final frames = _resample(seqRaw, targetFrames);

    final normalized = List.generate(
        targetFrames, (i) => _normalizeFrame(frames[i], targetFrames));

    // Compute velocity: delta between consecutive frames.
    final velocities = List.generate(targetFrames, (i) {
      if (i == 0) {
        return List<double>.filled(staticDim, 0.0, growable: false);
      }
      final prev = normalized[i - 1];
      final cur = normalized[i];
      return List<double>.generate(
          staticDim, (d) => cur[d] - prev[d],
          growable: false);
    });

    // Concatenate static + velocity per frame => [targetFrames, totalDim].
    final result = <double>[];
    for (int i = 0; i < targetFrames; i++) {
      result.addAll(normalized[i]);
      result.addAll(velocities[i]);
    }
    return result;
  }

  static List<List<List<double>>> _resample(
      List<List<List<double>>> seq, int targetFrames) {
    if (seq.isEmpty) {
      return _emptyFrames(targetFrames);
    }
    if (seq.length == targetFrames) {
      return seq;
    }
    final out = <List<List<double>>>[];
    if (seq.length > targetFrames) {
      // Uniform subsample.
      for (int i = 0; i < targetFrames; i++) {
        final idx = (i * seq.length / targetFrames).floor().clamp(0, seq.length - 1);
        out.add(seq[idx]);
      }
    } else {
      // Repeat last frame to pad to target length.
      out.addAll(seq);
      while (out.length < targetFrames) {
        out.add(seq.last);
      }
    }
    return out;
  }

  static List<List<List<double>>> _emptyFrames(int n) {
    return List.generate(
        n, (_) => List.generate(numLandmarks, (_) => [0.0, 0.0, 0.0]),
        growable: false);
  }

  static List<double> _normalizeFrame(List<List<double>> frame, int targetFrames) {
    final out = List<double>.filled(staticDim, 0.0);
    if (frame.length < numLandmarks) return out;
    if (frame[wristIndex][0] == 0.0 &&
        frame[wristIndex][1] == 0.0 &&
        frame[wristIndex][2] == 0.0) {
      return out;
    }

    final wx = frame[wristIndex][0];
    final wy = frame[wristIndex][1];
    final wz = frame[wristIndex][2];

    final mx = frame[palmScaleIndex][0];
    final my = frame[palmScaleIndex][1];
    final mz = frame[palmScaleIndex][2];

    final scale = _distance(wx, wy, wz, mx, my, mz);
    if (scale < 1e-6) return out;

    for (int i = 0; i < numLandmarks; i++) {
      final x = (frame[i][0] - wx) / scale;
      final y = (frame[i][1] - wy) / scale;
      final z = (frame[i][2] - wz) / scale;
      out[i * 3] = x;
      out[i * 3 + 1] = y;
      out[i * 3 + 2] = z;
    }
    return out;
  }

  static double _distance(double x1, double y1, double z1,
      double x2, double y2, double z2) {
    final dx = x1 - x2, dy = y1 - y2, dz = (z1 - z2);
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}