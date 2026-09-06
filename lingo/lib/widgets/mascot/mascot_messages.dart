import 'dart:math';

/// Context-aware encouraging messages spoken by the mascot.
///
/// Keep this in one place so copy can be fine-tuned without touching UI logic.
class MascotMessages {
  MascotMessages._();

  static final _random = Random();

  static String greeting([String? name]) {
    final base = name == null || name.isEmpty ? 'Hey there' : 'Hey $name';
    final messages = [
      '$base 👋 Ready to learn some sign language?',
      '$base! Let\'s make hands happy today 🤟',
      '$base, I\'m so glad you\'re here. Let\'s sign!',
    ];
    return _pick(messages);
  }

  static String correct() {
    const messages = [
      'Perfect! Your hand is right where it should be ✅',
      'Nailed it! That was spot on 🎯',
      'Beautiful! You read my mind 👏',
      'Excellent form! You\'re getting the hang of this 💪',
    ];
    return _pick(messages);
  }

  static String incorrect([String? signWord]) {
    final word = signWord ?? 'that sign';
    return 'Almost! Let\'s try "$word" once more — you\'re close 🔍';
  }

  static String tightlyIncorrect([String? signWord]) {
    return 'So close! One more try — you\'re nearly there ✨';
  }

  static String streak(int length) {
    if (length <= 1) {
      return 'First day of practice! 🔥 Let\'s come back tomorrow too.';
    }
    return '$length-day streak! You\'re on fire 🔥 Keep it going!';
  }

  static String lessonComplete(String lessonTitle) {
    final messages = [
      'Lesson complete! "$lessonTitle" — you crushed it 🎉',
      'That\'s a wrap on "$lessonTitle"! Amazing work 🏆',
    ];
    return _pick(messages);
  }

  static String levelUp() => 'You\'re leveling up! Next stop: fluency 🚀';

  static String _pick(List<String> options) =>
      options[_random.nextInt(options.length)];
}