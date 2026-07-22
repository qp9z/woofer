# Graph Report - woofer  (2026-07-23)

## Corpus Check
- 39 files · ~12,926 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 485 nodes · 649 edges · 27 communities (23 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1128cb5c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Counter App UI
- Flutter Project & Deps
- _error
- Home Page State
- formats_screen.dart
- Android Host Activity
- Launcher Icon (hdpi)
- Launcher Icon (mdpi)
- Launcher Icon (xhdpi)
- Launcher Icon (xxhdpi)
- StatelessWidget
- _download_to_file
- video_info.dart
- history_service.dart
- glass_container.dart
- api_error.dart
- config.dart
- app_theme.dart
- download_state.dart
- glass_scaffold.dart
- glass_button.dart
- glass_ui_test.dart
- GlassGalleryScreen
- StatelessWidget

## God Nodes (most connected - your core abstractions)
1. `downloadControllerProvider` - 11 edges
2. `DownloadState` - 10 edges
3. `MainActivity` - 7 edges
4. `Flutter Framework` - 6 edges
5. `storageServiceProvider` - 5 edges
6. `historyServiceProvider` - 5 edges
7. `_HomeScreenState` - 5 edges
8. `Failed` - 4 edges
9. `HistoryScreen` - 4 edges
10. `_MoreButton` - 4 edges

## Surprising Connections (you probably didn't know these)
- `App Launcher Icon (xxxhdpi) — Flutter Logo` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png → README.md
- `cupertino_icons Dependency` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  pubspec.yaml → README.md
- `flutter_lints Dev Dependency` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  pubspec.yaml → README.md
- `flutter_test Dev Dependency` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  pubspec.yaml → README.md
- `Material Design (uses-material-design)` --references--> `Flutter Framework`  [EXTRACTED]
  pubspec.yaml → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **woofer Package Dependencies** — pubspec_cupertino_icons, pubspec_flutter_lints, pubspec_flutter_test [INFERRED 0.75]
- **App Launcher Icon (resolution variants)** — android_app_src_main_res_mipmap_hdpi_ic_launcher, android_app_src_main_res_mipmap_mdpi_ic_launcher, android_app_src_main_res_mipmap_xhdpi_ic_launcher, android_app_src_main_res_mipmap_xxhdpi_ic_launcher, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher [EXTRACTED 1.00]

## Communities (27 total, 4 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.09
Nodes (23): api_exception.dart, close, download, extractInfo, mapYoutubeError, ProgressCallback, received, sink (+15 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.12
Nodes (15): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+7 more)

### Community 3 - "Home Page State"
Cohesion: 0.12
Nodes (15): describeError, digits, formatBytes, formatDate, formatDuration, h, m, months (+7 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.20
Nodes (9): build, child, GlassSheet, _GlassSheetPanel, title, glass_container.dart, T, ../theme/app_theme.dart (+1 more)

### Community 5 - "Android Host Activity"
Cohesion: 0.27
Nodes (5): MainActivity, FlutterActivity, FlutterEngine, MethodChannel, Uri

### Community 13 - "StatelessWidget"
Cohesion: 0.40
Nodes (6): GlassGalleryScreen, _GlassGalleryScreenState, GlassButton, _GlassButtonState, State, StatefulWidget

### Community 14 - "_download_to_file"
Cohesion: 0.07
Nodes (26): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, needsMerge (+18 more)

### Community 17 - "video_info.dart"
Cohesion: 0.06
Nodes (41): HistoryEntry, _brightness, build, createState, _gap, _isDark, _openSheet, _section (+33 more)

### Community 18 - "history_service.dart"
Cohesion: 0.06
Nodes (30): add, clear, createdAt, _createTableSql, _db, delete, filePath, format (+22 more)

### Community 20 - "glass_container.dart"
Cohesion: 0.07
Nodes (28): AlignmentGeometry?, duration, formats, fromJson, thumbnail, title, uploader, VideoInfo (+20 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.07
Nodes (27): appSubfolder, _channel, _defaultChannel, _ensurePermission, _invokeBool, isSuccess, message, openFile (+19 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.07
Nodes (28): accent, AppBackground, AppColors, AppGlass, AppRadius, AppSpacing, AppTheme, blobA (+20 more)

### Community 24 - "download_state.dart"
Cohesion: 0.11
Nodes (22): DownloadController, code, Done, Downloading, DownloadState, Failed, format, formats (+14 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.05
Nodes (44): _Chip, _HeaderCard, _Thumbnail, _Caption, controller, createState, dispose, _ErrorCard (+36 more)

### Community 29 - "glass_button.dart"
Cohesion: 0.11
Nodes (18): blur, build, child, createState, _down, enableBlur, _enabled, expand (+10 more)

### Community 31 - "glass_ui_test.dart"
Cohesion: 0.05
Nodes (35): build, main, WooferApp, main, _app, main, main, main (+27 more)

### Community 36 - "GlassGalleryScreen"
Cohesion: 0.08
Nodes (22): detectPlatform, _domains, Extractor, host, routeFor, SourcePlatform, trimmed, uri (+14 more)

### Community 38 - "StatelessWidget"
Cohesion: 0.08
Nodes (31): StorageService, build, cancel, download, downloadControllerProvider, extract, getAll, history (+23 more)

## Knowledge Gaps
- **270 isolated node(s):** `main`, `build`, `ApiError`, `errorCode`, `message` (+265 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HistoryService` connect `history_service.dart` to `StatelessWidget`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `video_info.dart`, `glass_scaffold.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `downloadControllerProvider` connect `StatelessWidget` to `glass_scaffold.dart`, `GlassGalleryScreen`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `main`, `build`, `ApiError` to the rest of the system?**
  _270 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Counter App UI` be split into smaller, more focused modules?**
  _Cohesion score 0.08666666666666667 - nodes in this community are weakly interconnected._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._