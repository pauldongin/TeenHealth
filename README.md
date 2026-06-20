# TeenHealth

> A research-backed iOS app helping teenagers (ages 13–17) build healthier habits — one small win at a time.

TeenHealth is designed as a **supplement to clinical care**, not a replacement. It focuses on the lifestyle factors most supported by adolescent health research: meal logging, daily movement, hydration, and sleep — without calorie counting, dieting, or weight-loss framing.

---

## Screenshots

<p float="left">
  <img src="screenshots/today.png" width="250" alt="Today Dashboard" />
  &nbsp;&nbsp;&nbsp;
  <img src="screenshots/progress.png" width="250" alt="Progress & Levels" />
</p>

**Left:** The Today dashboard shows active goals with progress rings, a daily summary (steps, active energy, sleep), a motivational message from Coach Alex, and a quick meal log button.

**Right:** The Progress tab tracks weekly steps and meals with bar charts, shows the user's current level and points (Seedling → Sprout → ...), and displays earned badges. HealthKit data is pulled automatically.

> More screenshots coming — some features are still being refined.

---

## Why This App?

Most health apps for teenagers either treat them like adults (calorie deficits, BMI tracking) or feel too childish to take seriously. TeenHealth is built around four evidence-based principles:

- **Self-monitoring works** — consistent meal and activity logging is one of the strongest predictors of healthy habit formation in adolescents
- **Autonomy matters** — goals are chosen by the teen, not imposed by the app or a parent
- **Small wins drive engagement** — a gamification system (points, levels, badges, streaks) keeps teens coming back without pressure
- **Coach relationships help** — a supportive, non-judgmental AI coach provides real-time encouragement and guidance

---

## Features

### Onboarding
- COPPA-compliant parental consent + teen assent flow before any data is collected
- Custom emoji avatar with personalized background color
- Swipe-lock: required fields must be filled before advancing

### Today Dashboard
- Personalized greeting with the user's avatar
- Progress rings for each active goal — turn green with a checkmark when completed
- Quick stats: steps, active energy, sleep (pulled from HealthKit)
- Daily meal log timeline
- One-tap "Log a Meal" button

### Food Log
- Photo logging, quick-pick favorites, and manual search
- Weekly calendar strip to browse past days
- Organized by meal type (breakfast, lunch, dinner, snack)

### Goals
- 3 research-backed starter goals auto-created on signup (2 meals/day, 5,000 steps, 6 glasses of water)
- Fully customizable — teens set their own targets
- Visual progress bars with completion states

### AI Coach
- Real conversations with **Coach Alex**, powered by **Groq (Llama 3.3 70B)**
- Context-aware replies — the coach remembers the last 10 messages
- Encouraging, non-restrictive tone. Never mentions calories, weight, or dieting.
- Typing indicator and message timestamps

### Progress
- Weekly bar charts for steps and meals logged (HealthKit-integrated)
- Level progression system: Seedling → Sprout → ... with point milestones
- Badge collection earned through streaks, logging, and first messages

### Profile
- Avatar and display name
- Links to Progress, Learn, and Settings in one place

### Learn
- Education cards on nutrition, movement, sleep, and mental wellness
- Evidence-based content written for a teen audience

### Settings
- Profile and avatar editing
- Notification preferences (meal, step, and weigh-in reminders)
- HealthKit permissions management
- Full data deletion

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM |
| Persistence | SwiftData (on-device only, no iCloud) |
| Health data | HealthKit (steps, active energy, sleep, weight) |
| AI Coach | Groq API — Llama 3.3 70B |
| Notifications | UserNotifications |
| Project generation | XcodeGen |

---

## Requirements

- iOS 17.0+
- Xcode 15+
- A physical iPhone or iOS Simulator

---

## Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/pauldongin/TeenHealth.git
   cd TeenHealth
   ```

2. **Install XcodeGen** (if not already installed)
   ```bash
   brew install xcodegen
   ```

3. **Generate the Xcode project**
   ```bash
   xcodegen generate
   ```

4. **Add your Groq API key**

   Create `TeenHealth/Secrets.swift` (this file is gitignored):
   ```swift
   enum Secrets {
       static let groqAPIKey = "YOUR_GROQ_API_KEY"
   }
   ```
   Get a free key at [console.groq.com](https://console.groq.com)

5. **Open in Xcode**
   ```bash
   open TeenHealth.xcodeproj
   ```

6. **Set your Development Team** in Xcode → Target → Signing & Capabilities, then run with **Cmd+R**

---

## Privacy & Data

- All personal data is stored **on-device only** — nothing is sent to a third-party server
- Coach messages go to Groq's API for AI processing only — no data is stored or sold
- Parental consent is required before any data is collected (COPPA-aware flow)
- Users can delete all their data at any time from Settings

---

## Availability

Currently available in **developer mode only** — the app must be built and installed via Xcode directly onto your device. Not yet on the App Store.

---

## Disclaimer

TeenHealth is a wellness tracking tool intended to **supplement** — not replace — care from a qualified healthcare provider. Always consult your medical team when making decisions about your health.

---

## License

© 2026 Paul Son. All Rights Reserved.

This project is publicly visible for portfolio purposes. You may not copy, distribute, modify, or use any part of this code without explicit written permission from the author.
