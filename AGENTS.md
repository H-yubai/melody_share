# AGENTS.md

Flutter music player app (`app/`).

## App (`app/`)

- **Entry**: `lib/main.dart`
- **SDK**: `^3.9.2`, Material 3, `go_router`, `provider`, `media_kit` (not `just_audio`), `sqflite`, `audio_metadata_reader`, `dio`, `webview_flutter`, `lottie`, `permission_handler`, `flutter_localizations`, `toastification`（默认信息反馈方式）
- **Routes**: `/home`, `/higequ`, `/player`, `/group/:id`, `/developer` (defined in `lib/router/app_router.dart`)
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

## Known issues

- `app/test/widget_test.dart` is a basic smoke test only
- No CI workflows
