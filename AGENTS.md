# AGENTS.md

Monorepo with `app/` (Flutter) and `server/` (Rust/Axum).

## App (`app/`)

- **Entry**: `lib/main.dart`
- **SDK**: `^3.9.2`, Material 3, `go_router`, `provider`, `media_kit` (not `just_audio`), `sqflite`, `metadata_god`, `dio`, `webview_flutter`, `lottie`, `permission_handler`, `flutter_localizations`
- **Routes**: `/home`, `/upload`, `/player`, `/group/:id`, `/developer` (defined in `lib/router/app_router.dart`)
- **State**: `MusicHandler` (in `services/`; core `media_kit` Player + queue + ratings) + 6 providers in `lib/provider/`: `PlaylistProvider` (ChangeNotifier wrapper), `ThemeProvider`, `LocaleProvider` (default `zh`), `AnimationProvider`, `GroupProvider`, `DeveloperSettings` — wired via `MultiProvider` in `lib/app.dart`
- **Local DB**: SQLite via `sqflite` (`guangling.db`); tables: `song_groups`, `group_tracks`, `scanned_tracks`, `track_ratings`. Desktop uses `sqflite_common_ffi` fallback.
- **API**: `dio` via `ApiService` (initialized in `main.dart`); dynamic `baseUrl` from `DeveloperSettings`; long-press 广陵 title → `/developer` page to switch URL
- **Localization**: `l10n.yaml` → ARB files in `lib/l10n/` (`app_en.arb`, `app_zh.arb`); `flutter gen-l10n` generates `AppLocalizations`
- **Assets**: Lottie animations in `assets/animations/lottie/`; launcher icon / splash configured in `pubspec.yaml` via `flutter_launcher_icons` / `flutter_native_splash`
- **Notifications**: Android `MethodChannel('guangling/media_session')` in `MediaNotificationService`; `media_kit` libs handle platform audio focus
- **Permissions**: Android — `audio` / `storage` / `manageExternalStorage` / `notification`; iOS — `NSAppleMusicUsageDescription`
- **Test**: `flutter test` — single smoke test in `test/widget_test.dart` (uses `package:guangling/` imports)

| Action | Command |
|---|---|
| Analyze | `flutter analyze` |
| Format | `dart format .` |
| Test | `flutter test` |
| Run | `flutter run` |
| Gen l10n | `flutter gen-l10n` (auto-run by `flutter run`/`build`) |
| Gen icons | `dart run flutter_launcher_icons` |
| Gen splash | `dart run flutter_native_splash` |

## Server (`server/`)

- **Entry**: `src/main.rs`, Axum 0.8 + SQLx + PostgreSQL, Rust edition 2024
- **Config**: env vars — `DATABASE_URL` (required), `SERVER_HOST` (default `0.0.0.0`), `SERVER_PORT` (default `3000`); `.env` loaded via `dotenvy`
- **CORS**: permissive (no restrictions)
- **DB**: auto-creates tables on startup (`db.rs`): `tracks`, plus community tables — `users`, `sessions`, `playlists`, `playlist_tracks`, `follows`, `track_likes`, `comments`, `notifications`. Reference SQL in `server/sql/001_community_schema.sql`.
- **Routes**: `GET /` (index), `GET /api/tracks`, `GET /api/tracks/{id}`, `POST /api/upload`. Defined in `routes/mod.rs` + `routes/tracks.rs`.
- **Community API routes are NOT yet implemented** — only DB schema exists.
- **Uploads**: saved to `uploads/` dir (auto-created)
- Uses `tower-http` CORS, `tracing` + `tracing-subscriber` for logging
- **No tests**

| Action | Command |
|---|---|
| Check | `cargo check` |
| Lint | `cargo clippy` |
| Build | `cargo build` |
| Run | `cargo run` |
| Test | `cargo test` |

## Known issues

- Server has **no tests** and **no Docker Compose** for PostgreSQL — need a running PG instance for `cargo run`
- Community API routes are unimplemented (DB schema exists, no handlers)
- `app/test/widget_test.dart` is a basic smoke test only
- No CI workflows
