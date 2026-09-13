"""Train the on-device ASL alphabet and number handshape classifier.

Input: archive (4)/asl_dataset/{0-9,a-z}/*.jpg
Features: one MediaPipe hand frame, normalized to 63 wrist-relative values.
Outputs: ml_work/models/lingo_static_sign_model[(_f16)].tflite,
         ml_work/models/static_class_map.json and static_stats.json
"""
import json
import os

import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

ROOT = r"C:\Users\Lenovo\Desktop\LINGO"
DATASET = os.path.join(ROOT, "archive (4)", "asl_dataset")
HAND_MODEL = os.path.join(ROOT, "ml_work", "models", "hand_landmarker.task")
OUT = os.path.join(ROOT, "ml_work", "models")
LABELS = list("0123456789abcdefghijklmnopqrstuvwxyz")
SEED = 7

np.random.seed(SEED)
tf.random.set_seed(SEED)


def normalize(landmarks):
    """Match SignFeatureExtractor.normalizeFrame in the Flutter app."""
    points = np.asarray(landmarks, dtype=np.float32)
    wrist = points[0]
    scale = np.linalg.norm(points[9] - wrist)
    if scale < 1e-6:
        return None
    return ((points - wrist) / scale).reshape(-1).astype(np.float32)


def extract_samples():
    options = mp.tasks.vision.HandLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(model_asset_path=HAND_MODEL),
        running_mode=mp.tasks.vision.RunningMode.IMAGE,
        num_hands=1,
        min_hand_detection_confidence=0.4,
        min_hand_presence_confidence=0.4,
    )
    features, labels, missing = [], [], 0
    with mp.tasks.vision.HandLandmarker.create_from_options(options) as landmarker:
        for label_index, label in enumerate(LABELS):
            folder = os.path.join(DATASET, label)
            files = sorted(
                f for f in os.listdir(folder)
                if f.lower().endswith((".jpg", ".jpeg", ".png"))
            )
            for filename in files:
                image = cv2.imread(os.path.join(folder, filename))
                if image is None:
                    missing += 1
                    continue
                rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                result = landmarker.detect(
                    mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                )
                if not result.hand_landmarks:
                    missing += 1
                    continue
                vector = normalize(
                    [[p.x, p.y, p.z] for p in result.hand_landmarks[0]]
                )
                if vector is None:
                    missing += 1
                    continue
                features.append(vector)
                labels.append(label_index)
    if not features:
        raise RuntimeError("No hand landmarks were extracted from the dataset")
    print("extracted:", len(features), "missing:", missing)
    return np.stack(features), np.asarray(labels, dtype=np.int32)


def export(model):
    os.makedirs(OUT, exist_ok=True)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    model_bytes = converter.convert()
    with open(os.path.join(OUT, "lingo_static_sign_model.tflite"), "wb") as file:
        file.write(model_bytes)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    model_f16 = converter.convert()
    with open(os.path.join(OUT, "lingo_static_sign_model_f16.tflite"), "wb") as file:
        file.write(model_f16)
    return len(model_bytes), len(model_f16)


def main():
    X, y = extract_samples()
    indices = np.arange(len(y))
    train_idx, test_idx = train_test_split(
        indices, test_size=0.2, random_state=SEED, stratify=y
    )
    train_idx, val_idx = train_test_split(
        train_idx, test_size=0.2, random_state=SEED, stratify=y[train_idx]
    )

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(63,)),
        tf.keras.layers.Dense(128, activation="relu"),
        tf.keras.layers.Dropout(0.25),
        tf.keras.layers.Dense(64, activation="relu"),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(len(LABELS), activation="softmax"),
    ])
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    history = model.fit(
        X[train_idx], y[train_idx],
        validation_data=(X[val_idx], y[val_idx]),
        epochs=150,
        batch_size=32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=20, restore_best_weights=True
            )
        ],
        verbose=1,
    )
    _, accuracy = model.evaluate(X[test_idx], y[test_idx], verbose=0)
    model_size, model_f16_size = export(model)

    with open(os.path.join(OUT, "static_class_map.json"), "w") as file:
        json.dump({i: label for i, label in enumerate(LABELS)}, file, indent=2)
    with open(os.path.join(OUT, "static_stats.json"), "w") as file:
        json.dump({
            "test_accuracy": float(accuracy),
            "n_samples": int(len(y)),
            "n_train": int(len(train_idx)),
            "n_val": int(len(val_idx)),
            "n_test": int(len(test_idx)),
            "classes": LABELS,
            "best_epoch": int(np.argmin(history.history["val_loss"])) + 1,
            "tflite_bytes": model_size,
            "tflite_f16_bytes": model_f16_size,
        }, file, indent=2)
    print(f"test accuracy: {accuracy:.1%}")
    print(f"tflite bytes: {model_size}; float16 bytes: {model_f16_size}")


if __name__ == "__main__":
    main()