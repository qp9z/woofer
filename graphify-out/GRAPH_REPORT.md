# Graph Report - woofer  (2026-07-24)

## Corpus Check
- 47 files · ~63,409 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 753 nodes · 1022 edges · 50 communities (42 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5640605d`
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
- video_info.dart
- screens_test.dart
- glass_scaffold.dart
- _HomeScreenState
- aurora_background.dart
- GlassGalleryScreen
- GlassGalleryScreen
- glass_ui_test.dart
- MethodChannel
- ytdlp_extractor_test.dart
- package:flutter/cupertino.dart
- aurora_background.dart
- storage_service_test.dart
- library_tab.dart
- StatelessWidget
- media_processor_test.dart
- history_service_test.dart
- historyServiceProvider
- settings_tab.dart

## God Nodes (most connected - your core abstractions)
1. `MainActivity` - 13 edges
2. `DownloadState` - 11 edges
3. `downloadControllerProvider` - 10 edges
4. `DownloadController` - 7 edges
5. `_LibraryTabState` - 6 edges
6. `Flutter Framework` - 6 edges
7. `VideoInfo` - 5 edges
8. `ApiException` - 5 edges
9. `storageServiceProvider` - 5 edges
10. `historyServiceProvider` - 5 edges

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

## Communities (50 total, 8 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.05
Nodes (46): Animation, AnimationController, GlassGalleryScreen, _GlassGalleryScreenState, _IndeterminateStripe, _IndeterminateStripeState, _FadeIn, _FadeInState (+38 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.07
Nodes (26): active, _c, child, controller, createState, dim, dispose, fontSize (+18 more)

### Community 3 - "Home Page State"
Cohesion: 0.09
Nodes (22): _deleteQuietly, detail, _dir, _ext, FfmpegRun, MediaProcessor, mergeArgs, mergeContainer (+14 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.13
Nodes (15): _Badge, _CaptionLabel, _DetectedCard, _ErrorCard, _Hint, _InfoCircle, _ProgressBar, _Thumb (+7 more)

### Community 5 - "Android Host Activity"
Cohesion: 0.19
Nodes (7): MethodChannel, MainActivity, ProgressBridge, FlutterActivity, FlutterEngine, PyObject, Uri

### Community 13 - "StatelessWidget"
Cohesion: 0.18
Nodes (10): controller, firstUrl, initial, initialUrl, null, _pickUrl, dart:async, download_controller.dart (+2 more)

### Community 14 - "_download_to_file"
Cohesion: 0.04
Nodes (46): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, needsMerge (+38 more)

### Community 15 - "formats_screen.dart"
Cohesion: 0.13
Nodes (14): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+6 more)

### Community 16 - "ytdlp_extractor.dart"
Cohesion: 0.43
Nodes (7): _classify(), download(), _error(), extract_info(), yt-dlp bridge for the "ytdlp" MethodChannel.  Both entry points return a JSON *e, Download a single format to out_dir. `callback.onProgress(recv, total)` is     i, _video_info()

### Community 17 - "video_info.dart"
Cohesion: 0.06
Nodes (31): HistoryEntry, _brightness, build, createState, _gap, _isDark, _openSheet, _section (+23 more)

### Community 18 - "history_service.dart"
Cohesion: 0.08
Nodes (25): active, _audio, build, createState, enabled, _FormatSheet, _FormatSheetState, icon (+17 more)

### Community 19 - "history_screen.dart"
Cohesion: 0.06
Nodes (30): _bestAudio, build, cancel, _cancelled, _deleteDirQuietly, _deleteQuietly, download, _downloadFormat (+22 more)

### Community 20 - "glass_container.dart"
Cohesion: 0.07
Nodes (29): AlignmentGeometry?, duration, formats, fromJson, thumbnail, title, uploader, VideoInfo (+21 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.09
Nodes (22): appSubfolder, _channel, _defaultChannel, _ensurePermission, _invokeBool, isSuccess, message, openFile (+14 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.03
Nodes (63): a100, a200, a300, a400, a500, a600, a700, a800 (+55 more)

### Community 24 - "download_state.dart"
Cohesion: 0.05
Nodes (44): code, Done, Downloading, DownloadState, Failed, format, formats, FormatsReady (+36 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.07
Nodes (26): active, _c, child, createState, current, _defs, dispose, icon (+18 more)

### Community 26 - "progress_screen.dart"
Cohesion: 0.18
Nodes (10): _app, _info, main, main, package:flutter_riverpod/flutter_riverpod.dart, package:woofer/main.dart, package:woofer/models/media_format.dart, package:woofer/state/download_controller.dart (+2 more)

### Community 27 - "history_screen.dart"
Cohesion: 0.14
Nodes (13): bars, build, _MarkPainter, paint, shouldRepaint, size, tile, WooferBars (+5 more)

### Community 28 - "glass_ui_test.dart"
Cohesion: 0.33
Nodes (5): Build changes, Build-time requirement: Python 3.12, Caveats, Channel contract (`ytdlp`), On-device yt-dlp via Chaquopy

### Community 29 - "glass_button.dart"
Cohesion: 0.11
Nodes (17): blur, build, child, createState, _down, enableBlur, _enabled, expand (+9 more)

### Community 30 - "screens_test.dart"
Cohesion: 0.18
Nodes (10): api_exception.dart, _channel, download, extractInfo, _invoke, _onNativeCall, ytdlpErrorCode, YtdlpExtractor (+2 more)

### Community 31 - "video_info.dart"
Cohesion: 0.18
Nodes (10): build, child, _DesignSheetPanel, GlassSheet, _GlassSheetPanel, SheetGrabber, title, glass_container.dart (+2 more)

### Community 32 - "screens_test.dart"
Cohesion: 0.29
Nodes (5): main, main, package:flutter_test/flutter_test.dart, package:woofer/state/share_intent.dart, package:woofer/ui/format_utils.dart

### Community 33 - "glass_scaffold.dart"
Cohesion: 0.12
Nodes (16): _Blob, bottom, build, child, children, color, GlassBackground, GlassScaffold (+8 more)

### Community 35 - "aurora_background.dart"
Cohesion: 0.22
Nodes (9): downloadControllerProvider, sharedUrlProvider, _ActiveCard, build, _fetch, build, _openFormatSheet, _confirm (+1 more)

### Community 37 - "GlassGalleryScreen"
Cohesion: 0.10
Nodes (19): _audioOnly, download, downloaded, extractCalls, extractError, extractInfo, history, _info (+11 more)

### Community 38 - "glass_ui_test.dart"
Cohesion: 0.25
Nodes (7): _app, main, package:woofer/ui/theme/app_theme.dart, package:woofer/ui/widgets/glass_button.dart, package:woofer/ui/widgets/glass_container.dart, package:woofer/ui/widgets/glass_scaffold.dart, package:woofer/ui/widgets/glass_sheet.dart

### Community 40 - "ytdlp_extractor_test.dart"
Cohesion: 0.15
Nodes (12): main, channel, extractor, main, messenger, mockChannel, dart:convert, package:flutter/services.dart (+4 more)

### Community 41 - "package:flutter/cupertino.dart"
Cohesion: 0.29
Nodes (6): build, main, WooferApp, package:flutter/cupertino.dart, ui/screens/home_shell.dart, ui/theme/app_theme.dart

### Community 43 - "storage_service_test.dart"
Cohesion: 0.25
Nodes (7): channel, main, messenger, tmp, dart:io, File, package:woofer/services/storage_service.dart

### Community 44 - "library_tab.dart"
Cohesion: 0.33
Nodes (7): DownloadTab, _DownloadTabState, HomeShell, _HomeShellState, LibraryTab, ConsumerState, ConsumerStatefulWidget

### Community 45 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): _AboutSheet, build, fontSize, icon, label, _LegalButton, _LinkRow, onTap (+10 more)

### Community 46 - "media_processor_test.dart"
Cohesion: 0.22
Nodes (8): ApiException, dir, main, okRunner, touch, Directory, Exception, package:woofer/services/media_processor.dart

### Community 47 - "history_service_test.dart"
Cohesion: 0.22
Nodes (8): HistoryService, db, entry, main, svc, Database, package:sqflite_common_ffi/sqflite_ffi.dart, package:woofer/services/history_service.dart

### Community 49 - "historyServiceProvider"
Cohesion: 0.24
Nodes (11): DownloadController, historyListProvider, historyServiceProvider, mediaProcessorProvider, _recordHistory, storageServiceProvider, ytdlpExtractorProvider, build (+3 more)

### Community 50 - "settings_tab.dart"
Cohesion: 0.14
Nodes (13): build, _Group, icon, label, name, onTap, _Row, rows (+5 more)

## Knowledge Gaps
- **448 isolated node(s):** `main`, `build`, `ApiError`, `errorCode`, `message` (+443 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HistoryService` connect `history_service_test.dart` to `history_screen.dart`, `GlassGalleryScreen`, `_download_to_file`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `VideoInfo` connect `glass_container.dart` to `download_state.dart`, `history_service.dart`, `_error`, `history_screen.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `historyServiceProvider`, `_error`, `glass_scaffold.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `main`, `build`, `ApiError` to the rest of the system?**
  _448 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Counter App UI` be split into smaller, more focused modules?**
  _Cohesion score 0.05230496453900709 - nodes in this community are weakly interconnected._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._