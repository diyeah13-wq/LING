import 'learning_goal.dart';
import 'skill_level.dart';

/// A learner's profile, created during onboarding.
class LearnerProfile {
  final String name;
  final LearningGoal goal;
  final SkillLevel level;

  const LearnerProfile({
    required this.name,
    required this.goal,
    required this.level,
  });

  LearnerProfile copyWith({
    String? name,
    LearningGoal? goal,
    SkillLevel? level,
  }) {
    return LearnerProfile(
      name: name ?? this.name,
      goal: goal ?? this.goal,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'goal': goal.name,
        'level': level.name,
      };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      name: json['name'] as String? ?? '',
      goal: LearningGoal.fromName(json['goal'] as String? ?? ''),
      level: SkillLevel.fromName(json['level'] as String? ?? ''),
    );
  }
}
