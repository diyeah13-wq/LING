import 'package:flutter_test/flutter_test.dart';
import 'package:lingo/data/lesson_catalog.dart';
import 'package:lingo/services/grading/sign_grading_service.dart';

void main() {
  group('SignGradingService tests', () {
    final helloSign = LessonCatalog.signById('hello')!;

    test('High confidence match awards A+ grade and 25 XP', () {
      final result = SignGradingService.evaluate(
        targetSign: helloSign,
        detectedSignId: 'hello',
        confidence: 0.95,
      );

      expect(result.grade, equals(SignGrade.aPlus));
      expect(result.grade.letter, equals('A+'));
      expect(result.isMatch, isTrue);
      expect(result.accuracyPercentage, equals(95));
      expect(result.xpEarned, equals(25));
      expect(result.grade.isPassing, isTrue);
    });

    test('Good confidence match awards B grade', () {
      final result = SignGradingService.evaluate(
        targetSign: helloSign,
        detectedSignId: 'hello',
        confidence: 0.66,
      );

      expect(result.grade, equals(SignGrade.b));
      expect(result.grade.letter, equals('B'));
      expect(result.isMatch, isTrue);
      expect(result.xpEarned, equals(15));
      expect(result.grade.isPassing, isTrue);
    });

    test('Mismatched sign awards F grade and 0 XP', () {
      final result = SignGradingService.evaluate(
        targetSign: helloSign,
        detectedSignId: 'water',
        confidence: 0.88,
      );

      expect(result.grade, equals(SignGrade.f));
      expect(result.isMatch, isFalse);
      expect(result.xpEarned, equals(0));
      expect(result.grade.isPassing, isFalse);
      expect(result.feedback, contains('water'));
    });

    test('Multi-sign session evaluation computes overall grade and summary', () {
      final summary = SignGradingService.evaluateSession(
        lessonTitle: 'Greetings',
        totalSigns: 5,
        correctSigns: 5,
        totalAttempts: 5,
        confidences: [0.92, 0.88, 0.85, 0.90, 0.86],
        baseXp: 50,
      );

      expect(summary.accuracy, equals(1.0));
      expect(summary.accuracyPercentage, equals(100));
      expect(summary.overallGrade, equals(SignGrade.aPlus));
      expect(summary.totalXpEarned, greaterThan(50));
    });
  });
}
