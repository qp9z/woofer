# Graph Report - woofer  (2026-07-23)

## Corpus Check
- 35 files · ~11,505 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 450 nodes · 603 edges · 32 communities (28 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `03c73395`
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
- history_screen.dart
- progress_screen.dart
- video_info.dart
- history_service.dart
- json_parsing_test.dart
- glass_container.dart
- api_error.dart
- config.dart
- app_theme.dart
- download_state.dart
- glass_scaffold.dart
- glass_list_tile.dart
- glass_sheet.dart
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

## Communities (32 total, 4 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.18
Nodes (9): build, main, WooferApp, main, package:flutter/cupertino.dart, package:flutter_riverpod/flutter_riverpod.dart, package:woofer/main.dart, ui/screens/home_screen.dart (+1 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.14
Nodes (13): controller, createState, dispose, onPaste, onSubmit, _paste, state, text (+5 more)

### Community 3 - "Home Page State"
Cohesion: 0.12
Nodes (15): describeError, digits, formatBytes, formatDate, formatDuration, h, m, months (+7 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.17
Nodes (11): format, _h, info, label, selected, _subtitle, _Thumbnail, url (+3 more)

### Community 5 - "Android Host Activity"
Cohesion: 0.27
Nodes (5): MainActivity, FlutterActivity, FlutterEngine, MethodChannel, Uri

### Community 13 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): _Badges, _Chip, _HeaderCard, _Thumb, _Caption, _ErrorCard, _Hint, _SharedBanner (+4 more)

### Community 14 - "_download_to_file"
Cohesion: 0.08
Nodes (24): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, note (+16 more)

### Community 15 - "history_screen.dart"
Cohesion: 0.18
Nodes (10): HistoryEntry, _EmptyState, entry, _h, _meta, url, _w, ../../state/download_controller.dart (+2 more)

### Community 16 - "progress_screen.dart"
Cohesion: 0.22
Nodes (8): _Bar, _IdleCard, progress, state, ../format_utils.dart, ../../state/download_state.dart, ../widgets/glass_container.dart, ../widgets/glass_scaffold.dart

### Community 17 - "video_info.dart"
Cohesion: 0.14
Nodes (13): _brightness, build, createState, _gap, _isDark, _openSheet, _section, _toggle (+5 more)

### Community 18 - "history_service.dart"
Cohesion: 0.06
Nodes (30): add, clear, createdAt, _createTableSql, _db, delete, filePath, format (+22 more)

### Community 19 - "json_parsing_test.dart"
Cohesion: 0.40
Nodes (6): GlassGalleryScreen, _GlassGalleryScreenState, GlassButton, _GlassButtonState, State, StatefulWidget

### Community 20 - "glass_container.dart"
Cohesion: 0.07
Nodes (28): AlignmentGeometry?, duration, formats, fromJson, thumbnail, title, uploader, VideoInfo (+20 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.07
Nodes (29): appSubfolder, _channel, _defaultChannel, _ensurePermission, _invokeBool, isSuccess, message, openFile (+21 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.07
Nodes (28): accent, AppBackground, AppColors, AppGlass, AppRadius, AppSpacing, AppTheme, blobA (+20 more)

### Community 24 - "download_state.dart"
Cohesion: 0.11
Nodes (22): DownloadController, code, Done, Downloading, DownloadState, Failed, format, formats (+14 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.12
Nodes (16): bottom, build, child, children, color, GlassBackground, GlassScaffold, leading (+8 more)

### Community 26 - "glass_list_tile.dart"
Cohesion: 0.12
Nodes (15): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+7 more)

### Community 27 - "glass_sheet.dart"
Cohesion: 0.20
Nodes (9): build, child, GlassSheet, _GlassSheetPanel, title, glass_container.dart, T, ../theme/app_theme.dart (+1 more)

### Community 29 - "glass_button.dart"
Cohesion: 0.11
Nodes (18): blur, build, child, createState, _down, enableBlur, _enabled, expand (+10 more)

### Community 31 - "glass_ui_test.dart"
Cohesion: 0.08
Nodes (24): main, _app, main, main, _app, _info, main, main (+16 more)

### Community 36 - "GlassGalleryScreen"
Cohesion: 0.11
Nodes (18): controller, firstUrl, initial, initialUrl, null, _pickUrl, sharedUrlProvider, build (+10 more)

### Community 38 - "StatelessWidget"
Cohesion: 0.08
Nodes (31): StorageService, build, cancel, download, downloadControllerProvider, extract, getAll, history (+23 more)

## Knowledge Gaps
- **246 isolated node(s):** `main`, `build`, `ApiError`, `errorCode`, `message` (+241 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HistoryService` connect `history_service.dart` to `StatelessWidget`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `_error`, `formats_screen.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `downloadControllerProvider` connect `StatelessWidget` to `GlassGalleryScreen`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `main`, `build`, `ApiError` to the rest of the system?**
  _246 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `_download_to_file` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._