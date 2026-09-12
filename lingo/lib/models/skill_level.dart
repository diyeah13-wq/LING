enum SkillLevel {
  beginner,
  intermediate;

  String get label {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
    }
  }

  String get description {
    switch (this) {
      case SkillLevel.beginner:
        return 'I\'m new to ASL — I know little or nothing yet.';
      case SkillLevel.intermediate:
        return 'I know some ASL and want to improve my skills.';
    }
  }

  static SkillLevel fromName(String name) {
    return SkillLevel.values.firstWhere(
      (l) => l.name == name,
      orElse: () => SkillLevel.beginner,
    );
  }
}
