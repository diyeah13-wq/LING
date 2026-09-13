"""Build normalized feature dataset + stratified train/val/test splits.

Each sample: raw landmarks [24,21,3] from extract_landmarks.py.
Normalization per frame:
  - translate so wrist (lm0) is origin
  - scale by palm size = ||lm0 - lm9||  (robust to camera distance/zoom)
  - z relative to wrist
Features per frame: 63 floats (21 x 3).

Split: stratified per class, deterministic seed.
  hello/goodbye (<=5 clips):  train=2, val=1, test=rest
  others:                    60% train, 20% val, 20% test (min 1 each)

Outputs:
  ml_work/dataset/{train,val,test}.npz   with keys X (n,24,63), y (n,) int, class_names
  ml_work/dataset/class_map.json          class index -> sign id
"""
import json
import os

import numpy as np
from sklearn.model_selection import train_test_split

EXTRACTED = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\extracted"
OUT = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\dataset"

# sign id (matches Flutter lesson_catalog) -> folder name
SIGN_TO_FOLDER = {
    "hello": "hello",
    "thank-you": "thank you",
    "please": "please",
    "sorry": "sorry",
    "goodbye": "goodbye",
    "yes": "yes",
    "no": "no",
    "help": "help",
    "water": "water",
    "food": "food",
    "doctor": "doctor",
    "hospital": "hospital",
    "where": "where",
}

RNG_SEED = 7
N_FRAMES = 24


def normalize(seq):
    """seq: [24,21,3]. Returns [24,63] normalized; zero rows stay zero."""
    out = np.zeros((N_FRAMES, 21 * 3), dtype=np.float32)
    for i in range(N_FRAMES):
        frame = seq[i]
        wrist = frame[0]
        if np.all(wrist == 0):
            continue
        palm = frame[9] - wrist
        scale = float(np.linalg.norm(palm))
        if scale < 1e-6:
            continue
        rel = frame - wrist
        rel = rel / scale
        out[i] = rel.reshape(-1).astype(np.float32)
    return out


def load_all():
    sign_ids = list(SIGN_TO_FOLDER.keys())
    X, y = [], []
    for cls, sid in enumerate(sign_ids):
        folder = os.path.join(EXTRACTED, SIGN_TO_FOLDER[sid])
        for fn in sorted(os.listdir(folder)):
            if not fn.endswith(".npy"):
                continue
            seq = np.load(os.path.join(folder, fn))
            X.append(normalize(seq))
            y.append(cls)
    return np.stack(X), np.array(y), sign_ids


def main():
    X, y, sign_ids = load_all()
    print("samples:", X.shape, "classes:", len(sign_ids), "per class:", np.bincount(y))

    os.makedirs(OUT, exist_ok=True)

    # Per-class deterministic split (handles tiny classes):
    #   test  = max(1, round(0.2*n))
    #   val   = max(1, round(0.2*n))
    #   train = remaining (>= 2 always for n >= 4)
    rng = np.random.default_rng(RNG_SEED)
    train_idx, val_idx, test_idx = [], [], []
    for cls in range(len(sign_ids)):
        idxs = np.where(y == cls)[0]
        rng.shuffle(idxs)
        n = len(idxs)
        test_n = max(1, round(0.2 * n))
        val_n = max(1, round(0.2 * n))
        train_n = n - test_n - val_n
        train_idx += idxs[:train_n].tolist()
        val_idx += idxs[train_n:train_n + val_n].tolist()
        test_idx += idxs[train_n + val_n:].tolist()

    splits = {
        "train": (np.array(train_idx), "train"),
        "val": (np.array(val_idx), "val"),
        "test": (np.array(test_idx), "test"),
    }
    class_map = {i: sid for i, sid in enumerate(sign_ids)}
    with open(os.path.join(OUT, "class_map.json"), "w") as f:
        json.dump(class_map, f, indent=2)

    for name, (idx, out_name) in splits.items():
        np.savez_compressed(
            os.path.join(OUT, f"{out_name}.npz"),
            X=X[idx],
            y=y[idx],
            class_names=np.array(sign_ids),
        )
        print(f"{out_name}: {len(idx)} samples")

    print("class_map written. Split distribution:")
    for name, (idx, _) in splits.items():
        counts = np.bincount(y[idx], minlength=len(sign_ids))
        print(name, dict(zip(sign_ids, counts.tolist())))


if __name__ == "__main__":
    main()