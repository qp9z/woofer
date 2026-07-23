# Graph Report - woofer  (2026-07-23)

## Corpus Check
- 42 files · ~59,305 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 564 nodes · 781 edges · 44 communities (39 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b5433032`
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
- formats_screen.dart
- ytdlp_extractor.dart
- video_info.dart
- history_service.dart
- history_screen.dart
- glass_container.dart
- api_error.dart
- config.dart
- app_theme.dart
- download_state.dart
- glass_scaffold.dart
- progress_screen.dart
- history_screen.dart
- glass_ui_test.dart
- glass_button.dart
- screens_test.dart
- DownloadController
- screens_test.dart
- glass_scaffold.dart
- _HomeScreenState
- package:flutter/cupertino.dart
- GlassGalleryScreen
- GlassGalleryScreen
- MethodChannel
- ytdlp_extractor_test.dart
- glass_ui_test.dart
- media_processor_test.dart
- storage_service_test.dart
- media_processor_test.dart

## God Nodes (most connected - your core abstractions)
1. `MainActivity` - 13 edges
2. `downloadControllerProvider` - 11 edges
3. `DownloadState` - 11 edges
4. `DownloadController` - 7 edges
5. `historyServiceProvider` - 7 edges
6. `storageServiceProvider` - 6 edges
7. `Flutter Framework` - 6 edges
8. `ApiException` - 5 edges
9. `Failed` - 5 edges
10. `_HomeScreenState` - 5 edges

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

## Communities (44 total, 5 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.24
Nodes (12): downloadControllerProvider, sharedUrlProvider, build, FormatsScreen, build, _fetch, _DoneCard, _FailedCard (+4 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.12
Nodes (15): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+7 more)

### Community 3 - "Home Page State"
Cohesion: 0.06
Nodes (30): api_exception.dart, _deleteQuietly, detail, _dir, FfmpegRun, MediaProcessor, mergeArgs, mergeVideoAudio (+22 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.20
Nodes (9): build, child, GlassSheet, _GlassSheetPanel, title, glass_container.dart, T, ../theme/app_theme.dart (+1 more)

### Community 5 - "Android Host Activity"
Cohesion: 0.19
Nodes (7): MethodChannel, MainActivity, ProgressBridge, FlutterActivity, FlutterEngine, PyObject, Uri

### Community 13 - "StatelessWidget"
Cohesion: 0.20
Nodes (9): build, _IdleCard, _ProcessingCard, progress, state, ../format_utils.dart, ../../state/download_controller.dart, ../../state/download_state.dart (+1 more)

### Community 14 - "_download_to_file"
Cohesion: 0.08
Nodes (24): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, needsMerge (+16 more)

### Community 15 - "formats_screen.dart"
Cohesion: 0.15
Nodes (12): _Badges, format, _h, _HeaderCard, info, label, selected, _subtitle (+4 more)

### Community 16 - "ytdlp_extractor.dart"
Cohesion: 0.43
Nodes (7): _classify(), download(), _error(), extract_info(), yt-dlp bridge for the "ytdlp" MethodChannel.  Both entry points return a JSON *e, Download a single format to out_dir. `callback.onProgress(recv, total)` is     i, _video_info()

### Community 17 - "video_info.dart"
Cohesion: 0.10
Nodes (20): _brightness, build, createState, _gap, GlassGalleryScreen, _GlassGalleryScreenState, _isDark, _openSheet (+12 more)

### Community 18 - "history_service.dart"
Cohesion: 0.07
Nodes (29): add, clear, createdAt, _createTableSql, _db, delete, filePath, format (+21 more)

### Community 19 - "history_screen.dart"
Cohesion: 0.07
Nodes (26): _bestAudio, build, cancel, _cancelled, _deleteQuietly, download, _downloadFormat, extract (+18 more)

### Community 20 - "glass_container.dart"
Cohesion: 0.07
Nodes (28): AlignmentGeometry?, duration, formats, fromJson, thumbnail, title, uploader, VideoInfo (+20 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.08
Nodes (23): appSubfolder, _channel, _defaultChannel, _ensurePermission, _invokeBool, isSuccess, message, openFile (+15 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.06
Nodes (32): accent, AppBackground, AppColors, AppGlass, AppRadius, AppSpacing, AppTheme, blobA (+24 more)

### Community 24 - "download_state.dart"
Cohesion: 0.11
Nodes (22): code, Done, Downloading, DownloadState, Failed, format, formats, FormatsReady (+14 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.14
Nodes (13): controller, createState, dispose, onPaste, onSubmit, _paste, state, text (+5 more)

### Community 26 - "progress_screen.dart"
Cohesion: 0.18
Nodes (11): _Chip, _Thumbnail, _Caption, _ErrorCard, _Hint, _SharedBanner, _UrlField, _Bar (+3 more)

### Community 27 - "history_screen.dart"
Cohesion: 0.15
Nodes (13): HistoryEntry, historyListProvider, build, _EmptyState, entry, _h, HistoryScreen, _meta (+5 more)

### Community 28 - "glass_ui_test.dart"
Cohesion: 0.33
Nodes (5): Build changes, Build-time requirement: Python 3.12, Caveats, Channel contract (`ytdlp`), On-device yt-dlp via Chaquopy

### Community 29 - "glass_button.dart"
Cohesion: 0.11
Nodes (18): blur, build, child, createState, _down, enableBlur, _enabled, expand (+10 more)

### Community 30 - "screens_test.dart"
Cohesion: 0.15
Nodes (12): main, _app, _info, main, dart:convert, package:woofer/models/api_error.dart, package:woofer/models/media_format.dart, package:woofer/models/video_info.dart (+4 more)

### Community 31 - "DownloadController"
Cohesion: 0.24
Nodes (10): DownloadController, historyServiceProvider, mediaProcessorProvider, _recordHistory, storageServiceProvider, ytdlpExtractorProvider, _confirmClear, _MoreButton (+2 more)

### Community 32 - "screens_test.dart"
Cohesion: 0.29
Nodes (5): main, main, package:flutter_test/flutter_test.dart, package:woofer/state/share_intent.dart, package:woofer/ui/format_utils.dart

### Community 33 - "glass_scaffold.dart"
Cohesion: 0.12
Nodes (16): _Blob, bottom, build, child, children, color, GlassBackground, leading (+8 more)

### Community 34 - "_HomeScreenState"
Cohesion: 0.50
Nodes (4): HomeScreen, _HomeScreenState, ConsumerState, ConsumerStatefulWidget

### Community 35 - "package:flutter/cupertino.dart"
Cohesion: 0.29
Nodes (6): build, main, WooferApp, package:flutter/cupertino.dart, ui/screens/home_screen.dart, ui/theme/app_theme.dart

### Community 36 - "GlassGalleryScreen"
Cohesion: 0.14
Nodes (12): controller, firstUrl, initial, initialUrl, null, _pickUrl, main, download_controller.dart (+4 more)

### Community 37 - "GlassGalleryScreen"
Cohesion: 0.10
Nodes (19): _audioOnly, download, downloaded, extractCalls, extractError, extractInfo, history, _info (+11 more)

### Community 40 - "ytdlp_extractor_test.dart"
Cohesion: 0.25
Nodes (7): channel, extractor, main, messenger, mockChannel, dart:async, package:woofer/services/ytdlp_extractor.dart

### Community 41 - "glass_ui_test.dart"
Cohesion: 0.25
Nodes (7): _app, main, package:woofer/ui/theme/app_theme.dart, package:woofer/ui/widgets/glass_button.dart, package:woofer/ui/widgets/glass_container.dart, package:woofer/ui/widgets/glass_scaffold.dart, package:woofer/ui/widgets/glass_sheet.dart

### Community 42 - "media_processor_test.dart"
Cohesion: 0.12
Nodes (15): describeError, digits, formatBytes, formatDate, formatDuration, h, m, months (+7 more)

### Community 43 - "storage_service_test.dart"
Cohesion: 0.25
Nodes (7): channel, main, messenger, tmp, File, package:flutter/services.dart, package:woofer/services/storage_service.dart

### Community 46 - "media_processor_test.dart"
Cohesion: 0.20
Nodes (9): ApiException, dir, main, okRunner, touch, dart:io, Directory, Exception (+1 more)

## Knowledge Gaps
- **313 isolated node(s):** `main`, `build`, `ApiError`, `errorCode`, `message` (+308 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HistoryService` connect `history_service.dart` to `history_screen.dart`, `GlassGalleryScreen`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Why does `ApiException` connect `media_processor_test.dart` to `ytdlp_extractor_test.dart`, `GlassGalleryScreen`, `_download_to_file`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `glass_scaffold.dart`, `formats_screen.dart`, `DownloadController`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `main`, `build`, `ApiError` to the rest of the system?**
  _313 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.0625 - nodes in this community are weakly interconnected._
- **Should `_download_to_file` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._