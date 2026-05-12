# SuperTutor App

Flutter client for SuperTutor AI — multilingual AI tutor with avatar chat.

## Setup

```powershell
flutter pub get
Copy-Item .env.example .env
flutter run            # Android emulator or device
flutter run -d chrome  # web
```

## Backend connection

This app talks to the FastAPI backend at `API_BASE_URL` (see `.env`).
- Android emulator default: `http://10.0.2.2:8000` (host loopback)
- Web: `http://localhost:8000`
- iOS simulator: `http://localhost:8000`

## Stack

- **State** — Riverpod
- **Routing** — go_router
- **HTTP** — Dio
- **Auth + DB** — supabase_flutter
- **Audio** — record (mic) + just_audio (playback)
- **Avatar** — placeholder; swap with Lottie animation later

## Free build & distribution

- Android: `flutter build apk --release` → direct APK install (no Play Store fee)
- Web: `flutter build web` → deploy on Cloudflare Pages / Vercel / GitHub Pages
- iOS: needs $99/year Apple Developer account; postpone for now
