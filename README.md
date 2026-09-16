# Habitude (AI-Powered Fitness & Habit Intelligence)

> **Build Better. Move Better. Become Better.**

Habitude is a mobile application built with **Flutter** and on-device **Computer Vision Pose Detection** to track daily habits, movement, workouts, and progression analytics.

---

## 🌟 Key Features (Phase 01 – Phase 11 Complete)

- 📸 **On-Device AI Pose Detection:**
  - **Push-ups:** Real-time elbow angle tracking with form coaching.
  - **Squats:** Joint geometry (Hip-Knee-Ankle) state machine with depth verification.
  - **Plank:** Horizontal shoulder-hip-ankle alignment duration tracking.
  - **Jumping Jacks:** Coordinate-normalized arm elevation and foot spread ratio cycles.
- 🎯 **Daily Task & Habit Engine:**
  - Date-safe daily habit generation tailored to fitness level and primary goals.
  - Granular progress tracking, check-ins, and completion celebrations.
- ⚡ **Structured Workout Sessions:**
  - Multi-exercise guided workouts (Morning Energy, Strength Starter, Core & Stability).
  - Pre-countdown, rest intervals, and live HUD camera overlay.
- 🏆 **Gamification & Consistency:**
  - Level progression curve and transaction-based single-award XP engine.
  - Multi-category milestone achievements (Centurion, 7-Day Streak, Level 5).
  - Active daily streak engine with duplicate protection and best streak retention.
- 📊 **Progress Analytics & Smart Insights:**
  - 7-day, 30-day, and 90-day activity aggregation.
  - Custom zero-dependency activity bar chart with glow styling.
  - Step goal performance analysis and peak day tracking.
  - Adaptive exercise progression steppers and rule-based insights.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`

### Installation
```bash
git clone https://github.com/thekrishna7/habitudeapk.git
cd habitudeapk
flutter pub get
```

### Running Tests
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```

### Running the App
```bash
flutter run
```
