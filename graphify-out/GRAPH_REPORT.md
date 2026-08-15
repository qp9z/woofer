# Graph Report - woofer  (2026-08-15)

## Corpus Check
- 54 files · ~71,832 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 877 nodes · 1195 edges · 53 communities (45 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `26c4f5c4`
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
- dart:io
- historyServiceProvider
- settings_tab.dart
- package:flutter/cupertino.dart
- test_outtmpl.py

## God Nodes (most connected - your core abstractions)
1. `MainActivity` - 18 edges
2. `DownloadState` - 11 edges
3. `downloadControllerProvider` - 10 edges
4. `DownloadService` - 9 edges
5. `DownloadController` - 9 edges
6. `WOOFER — project guide` - 9 edges
7. `_LibraryTabState` - 6 edges
8. `Flutter Framework` - 6 edges
9. `VideoInfo` - 5 edges
10. `ApiException` - 5 edges

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

## Communities (53 total, 8 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.12
Nodes (16): _bgGradient, _Blob, _blobs, bottom, build, _c, child, color (+8 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.08
Nodes (25): active, _c, child, controller, createState, dim, dispose, _hasVideo (+17 more)

### Community 3 - "Home Page State"
Cohesion: 0.06
Nodes (34): api_exception.dart, _deleteQuietly, detail, _dir, _ext, FfmpegRun, MediaProcessor, mergeArgs (+26 more)

### Community 4 - "formats_screen.dart"
Cohesion: 0.14
Nodes (14): _Badge, _CaptionLabel, _DetectedCard, _ErrorCard, _Hint, _InfoCircle, _ProgressBar, _Thumb (+6 more)

### Community 5 - "Android Host Activity"
Cohesion: 0.08
Nodes (18): DownloadActionReceiver, DownloadService, Context, showResult(), Context, MethodChannel, MainActivity, ProgressBridge (+10 more)

### Community 13 - "StatelessWidget"
Cohesion: 0.19
Nodes (17): GlassGalleryScreen, _GlassGalleryScreenState, _IndeterminateStripe, _IndeterminateStripeState, _FadeIn, _FadeInState, AuroraBackground, _AuroraBackgroundState (+9 more)

### Community 14 - "_download_to_file"
Cohesion: 0.04
Nodes (46): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, needsMerge (+38 more)

### Community 15 - "formats_screen.dart"
Cohesion: 0.13
Nodes (14): build, frosted, GlassListSection, GlassListTile, leading, margin, onTap, padding (+6 more)

### Community 16 - "ytdlp_extractor.dart"
Cohesion: 0.31
Nodes (9): _classify(), download(), _error(), extract_info(), yt-dlp bridge for the "ytdlp" MethodChannel.  Both entry points return a JSON *e, Abort the running download. Safe to call when nothing is running., Download a single format to out_dir. `callback.onProgress(recv, total)` is     i, request_cancel() (+1 more)

### Community 17 - "video_info.dart"
Cohesion: 0.06
Nodes (36): historyListProvider, _brightness, build, createState, _gap, _isDark, _openSheet, _section (+28 more)

### Community 18 - "history_service.dart"
Cohesion: 0.08
Nodes (25): active, _audio, build, createState, enabled, _FormatSheet, _FormatSheetState, icon (+17 more)

### Community 19 - "history_screen.dart"
Cohesion: 0.05
Nodes (47): _bestAudio, build, cancel, _cancelled, _cover, coverFetcherProvider, _deleteDirQuietly, _deleteQuietly (+39 more)

### Community 20 - "glass_container.dart"
Cohesion: 0.10
Nodes (19): AlignmentGeometry?, alignment, blur, border, borderRadius, build, child, enableBlur (+11 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.06
Nodes (33): _askedForNotifications, _channel, _defaultChannel, ForegroundService, hide, _invoke, onCancelRequested, show (+25 more)

### Community 23 - "app_theme.dart"
Cohesion: 0.03
Nodes (74): a100, a200, a300, a400, a500, a600, a700, a800 (+66 more)

### Community 24 - "download_state.dart"
Cohesion: 0.05
Nodes (45): code, Done, Downloading, DownloadState, Failed, format, formats, FormatsReady (+37 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.08
Nodes (24): active, _c, child, createState, current, _defs, dispose, icon (+16 more)

### Community 26 - "progress_screen.dart"
Cohesion: 0.07
Nodes (26): controller, firstUrl, initial, initialUrl, null, _pickUrl, _app, main (+18 more)

### Community 27 - "history_screen.dart"
Cohesion: 0.10
Nodes (19): animated, bars, beat, build, _c, createState, _delays, didUpdateWidget (+11 more)

### Community 28 - "glass_ui_test.dart"
Cohesion: 0.33
Nodes (5): Build changes, Build-time requirement: Python 3.12, Caveats, Channel contract (`ytdlp`), On-device yt-dlp via Chaquopy

### Community 29 - "glass_button.dart"
Cohesion: 0.11
Nodes (17): blur, build, child, createState, _down, enableBlur, _enabled, expand (+9 more)

### Community 30 - "screens_test.dart"
Cohesion: 0.12
Nodes (15): Animation, AnimationController?, animation, build, createState, dispose, _down, _enabled (+7 more)

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
Cohesion: 0.16
Nodes (15): downloadControllerProvider, sharedUrlProvider, _ActiveCard, build, DownloadTab, _DownloadTabState, _fetch, build (+7 more)

### Community 37 - "GlassGalleryScreen"
Cohesion: 0.06
Nodes (32): _audioOnly, cancel, cancels, download, downloaded, extractCalls, extractError, extractInfo (+24 more)

### Community 38 - "glass_ui_test.dart"
Cohesion: 0.18
Nodes (10): duration, formats, fromJson, thumbnail, title, uploader, VideoInfo, double? (+2 more)

### Community 40 - "ytdlp_extractor_test.dart"
Cohesion: 0.14
Nodes (13): main, channel, extractor, main, messenger, mockChannel, dart:async, dart:convert (+5 more)

### Community 41 - "package:flutter/cupertino.dart"
Cohesion: 0.14
Nodes (14): _Boot, _BootState, build, createState, dispose, initState, main, _ready (+6 more)

### Community 43 - "storage_service_test.dart"
Cohesion: 0.25
Nodes (7): channel, main, messenger, tmp, File, package:flutter/services.dart, package:woofer/services/storage_service.dart

### Community 44 - "library_tab.dart"
Cohesion: 0.20
Nodes (9): Architecture, Build & run, Design system, Errors, Gotchas that cost real time, Layout, State / open items, Testing (+1 more)

### Community 45 - "StatelessWidget"
Cohesion: 0.12
Nodes (16): _AboutSheet, build, icon, label, _LegalButton, _LinkRow, onTap, _open (+8 more)

### Community 46 - "media_processor_test.dart"
Cohesion: 0.22
Nodes (8): ApiException, dir, main, okRunner, touch, Directory, Exception, package:woofer/services/media_processor.dart

### Community 47 - "history_service_test.dart"
Cohesion: 0.22
Nodes (8): HistoryService, db, entry, main, svc, Database, package:sqflite_common_ffi/sqflite_ffi.dart, package:woofer/services/history_service.dart

### Community 48 - "dart:io"
Cohesion: 0.25
Nodes (7): CoverFetcher, fetch, _imageExt, _timeout, _FakeCover, dart:io, static const Duration

### Community 49 - "historyServiceProvider"
Cohesion: 0.29
Nodes (6): build, hold, SplashScreen, ../widgets/aurora_background.dart, ../widgets/woofer_mark.dart, ../widgets/wordmark.dart

### Community 50 - "settings_tab.dart"
Cohesion: 0.14
Nodes (13): build, _Group, icon, label, name, onTap, _Row, rows (+5 more)

### Community 51 - "package:flutter/cupertino.dart"
Cohesion: 0.29
Nodes (6): build, fontSize, height, Wordmark, package:flutter/cupertino.dart, ../theme/app_theme.dart

### Community 52 - "test_outtmpl.py"
Cohesion: 0.47
Nodes (5): _live_template(), _names(), Guards the download filename template in ytdlp_bridge.  Run with any interpreter, The outtmpl ytdlp_bridge actually uses, so this can't drift from the source., test_outtmpl_separates_the_two_streams_of_a_merge()

## Knowledge Gaps
- **512 isolated node(s):** `_ready`, `_timer`, `main`, `build`, `createState` (+507 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `VideoInfo` connect `glass_ui_test.dart` to `download_state.dart`, `history_service.dart`, `_error`, `history_screen.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `HistoryService` connect `history_service_test.dart` to `history_screen.dart`, `GlassGalleryScreen`, `_download_to_file`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `DownloadState` connect `download_state.dart` to `glass_scaffold.dart`, `_error`, `history_screen.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `_ready`, `_timer`, `main` to the rest of the system?**
  _512 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Counter App UI` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Home Page State` be split into smaller, more focused modules?**
  _Cohesion score 0.05555555555555555 - nodes in this community are weakly interconnected._