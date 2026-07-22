# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 8 files · ~2,506 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 54 nodes · 60 edges · 13 communities (8 shown, 5 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6b5753e4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Counter App UI
- Flutter Project & Deps
- Widget Test Harness
- Home Page State
- Android Host Activity
- Launcher Icon (hdpi)
- Launcher Icon (mdpi)
- Launcher Icon (xhdpi)
- Launcher Icon (xxhdpi)
- main.py

## God Nodes (most connected - your core abstractions)
1. `_build_response()` - 7 edges
2. `extract()` - 6 edges
3. `Flutter Framework` - 6 edges
4. `_has()` - 4 edges
5. `MyHomePage` - 3 edges
6. `_MyHomePageState` - 3 edges
7. `ExtractRequest` - 3 edges
8. `FormatModel` - 3 edges
9. `ExtractResponse` - 3 edges
10. `_classify_error()` - 3 edges

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

## Communities (13 total, 5 thin omitted)

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
Cohesion: 0.33
Nodes (6): _classify_error(), _error(), extract(), Map a yt-dlp error message to one of the documented error codes., _valid_url(), JSONResponse

### Community 13 - "main.py"
Cohesion: 0.36
Nodes (9): _build_response(), ExtractError, ExtractRequest, ExtractResponse, FormatModel, _has(), _quality_key(), _resolution() (+1 more)

## Knowledge Gaps
- **15 isolated node(s):** `title`, `_counter`, `main`, `build`, `createState` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Are the 4 inferred relationships involving `Flutter Framework` (e.g. with `App Launcher Icon (xxxhdpi) — Flutter Logo` and `cupertino_icons Dependency`) actually correct?**
  _`Flutter Framework` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `title`, `_counter`, `main` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._