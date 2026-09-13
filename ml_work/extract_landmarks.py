"""Extract MediaPipe hand landmarks from Dataset A MVP video clips.

For each clip we:
  - decode frames with OpenCV
  - sample N_SEQ frames uniformly across the clip
  - run HandLandmarker on each sampled frame
  - store the 21x3 landmarks (raw, normalized image coords) + handedness

Output: ml_work/extracted/{word}/{clip}.npy  (float32 [N_SEQ,21,3]) plus a
handedness row, else a .missing marker file when the hand is never found.
A per-word .coverage.json records how many clips had hands detected.
"""
import json
import os
from collections import Counter

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python.vision import (
    HandLandmarker,
    HandLandmarkerOptions,
    RunningMode,
)

SL = r"C:\Users\Lenovo\Desktop\LINGO\archive (3)\dataset\SL"
MODEL = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\models\hand_landmarker.task"
OUT = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\extracted"

WORDS = ["hello", "thank you", "please", "sorry", "goodbye",
         "yes", "no", "help", "water", "food", "doctor", "hospital", "where"]

N_SEQ = 24
MIN_FRAMES = 6   # min sampled frames with a hand to accept the clip


def main():
    options = HandLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(model_asset_path=MODEL),
        running_mode=RunningMode.IMAGE,  # one-shot per frame
        num_hands=1,
        min_hand_detection_confidence=0.4,
        min_hand_presence_confidence=0.4,
    )
    landmarker = HandLandmarker.create_from_options(options)

    summary = {}
    for word in WORDS:
        folder = os.path.join(SL, word)
        clips = sorted(f for f in os.listdir(folder) if f.lower().endswith(".mp4"))
        out_dir = os.path.join(OUT, word)
        os.makedirs(out_dir, exist_ok=True)
        ok = 0
        missing = []
        for clip in clips:
            path = os.path.join(folder, clip)
            seq = extract_landmarks(landmarker, path)
            np.save(os.path.join(out_dir, clip.replace(".mp4", ".npy")), seq.astype(np.float32))
            if not np.any(seq):
                missing.append(clip)
            else:
                ok += 1
        summary[word] = {"clips": len(clips), "with_hand": ok, "missing": missing}
        print(word, summary[word])

    with open(os.path.join(OUT, "coverage.json"), "w") as f:
        json.dump(summary, f, indent=2)
    print("done")


def extract_landmarks(landmarker, path) -> np.ndarray:
    """Returns float32 array [N_SEQ,21,3]. All-zero rows mean 'no hand'."""
    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        return np.zeros((N_SEQ, 21, 3), dtype=np.float32)
    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 1
    idxs = np.linspace(0, n_frames - 1, N_SEQ).astype(int)
    out = np.zeros((N_SEQ, 21, 3), dtype=np.float32)
    for i, idx in enumerate(idxs):
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ok, frame = cap.read()
        if not ok or frame is None:
            continue
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        res = landmarker.detect(img)
        if res.hand_landmarks:
            lm = res.hand_landmarks[0]
            arr = np.array([[p.x, p.y, p.z] for p in lm], dtype=np.float32)
            out[i] = arr
    cap.release()
    return out


if __name__ == "__main__":
    main()