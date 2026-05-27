# AGENTS.md

## Repo structure

Monorepo with two independent packages:

- **`app/`** — Flutter mobile app (Dart, SDK `^3.9.2`)
  - Entry: `lib/main.dart` → `MelodyShareApp`
  - Router: `go_router` (`/`, `/upload`, `/player/:id`)
  - API base URL hardcoded to `http://10.0.2.2:3000` (Android emulator → host)
  - Local music scanning via `LocalMusicService` (app bar scan icon)
  - Playback via `just_audio` managed by `PlaylistProvider` singleton
  - State: `ThemeProvider` + `PlaylistProvider` (both simple `ChangeNotifier` singletons)
  - Platform permissions: `READ_EXTERNAL_STORAGE` (Android ≤12) / `READ_MEDIA_AUDIO` (Android 13+) in `AndroidManifest.xml`; `NSAppleMusicUsageDescription` in iOS `Info.plist`

- **`server/`** — Rust API server (Axum 0.8 + SQLx + PostgreSQL)
  - Entry: `src/main.rs` → `#[tokio::main]`
  - Auto-creates `tracks` table on startup
  - Config via env vars (`DATABASE_URL` required, `SERVER_HOST`/`SERVER_PORT` optional)
  - CORS: permissive (no restrictions)
  - Uploaded files saved to `uploads/` dir

## Commands

### App (`app/`)

| Action | Command |
|---|---|
| Analyze | `flutter analyze` |
| Format | `dart format .` |
| Test | `flutter test` |
| Run | `flutter run` |

### Server (`server/`)

| Action | Command |
|---|---|
| Check | `cargo check` |
| Build | `cargo build` |
| Run | `cargo run` |
| Test | `cargo test` |

## Known issues

- `app/test/widget_test.dart` was fixed to be a basic smoke test (no longer the broken counter template).
- The server has **no tests** at all.
- No CI workflows or Docker Compose for the database.
