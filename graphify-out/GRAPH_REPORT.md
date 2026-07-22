# Graph Report - woofer  (2026-07-22)

## Corpus Check
- 8 files · ~2,092 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 39 nodes · 30 edges · 14 communities (9 shown, 5 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1d460f13`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Counter App UI
- Flutter Project & Deps
- Widget Test Harness
- Home Page State
- Dart Lint & Analysis
- Android Host Activity
- Launcher Icon (hdpi)
- Launcher Icon (mdpi)
- Launcher Icon (xhdpi)
- Launcher Icon (xxhdpi)

## God Nodes (most connected - your core abstractions)
1. `Flutter Framework` - 6 edges
2. `MyHomePage` - 3 edges
3. `_MyHomePageState` - 3 edges
4. `MainActivity` - 2 edges
5. `MyApp` - 2 edges
6. `cupertino_icons Dependency` - 2 edges
7. `flutter_lints Dev Dependency` - 2 edges
8. `Material Design (uses-material-design)` - 2 edges
9. `flutter_lints Lint Ruleset` - 2 edges
10. `title` - 1 edges

## Surprising Connections (you probably didn't know these)
- `App Launcher Icon (xxxhdpi) — Flutter Logo` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png → README.md
- `flutter_lints Dev Dependency` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
  pubspec.yaml → README.md
- `cupertino_icons Dependency` --conceptually_related_to--> `Flutter Framework`  [INFERRED]
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

## Communities (14 total, 5 thin omitted)

### Community 0 - "Counter App UI"
Cohesion: 0.22
Nodes (8): build, _counter, createState, _incrementCounter, main, MyApp, title, StatelessWidget

### Community 1 - "Flutter Project & Deps"
Cohesion: 0.40
Nodes (6): App Launcher Icon (xxxhdpi) — Flutter Logo, Flutter Framework, cupertino_icons Dependency, flutter_test Dev Dependency, Material Design (uses-material-design), woofer (Flutter Project)

### Community 2 - "Widget Test Harness"
Cohesion: 0.40
Nodes (4): main, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:woofer/main.dart

### Community 3 - "Home Page State"
Cohesion: 0.50
Nodes (4): MyHomePage, _MyHomePageState, State, StatefulWidget

### Community 4 - "Dart Lint & Analysis"
Cohesion: 0.67
Nodes (3): Dart Static Analyzer, flutter_lints Lint Ruleset, flutter_lints Dev Dependency

## Knowledge Gaps
- **15 isolated node(s):** `title`, `_counter`, `main`, `build`, `createState` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Flutter Framework` connect `Flutter Project & Deps` to `Dart Lint & Analysis`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `MyHomePage` connect `Home Page State` to `Counter App UI`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `Flutter Framework` (e.g. with `App Launcher Icon (xxxhdpi) — Flutter Logo` and `cupertino_icons Dependency`) actually correct?**
  _`Flutter Framework` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `title`, `_counter`, `main` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._