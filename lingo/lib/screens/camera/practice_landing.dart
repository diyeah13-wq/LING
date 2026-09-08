import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sign.dart';
import 'detection_camera_screen.dart';

/// Full-screen camera practice for a single sign.
///
/// Launches the live recognition pipeline targeting [sign]; when the user
/// performs the expected sign correctly they earn XP (see
/// [DetectionCameraScreen]).
class PracticeCameraLanding extends ConsumerWidget {
  final Sign sign;

  const PracticeCameraLanding({super.key, required this.sign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetectionCameraScreen(expectedSignId: sign.id);
  }
}