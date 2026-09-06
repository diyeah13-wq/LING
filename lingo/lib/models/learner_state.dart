import 'learner_profile.dart';
import 'progress.dart';

/// Binds a learner identity to their ongoing progress.
class LearnerState {
  final LearnerProfile? profile;
  final Progress progress;

  const LearnerState({this.profile, this.progress = const Progress()});

  LearnerState copyWith({LearnerProfile? profile, Progress? progress}) {
    return LearnerState(
      profile: profile ?? this.profile,
      progress: progress ?? this.progress,
    );
  }

  bool get isOnboarded => profile != null;

  Map<String, dynamic> toJson() => {
        'profile': profile?.toJson(),
        'progress': progress.toJson(),
      };

  factory LearnerState.fromJson(Map<String, dynamic> json) {
    return LearnerState(
      profile: json['profile'] == null
          ? null
          : LearnerProfile.fromJson(json['profile'] as Map<String, dynamic>),
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>? ?? {}),
    );
  }
}