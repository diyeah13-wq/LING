"""Analyze Dataset A videos: resolution, fps, frame count, duration."""
import os
import sys
import csv
import cv2

SL = r"C:\Users\Lenovo\Desktop\LINGO\archive (3)\dataset\SL"
WORDS = ["hello", "thank you", "please", "sorry", "goodbye",
         "yes", "no", "help", "water", "food", "doctor", "hospital", "where"]

def main():
    rows = []
    for word in WORDS:
        folder = os.path.join(SL, word)
        for fn in sorted(os.listdir(folder)):
            path = os.path.join(folder, fn)
            cap = cv2.VideoCapture(path)
            if not cap.isOpened():
                rows.append([word, fn, -1, -1, -1, 0])
                continue
            w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = cap.get(cv2.CAP_PROP_FPS)
            n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = n / fps if fps > 0 else 0
            rows.append([word, fn, w, h, round(fps, 2), round(duration, 2)])
            cap.release()
    out = r"C:\Users\Lenovo\Desktop\LINGO\ml_work\video_analysis.csv"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", newline="") as f:
        wc = csv.writer(f)
        wc.writerow(["word", "file", "width", "height", "fps", "duration_s"])
        wc.writerows(rows)
    print(f"Analyzed {len(rows)} videos -> {out}")
    for r in rows:
        print(r)

if __name__ == "__main__":
    main()