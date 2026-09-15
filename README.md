# 🖐️ LINGO

**Learn ASL. Communicate instantly.**

LINGO is an on-device American Sign Language (ASL) learning and communication app for Android. It uses a custom-built machine learning pipeline — MediaPipe hand tracking + a GRU neural network — to recognize your signs in real time through the camera, grade your practice, and translate free-form signing into text. No internet, no cloud, no privacy worries: everything runs on your phone.

> Built for **AppSprint 2025**.

---

## 👥 Team Information

| | |
|---|---|
| **Team Name** | LINGO Team |
| **Team Member** | Diya Joy |
| **College** | Sahrdaya College of Engineering and Technology |

---

## 🚨 Problem Statement

American Sign Language is the primary language for millions of Deaf and hard-of-hearing people, yet hearing people rarely learn it. Many ASL learning tools are:

- **Expensive or passive** — video-only courses with no feedback on whether you're signing correctly.
- **Delayed** — gamified apps grade you *after* the fact, not as you sign.
- **Not communication tools** — learners can sign "hello" in a quiz but can't hold a real conversation.
- **Privacy-invasive** — cloud-based recognition uploads your camera feed to process signing.

There is no accessible tool that both **teaches** realistic signing *and* **translates** your signing live, entirely on-device.

---

## 💡 Solution

LINGO closes the gap between *learning* and *communicating*:

**1. Real-time on-device sign recognition.** A pipeline of MediaPipe palm detection → hand landmark tracking → a custom **GRU(64) sequence classifier** (TFLite, ~245 KB) interprets a 24-frame sliding window of 21 hand landmarks. The model achieves **84.2% test accuracy** across 13 everyday signs.

**2. Graded practice.** The camera grades your signing with an instant **A–F letter grade** and AI coaching tips — so you get live feedback, not after-the-fact scoring.

**3. Communicate mode.** Perform any supported sign in sequence and LINGO builds a real phrase for you, turning the app into a two-way communication bridge.

**Everything runs on-device.** No camera frames ever leave your phone.

---

## ✨ Features

- 🔤 **ASL Alphabet & Numbers** — fingerspelling lessons for A–Z and 0–9 with reference images
- 📚 **Structured Curriculum** — Greetings, Everyday Basics, and Everyday Needs lessons with video guides, meanings, and performance tips
- 📷 **Live Camera Practice** — skeleton overlay over your hand in real time
- 🏅 **Instant AI Grading** — A+/A/B/C/D letter grades on every practiced sign
- 🗣️ **Communicate Mode** — free-form live sign-to-text phrase building
- 📈 **Progress Tracking** — XP, streaks, lessons completed, and signs learned
- 🏆 **Achievements** — gamified milestones to keep motivation high
- 🔐 **Accounts & Sync** — Firebase Authentication + Firestore profile storage
- 🌙 **Dark Mode** — full theming with light/dark support
- 🦉 **Mascot & Animations** — Lottie animations and an interactive learning mascot
- 📱 **100% On-device ML** — no cloud, fully private

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) |
| **State management** | flutter_riverpod |
| **Navigation** | go_router |
| **Camera** | camera (`camerax`) |
| **Hand tracking** | MediaPipe `hand_detection` (palm + landmark TFLite models) |
| **ML inference** | `flutter_litert` (TFLite Interpreter) |
| **Recognition model** | Custom GRU(64) sequence classifier — `lingo_sign_model.tflite` (~245 KB) |
| **Static sign model** | Custom static alphabet/number classifier TFLite model |
| **Auth & data** | Firebase Auth, Cloud Firestore, SharedPreferences |
| **Animation** | Lottie, flutter_animate |
| **Fonts** | google_fonts |
| **ML training** | Python, TensorFlow / Keras, NumPy |

---

## 📦 Installation Instructions

### Prerequisites
- **Flutter SDK** 3.12+ (stable channel)
- **Android Studio** with Android SDK (min SDK 24)
- A physical Android device (camera required) or Android emulator

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/diyeah13-wq/LINGO.git
cd LINGO

# 2. Get the Flutter dependencies
cd lingo
flutter pub get

# 3. Run the app (connects to your device/emulator)
flutter run

# 4. Build a debug APK
flutter build apk --debug

# 5. Or build a release APK
flutter build apk --release
```

> **Note:** Enable **camera permission** on your device when prompted. For best results use the **front camera** in a well-lit room with a plain background.

---

## 🎬 Demo Video

[▶️ Watch the demo](https://drive.google.com/file/d/1Rth9gZXqvl5CQupTC5ycgbX9kH5I6lMv/view?usp=sharing)

[📊 Presentation / PPT](https://docs.google.com/presentation/d/1mKLPSGenXRLEMWxmC_QnQTp7wPWHgGkL/edit?usp=sharing&ouid=112115224653715150009&rtpof=true&sd=true)

---

## 📲 APK Download

[⬇️ Download the APK from GitHub Releases](https://github.com/diyeah13-wq/LINGO/releases/latest)

---

## 🤖 AI Usage Disclosure

This project was developed with the assistance of AI-assisted development tools, including:

- **OpenCode** (interactive CLI coding agent)
- **ChatGPT** / **Gemini** (design & debugging support)

All AI-generated code was reviewed and understood by the team before submission, and every team member can explain the implementation during judging. AI tools were used to accelerate development — not to replace understanding of the project.

---

## 🛠️ Repository Structure

```
LINGO/
├── lingo/          Flutter mobile app (Android)
│   ├── lib/
│   │   ├── screens/    Home, Learn, Practice, Communicate, Auth, Settings
│   │   ├── services/   ML recognition pipeline (feature extractor, TFLite classifier, engine)
│   │   ├── data/       Lessons & model vocabulary catalog
│   │   └── widgets/    Mascot, XP badges, shared UI
│   └── assets/     Models, alphabet images, sign videos
├── ml_work/        Python ML pipeline (dataset → landmarks → GRU training → TFLite export)
└── ml/             MediaPipe task files & TFLite models
```

---

## 🏷️ Topic

Repository topic: **`appsprint-2025`**