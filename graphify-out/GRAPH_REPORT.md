# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 12 files · ~4,629 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 111 nodes · 146 edges · 18 communities (12 shown, 6 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 7 edges (avg confidence: 0.74)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `99ebba70`
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
- _check_ytdlp_update

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

## Communities (18 total, 6 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.12
Nodes (16): build, _counter, createState, _incrementCounter, main, MyApp, MyHomePage, _MyHomePageState (+8 more)

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.25
Nodes (9): Dart Static Analyzer, flutter_lints Lint Ruleset, App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_lints Dev Dependency, flutter_test Dev Dependency, Material Design (uses-material-design) (+1 more)

### Community 2 - "_error"
Cohesion: 0.40
Nodes (5): logging_mw(), rate_limit_mw(), _rate_limited(), JSONResponse, Request

### Community 4 - "test_extract.py"
Cohesion: 0.53
Nodes (4): _mock_ydl(), test_extract_private(), test_extract_success(), test_extract_unavailable()

### Community 13 - "main.py"
Cohesion: 0.16
Nodes (25): _build_response(), _classify_error(), _content_type(), download(), DownloadRequest, _error(), _estimated_size(), extract() (+17 more)

### Community 14 - "_download_to_file"
Cohesion: 0.67
Nodes (3): _download_to_file(), Download (and post-process) into tmpdir; return the final media file., Path

### Community 15 - "test_download.py"
Cohesion: 0.27
Nodes (6): _fake_download(), test_download_allowed_when_it_fits_on_disk(), test_download_audio_is_mp3(), test_download_muxed_not_merged(), test_download_video_only_gets_merged(), test_download_video_streams_with_headers()

### Community 18 - "_check_ytdlp_update"
Cohesion: 0.25
Nodes (9): _check_ytdlp_update(), _latest_pypi_version(), lifespan(), _norm_version(), yt-dlp and app version., Best-effort: log whether a newer yt-dlp exists on PyPI. Never raises., _update_event(), version() (+1 more)

## Knowledge Gaps
- **15 isolated node(s):** `title`, `_counter`, `main`, `build`, `createState` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_download_to_file()` connect `_download_to_file` to `main.py`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `download()` connect `main.py` to `_download_to_file`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `_check_ytdlp_update()` connect `_check_ytdlp_update` to `main.py`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `title`, `_counter`, `main` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Counter App UI` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._