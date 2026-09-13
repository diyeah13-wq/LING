"""Train a lightweight GRU sequence classifier on ASL landmark sequences.

Model:   Input(24,63) -> GRU(48) -> Dropout -> Dense(32) -> Dense(n_classes)
Training: class-weighted CE, Adam, early stopping, mild input noise aug.

Outputs:
  ml_work/models/lingo_sign_model.tflite      (float32, on-device)
  ml_work/models/lingo_sign_model_f16.tflite  (float16, on-device)
  ml_work/models/stats.json                   (split sizes + test accuracy)
  ml_work/models/test_report.txt              (per-class report)
"""
import json
import os

import numpy as np
import tensorflow as tf

DS = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\dataset"
OUT = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\models"
SEED = 7

tf.random.set_seed(SEED)
np.random.seed(SEED)


def load(name):
    d = np.load(os.path.join(DS, f"{name}.npz"))
    return d["X"], d["y"], d["class_names"]


def _add_deltas(X):
    """X: [n,24,63] positions -> [n,24,126] positions+velocity."""
    pad = np.zeros_like(X[:, :1])
    d = np.concatenate([pad, np.diff(X, axis=1)], axis=1)
    return np.concatenate([X, d], axis=-1).astype(np.float32)


def make_ds(X, y, batch, shuffle=False):
    n = len(y)
    class_map = np.unique(y)
    counts = np.bincount(y)
    weights = {int(c): (1.0 / float(counts[c])) ** 0.5 for c in class_map}
    sample_w = np.array([weights[int(c)] for c in y], dtype=np.float32)

    def aug(x, w):
        x = tf.cast(x, tf.float32)
        if shuffle:
            # noise
            x = x + tf.random.normal(tf.shape(x), 0.0, 0.02)
            # random x-mirror across position x channels (0,3,6,... of first 63)
            if tf.random.uniform(()) > 0.5:
                pos = x[..., :63]
                vel = x[..., 63:]
                pos = tf.concat(
                    [-pos[..., 0::3], pos[..., 1::3], pos[..., 2::3]], axis=-1
                )
                vel = tf.concat(
                    [-vel[..., 0::3], vel[..., 1::3], vel[..., 2::3]], axis=-1
                )
                x = tf.concat([pos, vel], axis=-1)
            # random temporal shift
            shift = tf.random.uniform((), -2, 3, dtype=tf.int32)
            x = tf.roll(x, shift=shift, axis=-2)
        return x, w

    ds = tf.data.Dataset.from_tensor_slices((X, y, sample_w))
    if shuffle:
        ds = ds.shuffle(512, seed=SEED)
    ds = ds.map(lambda x, y, w: aug(tf.cast(x, tf.float32), y), num_parallel_calls=4)
    ds = ds.batch(batch)
    return ds, weights


def main():
    Xtr, ytr, names = load("train")
    Xva, yva, _ = load("val")
    Xte, yte, _ = load("test")
    # Add velocity fusion: positions + deltas -> 126 features/frame
    Xtr = _add_deltas(Xtr)
    Xva = _add_deltas(Xva)
    Xte = _add_deltas(Xte)
    n_cls = len(np.unique(ytr))
    print("train", Xtr.shape, "val", Xva.shape, "test", Xte.shape, "features/step:", Xtr.shape[-1])

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(24, Xtr.shape[-1])),
        tf.keras.layers.GRU(64, dropout=0.25, unroll=True),
        tf.keras.layers.Dense(48, activation="relu"),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(n_cls, activation="softmax"),
    ])
    model.compile(
        optimizer=tf.keras.optimizers.Adam(2e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    ds_train, class_w = make_ds(Xtr, ytr, 16, shuffle=True)
    ds_val, _ = make_ds(Xva, yva, 16, shuffle=False)

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=40, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=12),
    ]
    hist = model.fit(
        ds_train, epochs=150, validation_data=ds_val,
        class_weight=class_w, callbacks=callbacks, verbose=1,
    )

    # --- evaluation -------------------------------------------------------
    yp = model.predict(Xte, verbose=0).argmax(-1)
    acc = float(np.mean(yp == yte))
    cm = tf.math.confusion_matrix(yte, yp, num_classes=n_cls).numpy()

    lines = []
    lines.append(f"Test accuracy: {acc:.3f} ({acc:.1%})")
    lines.append("Per-class (class: correct/total):")
    for i, name in enumerate(names):
        lines.append(f"  {name:<12} {int((cm[i].sum() - cm[i,i] == 0 and cm[i,i]) or cm[i,i])}/{int(cm[i].sum())}")
    report = "\n".join(lines)
    print(report)
    with open(os.path.join(OUT, "test_report.txt"), "w") as f:
        f.write(report)
    np.save(os.path.join(OUT, "confusion.npy"), cm)

    # --- export -----------------------------------------------------------
    os.makedirs(OUT, exist_ok=True)

    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = []
    tflite = conv.convert()
    with open(os.path.join(OUT, "lingo_sign_model.tflite"), "wb") as f:
        f.write(tflite)

    conv16 = tf.lite.TFLiteConverter.from_keras_model(model)
    conv16.optimizations = [tf.lite.Optimize.DEFAULT]
    conv16.target_spec.supported_types = [tf.float16]
    tflite16 = conv16.convert()
    with open(os.path.join(OUT, "lingo_sign_model_f16.tflite"), "wb") as f:
        f.write(tflite16)

    with open(os.path.join(OUT, "stats.json"), "w") as f:
        json.dump({
            "test_accuracy": acc,
            "n_train": int(len(Xtr)), "n_val": int(len(Xva)), "n_test": int(len(Xte)),
            "classes": names.tolist(),
            "best_epoch": int(np.argmin(hist.history["val_loss"])) + 1,
        }, f, indent=2)

    print("tflite float32 bytes:", len(tflite))
    print("tflite float16 bytes:", len(tflite16))


if __name__ == "__main__":
    main()