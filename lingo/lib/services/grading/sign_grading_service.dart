import 'package:flutter/material.dart';

import '../../data/lesson_catalog.dart';
import '../../models/sign.dart';

/// Performance letter grades for sign language evaluation.
enum SignGrade {
  aPlus(
    letter: 'A+',
    label: 'Mastery!',
    minConfidence: 0.86,
    color: Color(0xFF10B981), // Emerald
    xp: 25,
    isPassing: true,
  ),
  a(
    letter: 'A',
    label: 'Great Form!',
    minConfidence: 0.74,
    color: Color(0xFF059669),
    xp: 20,
    isPassing: true,
  ),
  b(
    letter: 'B',
    label: 'Good Attempt!',
    minConfidence: 0.63,
    color: Color(0xFF3B82F6), // Blue
    xp: 15,
    isPassing: true,
  ),
  c(
    letter: 'C',
    label: 'Fair Effort',
    minConfidence: 0.50,
    color: Color(0xFFF59E0B), // Amber
    xp: 10,
    isPassing: true,
  ),
  d(
    letter: 'D',
    label: 'Needs Work',
    minConfidence: 0.40,
    color: Color(0xFFF97316), // Orange
    xp: 5,
    isPassing: false,
  ),
  f(
    letter: 'F',
    label: 'Try Again',
    minConfidence: 0.0,
    color: Color(0xFFEF4444), // Red
    xp: 0,
    isPassing: false,
  );

  final String letter;
  final String label;
  final double minConfidence;
  final Color color;
  final int xp;
  final bool isPassing;

  const SignGrade({
    required this.letter,
    required this.label,
    required this.minConfidence,
    required this.color,
    required this.xp,
    required this.isPassing,
  });

  static SignGrade forConfidence(double confidence, {bool isMatch = true}) {
    if (!isMatch) return SignGrade.f;
    if (confidence >= 0.86) return SignGrade.aPlus;
    if (confidence >= 0.74) return SignGrade.a;
    if (confidence >= 0.63) return SignGrade.b;
    if (confidence >= 0.50) return SignGrade.c;
    if (confidence >= 0.40) return SignGrade.d;
    return SignGrade.f;
  }
}

/// Evaluation result for a single sign attempt.
class SignEvaluationResult {
  final Sign targetSign;
  final String? detectedSignId;
  final double confidence;
  final SignGrade grade;
  final String feedback;
  final bool isMatch;
  final int xpEarned;

  int get accuracyPercentage => (confidence * 100).round().clamp(0, 100);

  const SignEvaluationResult({
    required this.targetSign,
    required this.detectedSignId,
    required this.confidence,
    required this.grade,
    required this.feedback,
    required this.isMatch,
    required this.xpEarned,
  });
}

/// Evaluation summary for a multi-sign practice session.
class SessionEvaluationSummary {
  final String lessonTitle;
  final int totalSigns;
  final int correctSigns;
  final int totalAttempts;
  final double averageConfidence;
  final int totalXpEarned;
  final SignGrade overallGrade;

  double get accuracy => totalAttempts == 0 ? 0.0 : correctSigns / totalAttempts;
  int get accuracyPercentage => (accuracy * 100).round().clamp(0, 100);

  const SessionEvaluationSummary({
    required this.lessonTitle,
    required this.totalSigns,
    required this.correctSigns,
    required this.totalAttempts,
    required this.averageConfidence,
    required this.totalXpEarned,
    required this.overallGrade,
  });
}

/// Logic and diagnostic generator for grading ASL sign attempts.
class SignGradingService {
  SignGradingService._();

  /// Evaluates an attempt against the target sign.
  static SignEvaluationResult evaluate({
    required Sign targetSign,
    required String? detectedSignId,
    required double? confidence,
  }) {
    final conf = (confidence ?? 0.0).clamp(0.0, 1.0);
    final isMatch = detectedSignId != null && detectedSignId == targetSign.id;
    final grade = SignGrade.forConfidence(conf, isMatch: isMatch);

    final feedback = _generateFeedback(
      targetSign: targetSign,
      detectedSignId: detectedSignId,
      confidence: conf,
      grade: grade,
      isMatch: isMatch,
    );

    return SignEvaluationResult(
      targetSign: targetSign,
      detectedSignId: detectedSignId,
      confidence: conf,
      grade: grade,
      feedback: feedback,
      isMatch: isMatch,
      xpEarned: grade.xp,
    );
  }

  /// Computes overall evaluation summary for a multi-sign session.
  static SessionEvaluationSummary evaluateSession({
    required String lessonTitle,
    required int totalSigns,
    required int correctSigns,
    required int totalAttempts,
    required List<double> confidences,
    required int baseXp,
  }) {
    final avgConf = confidences.isEmpty
        ? 0.0
        : confidences.reduce((a, b) => a + b) / confidences.length;

    final firstTryAccuracy =
        totalAttempts == 0 ? 0.0 : correctSigns / totalAttempts;

    SignGrade grade;
    if (firstTryAccuracy >= 0.85 && avgConf >= 0.80) {
      grade = SignGrade.aPlus;
    } else if (firstTryAccuracy >= 0.75) {
      grade = SignGrade.a;
    } else if (firstTryAccuracy >= 0.60) {
      grade = SignGrade.b;
    } else if (firstTryAccuracy >= 0.45) {
      grade = SignGrade.c;
    } else {
      grade = SignGrade.d;
    }

    final totalXp = baseXp + (grade.xp * totalSigns ~/ 2);

    return SessionEvaluationSummary(
      lessonTitle: lessonTitle,
      totalSigns: totalSigns,
      correctSigns: correctSigns,
      totalAttempts: totalAttempts,
      averageConfidence: avgConf,
      totalXpEarned: totalXp,
      overallGrade: grade,
    );
  }

  static String _generateFeedback({
    required Sign targetSign,
    required String? detectedSignId,
    required double confidence,
    required SignGrade grade,
    required bool isMatch,
  }) {
    if (!isMatch) {
      if (detectedSignId != null) {
        final detectedName =
            LessonCatalog.signById(detectedSignId)?.text ?? detectedSignId;
        return 'Detected "$detectedName" instead of "${targetSign.text}". '
            'Check the reference video and try again!';
      }
      return 'Hand shape was not recognized as "${targetSign.text}". '
          'Hold your hand steady and keep it inside the camera frame.';
    }

    switch (grade) {
      case SignGrade.aPlus:
        return 'Exceptional form! Your hand shape and motion matched "${targetSign.text}" with high precision.';
      case SignGrade.a:
        return 'Excellent signing! Clear posture and accurate hand orientation for "${targetSign.text}".';
      case SignGrade.b:
        return 'Good execution! For an even higher score, keep your wrist steady and make movements deliberate.';
      case SignGrade.c:
        return 'Passed, but with slight variance. Make sure your fingers and palm orientation match the demonstration video.';
      case SignGrade.d:
        return 'Marginal detection. Try checking the slow-motion reference video to review the exact finger configuration.';
      case SignGrade.f:
        return 'Hand motion was unclear. Review the reference demonstration and give it another try!';
    }
  }
}
