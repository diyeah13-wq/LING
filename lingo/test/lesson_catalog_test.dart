import 'package:flutter_test/flutter_test.dart';
import 'package:lingo/data/lesson_catalog.dart';
import 'package:lingo/data/model_vocabulary.dart';

void main() {
  group('LessonCatalog & Video Reference Tests', () {
    test('All 13 word vocabulary signs have resolved reference video assets', () {
      final expectedWords = [
        'hello',
        'thank-you',
        'please',
        'sorry',
        'goodbye',
        'yes',
        'no',
        'help',
        'where',
        'water',
        'food',
        'doctor',
        'hospital',
      ];

      for (final signId in expectedWords) {
        final sign = LessonCatalog.signById(signId);
        expect(sign, isNotNull, reason: 'Sign $signId should exist in catalog');
        expect(
          sign!.hasVideoReference,
          isTrue,
          reason: 'Sign $signId must have a video reference',
        );
        expect(
          sign.resolvedReferenceVideoAsset,
          equals('assets/references/videos/$signId.mp4'),
        );
      }
    });

    test('ModelVocabulary matches supported catalog signs', () {
      for (final label in ModelVocabulary.labels) {
        final signId = ModelVocabulary.signIdForLabel(label);
        expect(signId, isNotNull, reason: 'Label $label must map to signId');
        final sign = LessonCatalog.signById(signId);
        expect(sign, isNotNull, reason: 'Sign $signId must exist in catalog');
      }
    });
  });
}
