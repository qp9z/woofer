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
- Cancelling a download no longer re-opens the format sheet.
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

- **Accessibility.** Every control now has button semantics and a 44 px target;
  icon-only ones are named for screen readers ("About Woofer", "Clear link",
  "Cancel download", "More actions for ...", the nav tabs with their selected
  state). Toasts are announced. The aurora, Fetch sheen, progress stripe and splash
  mark freeze when Android's "Remove animations" is on. Layouts hold at 200% text,
  320 px width and landscape (the Library filter chips wrap, the Settings value
  drops under its label, the nav pill label ellipsizes).
- **Library:** a file that can no longer be opened or shared can be removed from the
  list on the spot, and "Clear library" empties it after a confirmation. Removing
  only forgets the entry: the file stays in Downloads, and every message says so.
- A **Best** badge in the format sheet marks what an untouched Download fetches.
- "A download is in progress - cancel it to fetch another link" appears under Fetch
  while one runs, and as a toast when a shared link is turned away (it used to
  vanish silently). Cancelling shows "Download cancelled." Downloads with no known
  total say "size unknown".

### Changed
- **History database schema v2:** it now stores the media kind, MIME type, file
  extension and yt-dlp format id, so the Library no longer guesses audio vs video
  from a label and open/share use the real MIME type. Existing libraries upgrade in
  place.
- Settings: Save location reads `Downloads/woofer`, a note explains quality
  selection, and the footer shows the installed version.
- The URL placeholder and the Settings footer text meet WCAG AA contrast.
- Bottom action sheets scroll instead of overflowing on short screens.
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
version line. The accessibility work is verified by guideline and layout tests only:
TalkBack, real font scaling, landscape and the Remove-animations toggle have not
been tried on hardware.

## [1.0.0] — unreleased

First build: paste or share a link, pick a quality, and the file is saved to
`Downloads/woofer`. On-device yt-dlp (Chaquopy) + ffmpeg_kit; video-only formats are
merged with the best audio, audio-only choices become MP3 192k with cover art;
foreground-service notification with Cancel; local download history.
