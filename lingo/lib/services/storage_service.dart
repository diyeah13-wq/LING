import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learner_state.dart';

/// Persists the learner's state (profile + progress) locally.
///
/// Uses [SharedPreferences] for simple, dependency-free local storage.
/// The stored data is a single JSON blob under one key.
class StorageService {
  static const _learnerStateKey = 'lingo.learner_state';

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  /// Loads the persisted learner state, or returns an empty default state.
  LearnerState loadLearnerState() {
    final raw = _prefs.getString(_learnerStateKey);
    if (raw == null) return const LearnerState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LearnerState.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable state — start fresh rather than crash.
      return const LearnerState();
    }
  }

  /// Persists the given learner state.
  Future<void> saveLearnerState(LearnerState state) async {
    await _prefs.setString(_learnerStateKey, jsonEncode(state.toJson()));
  }

  /// Clears all persisted learner state.
  Future<void> clear() async {
    await _prefs.remove(_learnerStateKey);
  }

  static Future<StorageService> open() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }
}