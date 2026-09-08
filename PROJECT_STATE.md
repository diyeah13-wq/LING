# LINGO project state — last updated 2026-09-07

## Goal
On-device ASL sign classifier in `lingo/` (Flutter app). Camera/pose pipeline must
match the validated Python training pipeline so collected frames match training
distribution.

## Architecture
- **Hand detection**: `hand_detection` package (MediaPipe palm + landmark models, cross-platform)
- **Classification**: Custom TFLite GRU(64) model (`lingo_sign_model.tflite`, 245KB)
- **Feature extraction**: 24-frame sliding window → wrist-translate + palm-scale → 126 features/frame (63 positions + 63 velocity deltas)
- **Input**: LandmarkFrame [24, 126] float32 → GRU → 13-class softmax

## What's done (committed + clean)
- `ml_work/`: Full Python ML pipeline
  - `analyze_videos.py` — Dataset A (Word-Level ASL) analysis
  - `extract_landmarks.py` — MediaPipe hand_landmarker → [24,21,3] per clip
  - `build_dataset.py` — wrist-translate + palm-scale normalization, stratified splits (70/19/19)
  - `train_model.py` — GRU(64) classifier, 84.2% test accuracy
  - `models/lingo_sign_model.tflite` + `lingo_sign_model_f16.tflite` (TFLite exports)
- `lingo/`: Flutter app
  - `lib/services/ml/sign_feature_extractor.dart` — Normalization (wrist-translate + palm-scale)
  - `lib/services/ml/tflite_sign_classifier.dart` — TFLite inference (implements SignClassifier)
  - `lib/services/ml/sign_recognition_engine.dart` — HandDetector + buffer + hysteresis + confirmed stream
  - `lib/screens/camera/detection_camera_screen.dart` — Live camera with skeleton overlay + practice/communicate modes
  - `lib/screens/communicate/communicate_screen.dart` — Free-form recognition (phrase builder)
  - `lib/data/model_vocabulary.dart` — 13-class label mapping (matches training class_map)
  - Routes wired: `/practice?sign=:id` (target), `/communicate` (free)
  - `flutter analyze`: clean
  - `flutter build apk --debug`: success (266MB debug)

## Model details
- Training class order: `["hello","thank-you","please","sorry","goodbye","yes","no","help","water","food","doctor","hospital","where"]`
- Test accuracy: 84.2% (16/19 clips)
- Confusion: hello (0/1), no (1/2), doctor (1/2) — weak due to tiny datasets (4-14 clips/class)
- Feature normalization: per-frame, wrist-origin, palm-scale, z-relative-to-wrist

## Key packages
- `hand_detection: ^4.1.0` (MediaPipe hand detection + landmarks, isolate-backed)
- `flutter_litert: ^3.8.0` (TFLite Interpreter, camera utils)
- `camera: ^0.11.4` (camera stream)
- `flutter_riverpod: ^2.6.1` (state management)

## Android config
- `minSdk = 24`, `compileSdk = flutter.compileSdkVersion`
- Camera permission declared in AndroidManifest.xml
- hand_detection TFLite models auto-bundled via package assets

## Known limitations
- Debug APK 266MB (large due to opencv_dart + hand_detection models)
- Kotlin KGP deprecation warning (camera_android_camerax) — cosmetic
- Single-hand detection only (maxDetections: 1)
- Front camera preferred (selfie-style), rotation handled via `rotationForFrame`

## Next steps
1. Optimize APK size (release build, split APKs by ABI)
2. Add multi-sign practice session (cycle through lesson signs)
3. Improve accuracy with data augmentation or more training data
4. Add word history / sentence builder for Communicate mode
5. Polish UI (onboarding animations, mascot integration with camera)
