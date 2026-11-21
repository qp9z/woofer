# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow
`version:` in `app/pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`).

## Releasing

1. Move the *Unreleased* entries under a new `## [x.y.z] — YYYY-MM-DD` heading.
2. Bump `version:` in `app/pubspec.yaml` (semver, `+` then an ever-increasing build
   number — Play requires `versionCode` to rise on every upload). It flows to the
   Android `versionName`/`versionCode` and to Settings → About.
3. Note the bundled **yt-dlp** version (Settings → About shows it; it is pinned in
   `app/android/app/requirements.txt`).
4. Build the bundle (`flutter build appbundle --release`) and check the signer:
   `apksigner verify --print-certs` must show the upload key, not the debug cert.

## [Unreleased]

### Fixed
- **Release builds were signed with the debug key.** A past commit replaced the
  `key.properties` signing config with the Flutter template's debug fallback; it is
  restored (and falls back to debug only when `key.properties` is absent).
- A link shared into the app while the Library or Settings tab was showing stopped
  being routed once the dependencies moved to Riverpod 3 (it pauses listeners of
  offstage widgets). `HomeShell` now owns the always-on subscription and brings
  the Download tab forward.
- Settings no longer shows a hardcoded `v1.0`; About shows the real version and
  build number.

### Added
- **yt-dlp version in Settings → About** (e.g. `yt-dlp 2026.10.26`), so a bug
  report says which extractor it came from.
- GitHub Actions CI: Flutter analyze/test (+ coverage artifact), the Python bridge
  tests, and an Android profile build with the native tests.
- Offline Python tests for the yt-dlp bridge (error classification, envelope
  validity, cancel path) and Robolectric tests for open/share intents and the
  notification Cancel receiver.
- Regression tests for unexpected processor/storage exceptions, shares while a
  download runs, and Library rows whose file was deleted.
- `SECURITY.md`, and a rewritten README for the on-device architecture.

### Changed
- **yt-dlp is pinned** (`2026.10.26`) in `app/android/app/requirements.txt` instead
  of floating, so identical commits bundle identical extractors.
- Chaquopy 17.0.0 → 17.2.0; `compileSdk` 37 (the per-plugin `compileSdk` 36
  workaround is removed).
- Dependencies: `flutter_riverpod` 3.5 (provider auto-retry disabled on purpose),
  `permission_handler` 13.0.2, `cupertino_icons` 2.0.0, `ffmpeg_kit_flutter_new`
  4.7.2, plus in-range bumps (`sqflite`, `url_launcher`, `package_info_plus`).
  `ffmpeg_kit_flutter_new` 5.0 (FFmpeg 8.1) is deferred until the on-device pass
  and the GPL/LGPL variant decision.
- The Python tests moved out of `src/main/python`, where they were being packaged
  into the APK.
- Repository hygiene: generated Graphify output, the Gradle problems report and
  stray agent marker files are no longer tracked.

### Not yet verified on a device
Nothing in this section has run on hardware (the test phone is unauthorized in
ADB): the share-from-another-tab fix, the permission flows after the
`permission_handler` upgrade, the `cupertino_icons` 2 glyphs, and the About
version line.

## [1.0.0] — unreleased

First build: paste or share a link, pick a quality, and the file is saved to
`Downloads/woofer`. On-device yt-dlp (Chaquopy) + ffmpeg_kit; video-only formats are
merged with the best audio, audio-only choices become MP3 192k with cover art;
foreground-service notification with Cancel; local download history.
