import '../models/lesson.dart';
import '../models/sign.dart';

/// Static catalog of lessons and signs available in the app.
///
/// Lessons are grouped by category. This is the "curriculum" content.
///
/// Every sign in this catalog is part of the on-device recognition
/// vocabulary (see `ModelVocabulary`), so every sign can be camera-practiced.
class LessonCatalog {
  LessonCatalog._();

  static const List<Lesson> lessons = [
    Lesson(
      id: 'greetings',
      title: 'Greetings',
      subtitle: 'Say hello and be polite',
      emoji: '👋',
      category: 'essentials',
      signs: [
        Sign(
          id: 'hello',
          text: 'Hello',
          meaning: 'A friendly greeting — the most-used sign in ASL.',
          howToPerform:
              'Place your right hand beside your head, palm facing out, and '
              'wave your hand back and forth a couple of times, like a '
              'friendly salute.',
          tip: 'Wave with a smile — matching your facial expression adds warmth.',
          type: SignType.motion,
          emoji: '👋',
        ),
        Sign(
          id: 'thank-you',
          text: 'Thank you',
          meaning: 'Express gratitude or appreciation.',
          howToPerform:
              'Start with your flat hand near your chin, then move it forward '
              'and slightly downward, as if blowing a kiss toward the person.',
          tip: 'Finish the motion toward the other person so they know the '
              'thanks is for them.',
          type: SignType.motion,
          emoji: '🙏',
          modelLabel: 'thank you',
        ),
        Sign(
          id: 'please',
          text: 'Please',
          meaning: 'Politely request something.',
          howToPerform:
              'Place your flat open hand over your chest and make a small '
              'circular motion, like drawing a circle over your heart.',
          tip: 'Keep your palm flat and move in slow, small circles.',
          type: SignType.motion,
          emoji: '🙌',
        ),
        Sign(
          id: 'sorry',
          text: 'Sorry',
          meaning: 'Apologize or express sympathy.',
          howToPerform:
              'Make a fist and rub it in a small circular motion over your '
              'chest, over your heart.',
          tip: 'A gentle, repeated circular motion reads clearly.',
          type: SignType.motion,
          emoji: '😔',
        ),
        Sign(
          id: 'goodbye',
          text: 'Goodbye',
          meaning: 'A friendly farewell.',
          howToPerform:
              'Open your hand flat with the palm facing out, then close and '
              'open your fingers together a couple of times, like waving '
              'goodbye with your fingertips.',
          tip: 'Keep the hand upright near your shoulder, fingers together.',
          type: SignType.motion,
          emoji: '👋',
        ),
      ],
    ),
    Lesson(
      id: 'basics',
      title: 'Everyday basics',
      subtitle: 'Core words for starting conversations',
      emoji: '✋',
      category: 'essentials',
      signs: [
        Sign(
          id: 'yes',
          text: 'Yes',
          meaning: 'Agreement or affirmation.',
          howToPerform:
              'Make a fist and bob your hand up and down at the wrist, like a '
              'nodding head.',
          tip: 'The fist bobs from the wrist — keep it small and quick.',
          type: SignType.motion,
          emoji: '👍',
        ),
        Sign(
          id: 'no',
          text: 'No',
          meaning: 'Disagreement or negation.',
          howToPerform:
              'Extend your thumb, forefinger, and middle finger, then bring '
              'the two fingers together against the thumb, like snapping.',
          tip: 'Think of a beak opening and closing — that\'s the shape.',
          type: SignType.motion,
          emoji: '🚫',
        ),
        Sign(
          id: 'help',
          text: 'Help',
          meaning: 'Ask for or offer assistance.',
          howToPerform:
              'Place your open palm under a raised fist and lift both up '
              'together.',
          tip: 'The dominant fist rests in the other palm and moves upward.',
          type: SignType.motion,
          emoji: '🆘',
        ),
        Sign(
          id: 'where',
          text: 'Where',
          meaning: 'Ask about a location or position.',
          howToPerform:
              'Shake your extended index finger side to side, like pointing '
              'to an unknown place.',
          tip: 'Keep only the index finger extended.',
          type: SignType.motion,
          emoji: '📍',
        ),
      ],
    ),
    Lesson(
      id: 'survival',
      title: 'Everyday needs',
      subtitle: 'Essential words for everyday situations',
      emoji: '🆘',
      category: 'daily',
      signs: [
        Sign(
          id: 'water',
          text: 'Water',
          meaning: 'Ask for or refer to water.',
          howToPerform:
              'Make a W handshape (thumb, index, and middle fingers extended) '
              'and tap your chin twice.',
          tip: 'The W shape is formed like the letter W with three fingers up.',
          type: SignType.motion,
          emoji: '💧',
        ),
        Sign(
          id: 'food',
          text: 'Food',
          meaning: 'Refer to food or a meal.',
          howToPerform:
              'Bring your flat hand to your mouth, like tapping it a couple '
              'of times.',
          tip: 'Think "food entering the mouth" — the flat hand moves to the '
              'lips.',
          type: SignType.motion,
          emoji: '🍽️',
        ),
        Sign(
          id: 'doctor',
          text: 'Doctor',
          meaning: 'Refer to a medical professional.',
          howToPerform:
              'Extend your middle three fingers on your wrist, like checking '
              'a pulse.',
          tip: 'The D handshape tapping the wrist traces the pulse point.',
          type: SignType.motion,
          emoji: '🩺',
        ),
        Sign(
          id: 'hospital',
          text: 'Hospital',
          meaning: 'Refer to a hospital or medical facility.',
          howToPerform:
              'Make an H shape and trace a cross on your upper arm.',
          tip: 'The H handshape draws the medical cross symbol.',
          type: SignType.motion,
          emoji: '🏥',
        ),
      ],
    ),
  ];

  static Lesson? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  static Sign? signById(String id) {
    for (final lesson in lessons) {
      for (final sign in lesson.signs) {
        if (sign.id == id) return sign;
      }
    }
    return null;
  }

  /// All signs across every lesson.
  static List<Sign> get allSigns {
    final result = <Sign>[];
    for (final lesson in lessons) {
      result.addAll(lesson.signs);
    }
    return result;
  }

  /// The full supported vocabulary for the communication mode.
  static Set<String> get supportedVocabulary {
    return allSigns.map((s) => s.text.toLowerCase()).toSet();
  }
}