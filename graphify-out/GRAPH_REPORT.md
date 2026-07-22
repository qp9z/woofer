# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 31 files · ~9,730 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 391 nodes · 476 edges · 28 communities (23 shown, 5 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.74)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bc2466ac`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Counter App UI
- Flutter Project & Deps
- _error
- test_extract.py
- Android Host Activity
- Launcher Icon (hdpi)
- Launcher Icon (mdpi)
- Launcher Icon (xhdpi)
- Launcher Icon (xxhdpi)
- main.py
- _download_to_file
- test_download.py
- download
- video_info.dart
- history_service.dart
- json_parsing_test.dart
- glass_container.dart
- api_error.dart
- config.dart
- app_theme.dart
- glass_scaffold.dart
- glass_list_tile.dart
- glass_sheet.dart
- StatelessWidget

## God Nodes (most connected - your core abstractions)
1. `download()` - 13 edges
2. `MainActivity` - 7 edges
3. `_build_response()` - 7 edges
4. `extract()` - 7 edges
5. `_check_ytdlp_update()` - 6 edges
6. `_has()` - 6 edges
7. `_fake_download()` - 6 edges
8. `Flutter Framework` - 6 edges
9. `_ytdlp_version()` - 4 edges
10. `rate_limit_mw()` - 4 edges

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

## Communities (28 total, 5 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.29
Nodes (6): build, main, WooferApp, package:flutter/cupertino.dart, ui/gallery/glass_gallery.dart, ui/theme/app_theme.dart

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.11
Nodes (17): api_exception.dart, ApiClient, _asJsonMap, _deleteQuietly, _dio, download, _errorFromStream, extract (+9 more)

### Community 4 - "test_extract.py"
Cohesion: 0.53
Nodes (4): _mock_ydl(), test_extract_private(), test_extract_success(), test_extract_unavailable()

### Community 5 - "Android Host Activity"
Cohesion: 0.27
Nodes (5): MainActivity, FlutterActivity, FlutterEngine, MethodChannel, Uri

### Community 13 - "main.py"
Cohesion: 0.09
Nodes (42): _build_response(), _check_ytdlp_update(), _classify_error(), _content_type(), download(), _download_to_file(), DownloadRequest, _error() (+34 more)

### Community 14 - "_download_to_file"
Cohesion: 0.08
Nodes (24): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, note (+16 more)

### Community 15 - "test_download.py"
Cohesion: 0.27
Nodes (6): _fake_download(), test_download_allowed_when_it_fits_on_disk(), test_download_audio_is_mp3(), test_download_muxed_not_merged(), test_download_video_only_gets_merged(), test_download_video_streams_with_headers()

### Community 17 - "video_info.dart"
Cohesion: 0.05
Nodes (40): _brightness, build, createState, _gap, GlassGalleryScreen, _GlassGalleryScreenState, _isDark, _openSheet (+32 more)

### Community 18 - "history_service.dart"
Cohesion: 0.06
Nodes (33): AppConfig, baseUrl, add, clear, createdAt, _createTableSql, _db, delete (+25 more)

### Community 19 - "json_parsing_test.dart"
Cohesion: 0.11
Nodes (16): _app, main, main, main, dart:convert, package:flutter_test/flutter_test.dart, package:woofer/main.dart, package:woofer/models/api_error.dart (+8 more)

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
Nodes (29): accent, AppBackground, AppColors, AppGlass, AppRadius, AppSpacing, AppTheme, blobA (+21 more)

### Community 25 - "glass_scaffold.dart"
Cohesion: 0.13
Nodes (14): bottom, build, child, children, color, leading, padding, size (+6 more)

### Community 26 - "glass_list_tile.dart"
Cohesion: 0.14
Nodes (13): build, frosted, leading, margin, onTap, padding, showChevron, subtitle (+5 more)

### Community 27 - "glass_sheet.dart"
Cohesion: 0.22
Nodes (8): build, child, GlassSheet, title, glass_container.dart, T, ../theme/app_theme.dart, Widget

### Community 28 - "StatelessWidget"
Cohesion: 0.25
Nodes (8): GlassContainer, GlassListSection, GlassListTile, _Blob, GlassBackground, GlassScaffold, _GlassSheetPanel, StatelessWidget

## Knowledge Gaps
- **193 isolated node(s):** `AppConfig`, `baseUrl`, `main`, `build`, `ApiError` (+188 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `AppConfig`, `baseUrl`, `main` to the rest of the system?**
  _193 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `main.py` be split into smaller, more focused modules?**
  _Cohesion score 0.08773784355179703 - nodes in this community are weakly interconnected._
- **Should `_download_to_file` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `video_info.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05226480836236934 - nodes in this community are weakly interconnected._
- **Should `history_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05714285714285714 - nodes in this community are weakly interconnected._
- **Should `json_parsing_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._