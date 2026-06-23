# Melody Share (广陵)

跨平台音乐播放器，支持本地播放和歌单管理。
Cross-platform music player with local playback and playlist management.

---

## 技术栈 / Tech Stack

### 应用端 / App (`app/`)

| 层级 / Layer | 技术 / Technology |
|---|---|
| 语言 Language | Dart (SDK ^3.9.2) |
| 框架 Framework | Flutter (Material 3) |
| 路由 Routing | `go_router`（声明式路由：`/home`、`/upload`、`/player`、`/group/:id`、`/developer`） |
| 状态管理 State | `provider`（6 个 ChangeNotifier：`ThemeProvider`、`LocaleProvider`、`AnimationProvider`、`DeveloperSettings`、`PlaylistProvider`、`GroupProvider`） |
| 音频 Audio | `media_kit`（核心 Player + 播放队列 + 评分） |
| 本地数据库 Local DB | `sqflite` / `sqflite_common_ffi`（SQLite，数据库文件 `guangling.db`） |
| HTTP 请求 HTTP | `dio`（通过 `ApiService` 封装，支持动态切换 base URL） |
| 元数据 Metadata | `metadata_god`（读取音频标签信息） |
| 歌词显示 Lyrics | `flutter_lyric` |
| 通知 Notifications | `flutter_local_notifications` + Android `MethodChannel('guangling/media_session')` |
| 动效 Lottie | `lottie`（动效文件位于 `assets/animations/lottie/`） |
| 权限 Permissions | `permission_handler` |
| 国际化 i18n | Flutter ARB（`app_en.arb`、`app_zh.arb`），默认语言 `zh` |
| 文件选择 File picker | `file_picker` |
| 图标 Icons | `phosphor_flutter` |
| WebView | `webview_flutter` |
| 启动图标 Launcher | `flutter_launcher_icons` |
| 启动屏 Splash | `flutter_native_splash` |

---

## 系统架构 / System Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Melody Share App                    │
│                      (Flutter)                        │
├──────────────────────────────────────────────────────┤
│                        UI 层 / UI Layer               │
│  HomePage | UploadPage | PlayerPage | GroupDetail    │
├──────────────────────────────────────────────────────┤
│                  状态管理 / State (provider)           │
│  ThemeProvider  LocaleProvider  AnimationProvider     │
│  DeveloperSettings  PlaylistProvider  GroupProvider   │
├──────────────────────────────────────────────────────┤
│                   服务层 / Services                   │
│  MusicHandler   ApiService   DatabaseService          │
│  LocalMusicService   LyricsService                    │
│  MediaNotificationService   MediaStoreScanner         │
├──────────────────────────────────────────────────────┤
│                   数据层 / Data Layer                  │
│  SQLite (guangling.db)        Dio (REST API)          │
│  ┌─ song_groups              ┌─ GET  /api/tracks     │
│  ├─ group_tracks             ├─ GET  /api/tracks/:id │
│  ├─ scanned_tracks           └─ POST /api/upload     │
│  └─ track_ratings                                     │
└──────────────────────────────────────────────────────┘
```

### 数据流 / Data Flow

1. **本地扫描 / Local Scan**：`metadata_god` 扫描设备音频文件 → 存入 `scanned_tracks` 表
2. **分组管理 / Grouping**：创建歌单（`song_groups`）→ 将曲目加入分组（`group_tracks`）
3. **播放 / Playback**：`MusicHandler` 通过 `media_kit` `Player` 播放本地文件，支持循环/随机/评分加权随机模式
4. **配置 / Config**：长按顶栏"广陵"标题进入开发者页面，动态修改服务端地址（若部署了可选后端）

---

## 应用使用说明 / App Usage

### 路由页面 / Routes

| 路径 Path | 页面 Page | 说明 Description |
|---|---|---|
| `/` | `HomePage` | 首页：浏览已扫描曲目、歌单、播放队列 |
| `/upload` | `UploadPage` | 上传页面：上传音乐至可选后端 |
| `/player` | `PlayerPage` | 播放页面：正在播放、控制按钮、歌词、评分 |
| `/group/:id` | `GroupDetailPage` | 歌单详情：查看/编辑分组内的曲目列表 |
| `/developer` | `DeveloperPage` | 开发者设置：修改服务端地址（长按标题进入） |

### 播放模式 / Playback Modes

通过播放器界面循环切换 / Cycled via player UI：

`无循环 No Repeat` → `列表循环 Repeat All` → `单曲循环 Repeat One` → `随机播放 Shuffle`（按评分加权 / weighted by rating）

### 国际化 / Localization

默认语言 **中文 (zh)**，支持中英文切换。通过 `LocaleProvider` 控制。
Default is **Chinese (zh)**, with English support. Toggle via `LocaleProvider`.

---

## 命令 / Commands

### 应用端 / App

```bash
flutter analyze              # 静态分析 / Static analysis
dart format .                # 格式化代码 / Format code
flutter test                 # 运行测试 / Run tests
flutter run                  # 运行应用 / Run app
flutter gen-l10n             # 生成本地化代码 / Generate localizations（run/build 时自动执行）
dart run flutter_launcher_icons    # 生成启动图标 / Generate launcher icons
dart run flutter_native_splash     # 生成启动屏 / Generate splash screen
```

---

## 已知问题 / Known Issues

- 仅有一个基础冒烟测试 `app/test/widget_test.dart` / Only a single basic smoke test exists
- 无 CI 工作流 / No CI workflows configured
