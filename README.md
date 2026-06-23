# Pigeon 🐦

> **সংযোগ থাকুক হৃদয়ের** — Stay Connected at Heart

Pigeon is a modern, high-performance, and feature-rich social networking platform built with Flutter and Supabase. Engineered for buttery-smooth fluid scrolling (60fps+) and instant real-time data synchronization, Pigeon delivers a premium user experience akin to Twitter and Bluesky.

---

## 🚀 Key Highlights & Premium Features

### 📊 Realtime Polls System
- Create dynamic polls with 2-4 options and configurable expiration durations (1h, 6h, 24h, 3d, 7d).
- Instant real-time vote count updating and smooth sweeping progress animation powered by `TweenAnimationBuilder`.

### 🔐 End-to-End Encryption (E2EE)
- Secure, cryptographically verifiable chat system.
- Uses **ECDH Key Exchange** to establish shared secrets and **AES-GCM-256** to encrypt and decrypt messages locally on-device.

### 🟢 AI-Powered "For You" Feed
- Advanced native RPC candidate selection algorithm combining:
  - User Interest Category mapping (40%)
  - Friend & chat frequency relationship scoring (25%)
  - Trending metrics (15%)
  - Community/Group updates (10%)
  - Fresh creator discovery boost (10%)
- Live interaction signals logging (clicks, watch time, scrolls) to dynamically refine feeds.

### ⚡ Rocket Performance Boost
- **Lazy Loading Viewports:** Standard lists converted to recycling `ListView.builder` widgets with cache extent pre-rendering.
- **Repaint Boundaries:** Post cards wrapped in `RepaintBoundary` to isolate UI updates and likes pulses, avoiding screen-wide repaints.
- **Disk Caching:** Persistent image caching using `CachedNetworkImage` to eliminate duplicate network downloads during scrolling.
- **In-Memory Sync:** Optimized Supabase Realtime callbacks to update counts locally, reducing network database queries by 99%.

---

## 🎨 Design Philosophy
- **Brand Colors:** HSL-tailored premium color scheme featuring a signature Emerald Green brand accent (`#1E824C`).
- **Typography:** Hind Siliguri (Bengali) combined with Outfit and Inter (English).
- **Responsive Layout:** Beautiful transitions, haptic feedbacks, and fluid micro-animations.

---

## 🏗️ Technology Stack

```
Frontend Framework  : Flutter (Dart)
Backend & Database  : Supabase (PostgreSQL + RLS + Realtime)
State Management    : Provider + GetIt (Dependency Injection)
Cryptographic Suite : Cryptography Package (ECDH / AES-GCM-256)
Local Storage       : Flutter Secure Storage (Keys) & SharedPreferences (Configs)
Media & Caching     : CachedNetworkImage & Flutter Cache Manager
```

---

## 📁 Project Architecture

```
Pigeon/
├── lib/
│   ├── main.dart                    # App Entry Point & Initialization
│   ├── core/
│   │   ├── injection.dart           # GetIt Service Locator & DI
│   │   └── security/
│   │       └── e2ee_service.dart    # ECDH Key Exchange & AES-GCM-256 Cipher
│   ├── models/
│   │   ├── thread_post.dart         # Post & Poll model
│   │   ├── poll_option.dart         # Poll option model
│   │   ├── profile.dart             # User profile model
│   │   └── notification.dart        # Notification schema
│   ├── services/
│   │   ├── auth_service.dart        # Supabase Authentication & Demo Bypass
│   │   └── database_service.dart    # Optimized Database Access & Realtime Listeners
│   ├── screens/
│   │   ├── auth_screen.dart         # Multi-step signup & login flow
│   │   ├── feed_screen.dart         # Main Feed screen with lazy-loading list
│   │   ├── thread_detail_screen.dart# Nested comment sheets & poll details
│   │   ├── profile/
│   │   │   └── profile_screen.dart  # Multi-tab User profile
│   │   └── messenger/
│   │       └── chat_screen.dart     # E2EE enabled private messaging
│   └── widgets/
│       ├── custom_thread_card.dart  # Repaint-isolated post card
│       └── poll_widget.dart         # Animating progress-bar poll widget
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>= 3.12.1`
- Dart SDK `>= 3.0`
- Android Studio / VS Code
- A Supabase Project Instance

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/arafath306/gok.git
cd gok

# Get packages
flutter pub get

# Setup configurations
cp .env.example .env
# Populate .env with your SUPABASE_URL and SUPABASE_ANON_KEY

# Run the app
flutter run
```

### Offline / Demo Mode
To test the visual flows without database setup:
- Tap **"Enter Demo Mode"** on the login screen to instantiate local mock mocks.

---

## 🤝 Contributing
Pull requests are welcome! If you want to contribute, please fork the repository and use a branch for your feature.

## 📄 License
This project is licensed under the MIT License.

---
<p align="center">
  <strong>Made in Bangladesh 🇧🇩 by NGST</strong>
</p>
