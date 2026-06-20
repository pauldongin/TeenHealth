# TeenHealth

A research-backed iOS app designed to help teenagers (ages 13–17) build healthier habits — as a supplement to clinical care, not a replacement.

---

## Overview

TeenHealth was built around four principles from adolescent obesity prevention research:

- **Self-monitoring works** — teens who log meals and activity consistently see better outcomes
- **Autonomy matters** — goals should be chosen by the teen, not imposed
- **Small wins drive streaks** — gamification (points, badges, streaks) maintains engagement
- **Coach relationships help** — a supportive coach voice improves adherence

The app targets the lifestyle factors most supported by evidence: meal logging, daily movement, hydration, and sleep — without ever showing calorie deficits or weight-loss framing.

---

## Screenshots

<img src="screenshots/today.png" width="300" alt="Today Dashboard" />

> More screenshots coming soon — some features are currently being refined and fixed.

---

## Features

### Onboarding
- COPPA-compliant parental consent + teen assent flow before any data is collected
- Custom avatar creation (skin tone, hair color, glasses, outfit style & color)
- Swipe-lock: can't advance past required fields

### Today Dashboard
- Daily summary: steps, meals logged, water, sleep
- Progress rings for each active goal
- Points and streak display
- Quick-log shortcuts

### Food Log
- Photo logging, quick-pick favorites, and manual search
- Weekly calendar strip to browse past days
- Meal-by-meal breakdown (breakfast, lunch, dinner, snack)

### Goals
- Research-backed starter goals (2 meals/day, 5,000 steps, 6 glasses of water)
- Fully customizable — teens set their own targets
- Progress bars with completion states

### Coach
- Chat interface with "Coach Alex"
- Encouragement-focused, non-restrictive messaging
- Typing indicator, message timestamps, read receipts

### Progress
- Weekly and monthly charts for steps, meals, water, sleep, and weight
- Badge collection (earned for streaks, logging milestones, etc.)
- Points history and level progression

### Learn
- Education cards on nutrition, movement, sleep, and mental wellness
- Evidence-based content written for a teen audience

### Settings
- Profile editing and avatar customization
- Notification preferences (meal reminders, step reminders, weigh-in reminders)
- HealthKit permissions
- Data deletion

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM |
| Persistence | SwiftData (on-device only, no iCloud) |
| Health data | HealthKit (steps, active energy, sleep, weight) |
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

4. **Open in Xcode**
   ```bash
   open TeenHealth.xcodeproj
   ```

5. **Set your Development Team** in Xcode → Target → Signing & Capabilities, then run on a device or simulator with **Cmd+R**

---

## Privacy & Data

- All data is stored **on-device only** — nothing is sent to a server
- No ads, no data selling
- Parental consent is required before the app collects any information
- Users can delete all data at any time from Settings

---

## Disclaimer

TeenHealth is a wellness tracking tool intended to **supplement** — not replace — care from a qualified healthcare provider. Always work with your medical team when making decisions about your health.

---

## License

MIT
