import 'package:flutter_test/flutter_test.dart';
import 'package:lingo/models/progress.dart';

void main() {
  group('Progress model tests', () {
    test('XP and daily XP tally', () {
      final now = DateTime.now();
      var p = const Progress();
      p = p.addXp(25, today: now);
      expect(p.xp, equals(25));
      expect(p.streak, equals(1));

      p = p.addXp(50, today: now);
      expect(p.xp, equals(75));
    });

    test('Accuracy computation', () {
      var p = const Progress();
      expect(p.accuracy, equals(0.0));

      p = p.recordAttempt(success: true);
      p = p.recordAttempt(success: true);
      p = p.recordAttempt(success: false);
      // 2 / 3 = 0.6666...
      expect(p.correctAttempts, equals(2));
      expect(p.incorrectAttempts, equals(1));
      expect((p.accuracy * 100).round(), equals(67));
    });

    test('Sign learning marks sign and updates set', () {
      var p = const Progress();
      p = p.learnSign('hello');
      p = p.learnSign('thank-you');
      p = p.learnSign('hello'); // duplicate

      expect(p.signsLearned.length, equals(2));
      expect(p.signsLearned.contains('hello'), isTrue);
      expect(p.signsLearned.contains('thank-you'), isTrue);
    });
  });
}
