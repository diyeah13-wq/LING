import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/learning_goal.dart';
import '../../models/skill_level.dart';
import '../../providers/learner_provider.dart';
import '../../widgets/common/lingo_button.dart';
import '../../widgets/mascot/mascot.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  LearningGoal? _selectedGoal;
  SkillLevel? _selectedLevel;
  final TextEditingController _nameController = TextEditingController();

  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim().isEmpty
        ? 'Friend'
        : _nameController.text.trim();
    final goal = _selectedGoal ?? LearningGoal.justLearning;
    final level = _selectedLevel ?? SkillLevel.beginner;

    await ref.read(learnerStateProvider.notifier).setProfile(
          name: name,
          goal: goal,
          level: level,
        );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _selectedGoal != null;
      case 2:
        return _selectedLevel != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _goToPage(_totalPages - 1),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(onNext: () => _goToPage(1)),
                  _GoalPage(
                    selected: _selectedGoal,
                    onSelect: (goal) => setState(() => _selectedGoal = goal),
                  ),
                  _LevelPage(
                    selected: _selectedLevel,
                    onSelect: (level) => setState(() => _selectedLevel = level),
                    nameController: _nameController,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LingoSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? LingoColors.primary
                              : LingoColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: LingoSpacing.lg),
                  LingoButton(
                    label: _currentPage == _totalPages - 1
                        ? 'Start learning'
                        : 'Continue',
                    onPressed: _canProceed
                        ? () {
                            if (_currentPage == _totalPages - 1) {
                              _finishOnboarding();
                            } else {
                              _goToPage(_currentPage + 1);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(LingoSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(mood: MascotMood.greeting, size: 120),
          const SizedBox(height: LingoSpacing.lg),
          Text('Welcome to LINGO', style: theme.textTheme.headlineMedium),
          const SizedBox(height: LingoSpacing.sm),
          Text(
            'LINGO makes learning American Sign Language fun and practical. '
            'Build real hand signing skills you can use in the real world.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LingoSpacing.lg),
          const _FeaturePoint(icon: Icons.school, text: 'Short, visual lessons'),
          const _FeaturePoint(
              icon: Icons.videocam, text: 'Practice with your camera'),
          const _FeaturePoint(
              icon: Icons.psychology, text: 'Real hand-sign recognition'),
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LingoSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LingoColors.primary, size: 22),
          const SizedBox(width: LingoSpacing.md),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final LearningGoal? selected;
  final ValueChanged<LearningGoal> onSelect;

  const _GoalPage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you learning ASL?',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: LingoSpacing.sm),
            Text(
              'This helps us tailor your lessons.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: LingoSpacing.xl),
            for (final goal in LearningGoal.values) ...[
              _OptionCard(
                emoji: goal.icon,
                label: goal.label,
                description: goal.description,
                selected: selected == goal,
                onTap: () => onSelect(goal),
              ),
              const SizedBox(height: LingoSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  final SkillLevel? selected;
  final ValueChanged<SkillLevel> onSelect;
  final TextEditingController nameController;

  const _LevelPage({
    required this.selected,
    required this.onSelect,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What's your current level?", style: theme.textTheme.headlineMedium),
            const SizedBox(height: LingoSpacing.sm),
            Text(
              'Be honest — the lessons adapt to you.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: LingoSpacing.xl),
            for (final level in SkillLevel.values) ...[
              _OptionCard(
                emoji: level == SkillLevel.beginner ? '🌱' : '🌿',
                label: level.label,
                description: level.description,
                selected: selected == level,
                onTap: () => onSelect(level),
              ),
              const SizedBox(height: LingoSpacing.md),
            ],
            const SizedBox(height: LingoSpacing.lg),
            Text("What should we call you?", style: theme.textTheme.titleMedium),
            const SizedBox(height: LingoSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: LingoSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? LingoColors.primary.withValues(alpha: 0.08)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(LingoSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LingoRadius.lg),
            border: Border.all(
              color: selected ? LingoColors.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle,
                    color: LingoColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}