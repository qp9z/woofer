# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 19 files · ~5,870 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 183 nodes · 217 edges · 23 communities (17 shown, 6 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 7 edges (avg confidence: 0.74)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ea6ad14d`
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
- _check_ytdlp_update
- json_parsing_test.dart
- media_format.dart
- api_error.dart
- config.dart

## God Nodes (most connected - your core abstractions)
1. `download()` - 13 edges
2. `_build_response()` - 7 edges
3. `extract()` - 7 edges
4. `_check_ytdlp_update()` - 6 edges
5. `_has()` - 6 edges
6. `_fake_download()` - 6 edges
7. `Flutter Framework` - 6 edges
8. `_ytdlp_version()` - 4 edges
9. `rate_limit_mw()` - 4 edges
10. `_classify_error()` - 4 edges

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

## Communities (23 total, 6 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.17
Nodes (12): build, _counter, createState, _incrementCounter, main, MyApp, MyHomePage, _MyHomePageState (+4 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.11
Nodes (18): api_exception.dart, ApiClient, _asJsonMap, _deleteQuietly, _dio, download, _errorFromStream, extract (+10 more)

### Community 4 - "test_extract.py"
Cohesion: 0.53
Nodes (4): _mock_ydl(), test_extract_private(), test_extract_success(), test_extract_unavailable()

### Community 13 - "main.py"
Cohesion: 0.11
Nodes (33): _build_response(), _classify_error(), _content_type(), download(), _download_to_file(), DownloadRequest, _error(), _estimated_size() (+25 more)

### Community 14 - "_download_to_file"
Cohesion: 0.14
Nodes (13): ApiErrorCode, ApiException, code, fromError, fromWire, message, network, rawCode (+5 more)

### Community 15 - "test_download.py"
Cohesion: 0.27
Nodes (6): _fake_download(), test_download_allowed_when_it_fits_on_disk(), test_download_audio_is_mp3(), test_download_muxed_not_merged(), test_download_video_only_gets_merged(), test_download_video_streams_with_headers()

### Community 17 - "video_info.dart"
Cohesion: 0.17
Nodes (11): duration, formats, fromJson, thumbnail, title, uploader, VideoInfo, double? (+3 more)

### Community 18 - "_check_ytdlp_update"
Cohesion: 0.25
Nodes (9): _check_ytdlp_update(), _latest_pypi_version(), lifespan(), _norm_version(), yt-dlp and app version., Best-effort: log whether a newer yt-dlp exists on PyPI. Never raises., _update_event(), version() (+1 more)

### Community 19 - "json_parsing_test.dart"
Cohesion: 0.17
Nodes (10): main, main, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:woofer/main.dart, package:woofer/models/api_error.dart, package:woofer/models/media_format.dart (+2 more)

### Community 20 - "media_format.dart"
Cohesion: 0.18
Nodes (10): ext, filesize, formatId, fromJson, hasAudio, hasVideo, MediaFormat, note (+2 more)

### Community 21 - "api_error.dart"
Cohesion: 0.40
Nodes (4): ApiError, errorCode, fromJson, message

### Community 22 - "config.dart"
Cohesion: 0.50
Nodes (3): AppConfig, baseUrl, static const String

## Knowledge Gaps
- **57 isolated node(s):** `AppConfig`, `baseUrl`, `title`, `_counter`, `main` (+52 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `AppConfig`, `baseUrl`, `title` to the rest of the system?**
  _57 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `_error` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `main.py` be split into smaller, more focused modules?**
  _Cohesion score 0.11260504201680673 - nodes in this community are weakly interconnected._
- **Should `_download_to_file` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._