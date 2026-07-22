# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 10 files · ~3,751 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 82 nodes · 107 edges · 18 communities (13 shown, 5 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9a348480`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Counter App UI
- Flutter Project & Deps
- Widget Test Harness
- Home Page State
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
- _build_response

## God Nodes (most connected - your core abstractions)
1. `download()` - 12 edges
2. `_build_response()` - 7 edges
3. `extract()` - 7 edges
4. `_has()` - 6 edges
5. `Flutter Framework` - 6 edges
6. `_fake_download()` - 5 edges
7. `_classify_error()` - 4 edges
8. `_error()` - 4 edges
9. `_estimated_size()` - 4 edges
10. `_probe()` - 4 edges

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

## Communities (18 total, 5 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.17
Nodes (12): build, _counter, createState, _incrementCounter, main, MyApp, MyHomePage, _MyHomePageState (+4 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "Widget Test Harness"
Cohesion: 0.40
Nodes (4): main, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:woofer/main.dart

### Community 3 - "Home Page State"
Cohesion: 0.25
Nodes (8): _classify_error(), _error(), extract(), _probe(), Metadata only, no download., Map a yt-dlp error message to one of the documented error codes., _valid_url(), JSONResponse

### Community 4 - "test_extract.py"
Cohesion: 0.53
Nodes (4): _mock_ydl(), test_extract_private(), test_extract_success(), test_extract_unavailable()

### Community 13 - "main.py"
Cohesion: 0.39
Nodes (6): DownloadRequest, ExtractError, ExtractRequest, ExtractResponse, FormatModel, BaseModel

### Community 14 - "_download_to_file"
Cohesion: 0.67
Nodes (3): _download_to_file(), Download (and post-process) into tmpdir; return the final media file., Path

### Community 15 - "test_download.py"
Cohesion: 0.29
Nodes (5): _fake_download(), test_download_audio_is_mp3(), test_download_muxed_not_merged(), test_download_video_only_gets_merged(), test_download_video_streams_with_headers()

### Community 16 - "download"
Cohesion: 0.33
Nodes (6): _content_type(), download(), _estimated_size(), _find_format(), Reported size of the download, incl. the audio stream we'll merge in., _safe_filename()

### Community 17 - "_build_response"
Cohesion: 0.83
Nodes (4): _build_response(), _has(), _quality_key(), _resolution()

## Knowledge Gaps
- **15 isolated node(s):** `title`, `_counter`, `main`, `build`, `createState` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `download()` connect `download` to `_build_response`, `Home Page State`, `main.py`, `_download_to_file`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `_download_to_file()` connect `_download_to_file` to `download`, `main.py`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `_classify_error()` connect `Home Page State` to `download`, `main.py`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `Flutter Framework` (e.g. with `App Launcher Icon (xxxhdpi) — Flutter Logo` and `cupertino_icons Dependency`) actually correct?**
  _`Flutter Framework` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `title`, `_counter`, `main` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._