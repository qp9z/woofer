# Graph Report - woofer  (2026-08-15)

## Corpus Check
- 55 files · ~74,819 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 908 nodes · 1230 edges · 58 communities (48 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5b50aa33`
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
- glass_scaffold.dart
- MethodChannel
- String?
- package:flutter/cupertino.dart
- aurora_background.dart
- storage_service_test.dart
- library_tab.dart
- StatelessWidget
- media_processor_test.dart
- history_service_test.dart
- json_parsing_test.dart
- historyServiceProvider
- settings_tab.dart
- _FakeYtdlp
- test_outtmpl.py
- StatelessWidget
- share_intent.dart
- glass_ui_test.dart
- foregroundServiceProvider
- _MarkPainter

## God Nodes (most connected - your core abstractions)
1. `MainActivity` - 18 edges
2. `DownloadState` - 11 edges
3. `WOOFER Project To-Do` - 11 edges
4. `downloadControllerProvider` - 10 edges
5. `DownloadService` - 9 edges
6. `DownloadController` - 9 edges
7. `WOOFER — project guide` - 9 edges
8. `_LibraryTabState` - 6 edges
9. `Flutter Framework` - 6 edges
10. `VideoInfo` - 5 edges

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

## Communities (58 total, 10 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.12
Nodes (15): _bgGradient, _Blob, _blobs, bottom, build, _c, child, color (+7 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.06
Nodes (39): active, _Badge, _c, _CaptionLabel, child, controller, createState, _DetectedCard (+31 more)

### Community 3 - "Home Page State"
Cohesion: 0.06
Nodes (34): CoverFetcher, fetch, _imageExt, _timeout, _deleteQuietly, detail, _dir, _ext (+26 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.25
Nodes (7): channel, extractor, main, messenger, mockChannel, dart:async, package:woofer/services/ytdlp_extractor.dart

### Community 5 - "Android Host Activity"
Cohesion: 0.08
Nodes (18): DownloadActionReceiver, DownloadService, Context, showResult(), Context, MethodChannel, MainActivity, ProgressBridge (+10 more)

### Community 13 - "StatelessWidget"
Cohesion: 0.09
Nodes (22): describeError, digits, false, formatBytes, formatDate, formatDuration, formatIsVideo, formatLabel (+14 more)

### Community 14 - "_download_to_file"
Cohesion: 0.07
Nodes (25): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, needsMerge (+17 more)

### Community 15 - "formats_screen.dart"
Cohesion: 0.13
Nodes (14): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+6 more)

### Community 16 - "ytdlp_extractor.dart"
Cohesion: 0.31
Nodes (9): _classify(), download(), _error(), extract_info(), yt-dlp bridge for the "ytdlp" MethodChannel.  Both entry points return a JSON *e, Abort the running download. Safe to call when nothing is running., Download a single format to out_dir. `callback.onProgress(recv, total)` is     i, request_cancel() (+1 more)

### Community 17 - "video_info.dart"
Cohesion: 0.11
Nodes (17): active, _Chip, createState, _Empty, entry, _filter, _guard, label (+9 more)

### Community 18 - "history_service.dart"
Cohesion: 0.06
Nodes (34): api_exception.dart, cancel, _channel, download, extractInfo, _invoke, _onNativeCall, ytdlpErrorCode (+26 more)

### Community 19 - "history_screen.dart"
Cohesion: 0.05
Nodes (42): _activeDownload, _bestAudio, cancel, cancelled, canExtract, _cover, _deleteDirQuietly, _deleteQuietly (+34 more)

### Community 20 - "glass_container.dart"
Cohesion: 0.10
Nodes (19): AlignmentGeometry?, alignment, blur, border, borderRadius, build, child, enableBlur (+11 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.05
Nodes (40): _askedForNotifications, _channel, _defaultChannel, ForegroundService, hide, _invoke, onCancelRequested, show (+32 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.03
Nodes (74): a100, a200, a300, a400, a500, a600, a700, a800 (+66 more)

### Community 24 - "download_state.dart"
Cohesion: 0.11
Nodes (23): code, Done, Downloading, DownloadState, Failed, format, formats, FormatsReady (+15 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.08
Nodes (24): active, _c, child, createState, current, _defs, dispose, icon (+16 more)

### Community 26 - "progress_screen.dart"
Cohesion: 0.18
Nodes (10): _app, _info, main, main, package:flutter_riverpod/flutter_riverpod.dart, package:woofer/main.dart, package:woofer/state/download_controller.dart, package:woofer/ui/screens/library_tab.dart (+2 more)

### Community 27 - "history_screen.dart"
Cohesion: 0.11
Nodes (17): animated, bars, beat, build, _c, createState, _delays, didUpdateWidget (+9 more)

### Community 28 - "glass_ui_test.dart"
Cohesion: 0.33
Nodes (5): Build changes, Build-time requirement: Python 3.12, Caveats, Channel contract (`ytdlp`), On-device yt-dlp via Chaquopy

### Community 29 - "glass_button.dart"
Cohesion: 0.05
Nodes (46): _Boot, _BootState, build, createState, dispose, initState, main, _ready (+38 more)

### Community 30 - "screens_test.dart"
Cohesion: 0.12
Nodes (15): Animation, AnimationController?, animation, build, createState, dispose, _down, _enabled (+7 more)

### Community 31 - "video_info.dart"
Cohesion: 0.18
Nodes (10): build, child, _DesignSheetPanel, GlassSheet, _GlassSheetPanel, SheetGrabber, title, glass_container.dart (+2 more)

### Community 32 - "screens_test.dart"
Cohesion: 0.12
Nodes (17): _brightness, build, createState, _gap, GlassGalleryScreen, _GlassGalleryScreenState, _isDark, _openSheet (+9 more)

### Community 33 - "glass_scaffold.dart"
Cohesion: 0.24
Nodes (10): historyListProvider, DownloadTab, _DownloadTabState, HomeShell, _HomeShellState, build, LibraryTab, _LibraryTabState (+2 more)

### Community 35 - "aurora_background.dart"
Cohesion: 0.17
Nodes (11): Current baseline, P0 — Correctness and lifecycle safety, P1 — Android integration review, P1 — Media selection and download behavior, P1 — Release blockers, P2 — CI and quality gates, P2 — Dependency and build maintenance, P2 — Documentation and repository hygiene (+3 more)

### Community 37 - "GlassGalleryScreen"
Cohesion: 0.05
Nodes (42): _audioOnly, cancel, cancels, download, downloadCalls, downloaded, downloadUrls, extractCalls (+34 more)

### Community 38 - "glass_scaffold.dart"
Cohesion: 0.11
Nodes (17): _Blob, bottom, build, child, children, color, GlassBackground, GlassScaffold (+9 more)

### Community 40 - "String?"
Cohesion: 0.17
Nodes (11): duration, formats, fromJson, thumbnail, title, uploader, VideoInfo, double? (+3 more)

### Community 41 - "package:flutter/cupertino.dart"
Cohesion: 0.22
Nodes (9): downloadControllerProvider, sharedUrlProvider, _ActiveCard, build, _fetch, build, _openFormatSheet, _confirm (+1 more)

### Community 43 - "storage_service_test.dart"
Cohesion: 0.29
Nodes (5): main, main, package:flutter_test/flutter_test.dart, package:woofer/state/share_intent.dart, package:woofer/ui/format_utils.dart

### Community 44 - "library_tab.dart"
Cohesion: 0.20
Nodes (9): Architecture, Build & run, Design system, Errors, Gotchas that cost real time, Layout, State / open items, Testing (+1 more)

### Community 45 - "StatelessWidget"
Cohesion: 0.12
Nodes (16): _AboutSheet, build, icon, label, _LegalButton, _LinkRow, onTap, _open (+8 more)

### Community 46 - "media_processor_test.dart"
Cohesion: 0.25
Nodes (9): coverFetcherProvider, DownloadController, historyServiceProvider, mediaProcessorProvider, _recordHistory, storageServiceProvider, ytdlpExtractorProvider, _openActions (+1 more)

### Community 47 - "history_service_test.dart"
Cohesion: 0.06
Nodes (30): add, clear, createdAt, _createTableSql, _db, delete, filePath, format (+22 more)

### Community 48 - "json_parsing_test.dart"
Cohesion: 0.29
Nodes (6): main, dart:convert, package:woofer/models/api_error.dart, package:woofer/models/media_format.dart, package:woofer/models/video_info.dart, package:woofer/services/api_exception.dart

### Community 49 - "historyServiceProvider"
Cohesion: 0.15
Nodes (12): build, hold, SplashScreen, build, fontSize, height, Wordmark, package:flutter/cupertino.dart (+4 more)

### Community 50 - "settings_tab.dart"
Cohesion: 0.14
Nodes (13): build, _Group, icon, label, name, onTap, _Row, rows (+5 more)

### Community 51 - "_FakeYtdlp"
Cohesion: 0.50
Nodes (4): YtdlpExtractor, _BlockingDownloadYtdlp, _ControlledExtractYtdlp, _FakeYtdlp

### Community 52 - "test_outtmpl.py"
Cohesion: 0.47
Nodes (5): _live_template(), _names(), Guards the download filename template in ytdlp_bridge.  Run with any interpreter, The outtmpl ytdlp_bridge actually uses, so this can't drift from the source., test_outtmpl_separates_the_two_streams_of_a_merge()

### Community 53 - "StatelessWidget"
Cohesion: 0.67
Nodes (3): MediaProcessor, _BlockingProcessor, _FakeProcessor

### Community 54 - "share_intent.dart"
Cohesion: 0.20
Nodes (9): controller, firstUrl, initial, initialUrl, null, _pickUrl, download_controller.dart, package:receive_sharing_intent/receive_sharing_intent.dart (+1 more)

### Community 55 - "glass_ui_test.dart"
Cohesion: 0.25
Nodes (7): _app, main, package:woofer/ui/theme/app_theme.dart, package:woofer/ui/widgets/glass_button.dart, package:woofer/ui/widgets/glass_container.dart, package:woofer/ui/widgets/glass_scaffold.dart, package:woofer/ui/widgets/glass_sheet.dart

## Knowledge Gaps
- **536 isolated node(s):** `_ready`, `_timer`, `main`, `build`, `createState` (+531 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HistoryService` connect `history_service_test.dart` to `history_screen.dart`, `GlassGalleryScreen`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `VideoInfo` connect `String?` to `download_state.dart`, `history_service.dart`, `_error`, `history_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `glass_scaffold.dart`, `_error`, `media_processor_test.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `_ready`, `_timer`, `main` to the rest of the system?**
  _536 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Counter App UI` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.06025641025641026 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.05555555555555555 - nodes in this community are weakly interconnected._