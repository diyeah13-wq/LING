enum LearningGoal {
  everyday,
  college,
  travel,
  workplace,
  justLearning;

  String get label {
    switch (this) {
      case LearningGoal.everyday:
        return 'Everyday communication';
      case LearningGoal.college:
        return 'College';
      case LearningGoal.travel:
        return 'Travel';
      case LearningGoal.workplace:
        return 'Workplace';
      case LearningGoal.justLearning:
        return 'Just learning ASL';
    }
  }

  String get icon {
    switch (this) {
      case LearningGoal.everyday:
        return '💬';
      case LearningGoal.college:
        return '🎓';
      case LearningGoal.travel:
        return '✈️';
      case LearningGoal.workplace:
        return '💼';
      case LearningGoal.justLearning:
        return '🤟';
    }
  }

  String get description {
    switch (this) {
      case LearningGoal.everyday:
        return 'Connect with Deaf and hard-of-hearing people in daily life.';
      case LearningGoal.college:
        return 'Communicate on campus, in classes, and with classmates.';
      case LearningGoal.travel:
        return 'Use ASL while traveling and meeting new people.';
      case LearningGoal.workplace:
        return 'Communicate with Deaf colleagues and customers.';
      case LearningGoal.justLearning:
        return 'You\'re curious and want to learn a new language.';
    }
  }

  static LearningGoal fromName(String name) {
    return LearningGoal.values.firstWhere(
      (g) => g.name == name,
      orElse: () => LearningGoal.justLearning,
    );
  }
}
