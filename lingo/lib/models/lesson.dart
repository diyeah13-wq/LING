import 'sign.dart';

/// A lesson, containing a group of related signs to learn together.
class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String category;
  final List<Sign> signs;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.category,
    required this.signs,
  });

  int get xpReward => signs.length * 20;

  /// Returns true if [sign] is part of this lesson.
  bool contains(String signId) => signs.any((s) => s.id == signId);
}
