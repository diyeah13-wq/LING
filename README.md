# LINGO

An interactive ASL learning & communication app for Android/iOS, built with Flutter.

## Status: MVP in progress

- **Vocabulary (12 signs):** hello, thank you, please, sorry, yes, no, help, where, water, food, doctor, hospital
- **On-device recognition pipeline (validated):**
  - MediaPipe palm detection (`palm_detection_without_custom_op.tflite`) → ROI crop
  - MediaPipe hand-landmark model (`hand_landmark.tflite`) → 21 landmarks
  - Custom int8 TFLite classifier (per-frame MLP over wrist-normalized landmarks, temporal majority vote)
  - Validation vs. MediaPipe Task API on SL dataset: median landmark error ~2% of frame size

## Structure

```
lingo/      Flutter app
ml/         Python ML pipeline (dataset → landmarks → classifier training/TFLite export)
archive (3)/  SL dataset (words videos) — gitignored
archive (4)/  ASL static alphabet dataset — gitignored
```

## Running

```sh
cd lingo && flutter run
```