# WOOFER — project guide

Android media downloader. **Everything runs on-device — there is no backend.**
yt-dlp runs in-process via Chaquopy (CPython), ffmpeg via ffmpeg_kit. Flutter UI.

## Layout

```
app/                    Flutter app (the whole product)
  lib/ui/               screens, sheets, widgets, theme
  lib/state/            Riverpod controller + state machine
  lib/services/         yt-dlp bridge, ffmpeg, storage, history
  android/app/src/main/python/ytdlp_bridge.py   Python side of the MethodChannel
design/                 brand identity + Inter font (source of truth: see below)
graphify-out/           generated knowledge graph, not source
```

## Build & run

```bash
cd app
flutter analyze && flutter test          # 118 tests, keep them green
flutter build apk --profile
flutter build apk --release
flutter build appbundle --release
flutter install --release -d R5CXA4Q2SHK  # SM A556E, Android 16
```

Test device is a Samsung SM A556E (`R5CXA4Q2SHK`). `adb` is **not on PATH**:
`C:/Users/Pc/AppData/Local/Android/Sdk/platform-tools/adb.exe`. Package id is
`dev.koulei.woofer`.

Screenshot loop: `adb shell monkey -p dev.koulei.woofer -c android.intent.category.LAUNCHER 1`
then `adb exec-out screencap -p > out.png`. If the phone is locked or asleep the
framebuffer is black — nothing to debug, just ask for it to be unlocked.

## Architecture

**Download flow** — one state machine, `DownloadController`
(`lib/state/download_controller.dart`), states in `download_state.dart`:

```
Idle → Loading → FormatsReady → Downloading → Processing → Done | Failed
```

`extract(url)` resolves formats through yt-dlp; `download()` fetches the chosen
stream, merges/transcodes, saves to public Downloads (MediaStore), records history.
Video-only formats get merged with the best audio; audio-only transcodes to MP3 192k.

**Network-switch retry** — `_downloadFormatWithNetworkRetry` wraps yt-dlp downloads:
on `ApiErrorCode.network` (mid-download Wi-Fi ↔ cellular switch), it rebinds the
process to the new active network via `bindProcessToActiveNetwork()` and retries
once. Applies to both the primary stream and the merged-audio stream.

**UI** — a tab shell, not push navigation. `HomeShell` (aurora background +
`IndexedStack` of Download/Library/Settings + floating nav pill + toast) drives
two bottom sheets: the format picker and About. The shell watches the controller:
`FormatsReady` opens the format sheet, `Done` toasts and resets.

## Design system

The UI is a high-fidelity implementation of a **Claude Design** handoff, not
freehand. Tokens live in `lib/ui/theme/app_theme.dart` — `AppColors`, `AppType`,
`AppSpacing`, `AppRadius`, `AppGlass`, `AppTouch`.

**Reference the tokens; do not inline font sizes, colours or paddings in widgets.**
The prototype was drawn on a 340px phone mock, so raw values from it read ~20% too
small on a real handset — `AppType` is the corrected scale. Touch targets must
clear `AppTouch.min` (44px).

Design source, including the full token spec (`THEME.md`) and the interactive
prototype, is a Claude Design project — see the `woofer-design-source` memory for
the project id and how to read it with the DesignSync tool.

## Gotchas that cost real time

- **Chaquopy needs `disable-abi-filtering=true`** (`android/gradle.properties`).
  Python 3.12 has no armeabi-v7a build, but Flutter otherwise force-overrides
  `ndk.abiFilters` to all ABIs and Chaquopy fails. minSdk is pinned to 24.
- **`android/local.properties` is gitignored** and must contain
  `chaquopy.buildPython=<path to a real Python 3.12>` (installed via `uv python
  install 3.12`). Without it the build can't find a 3.12 interpreter.
- **Python's sockets need the network bound explicitly.** `MainActivity.kt` calls
  `ConnectivityManager.bindProcessToNetwork()` before each Python network call —
  without it Dart has connectivity but Python DNS fails.
- **Downloads get a fresh temp dir per attempt.** yt-dlp names files by title only,
  so a shared temp let a leftover `.part` be *resumed* (a range past EOF ⇒ HTTP 416)
  or a stale file of the wrong resolution be silently reused. Don't reintroduce a
  shared download dir.
- **Merge container is chosen from the codecs**, not hardcoded. YouTube serves 4K as
  VP9/AV1 + Opus, which cannot stream-copy into `.mp4` (that threw `ffmpeg exited
  with code 1`). `MediaProcessor.mergeContainer` picks mp4 / webm / mkv;
  `+faststart` is mp4-only. A 4K download legitimately saves as `.webm`.
- **YouTube's bot gate is a moving target.** `_COMMON` in `ytdlp_bridge.py` sets
  `player_client: [default, tv_embedded, android_vr]`. A PO-token/WebView bypass was
  investigated and **deliberately abandoned** — on a flagged IP the token gets past
  the gate but web clients then return SABR/storyboard-only formats. Don't redo that
  work without new information; the app surfaces an honest "YouTube is blocking us"
  screen instead.
- **`adb devices` showing `unauthorized`**: `adb kill-server && adb start-server`
  usually re-triggers the authorization prompt.
- **Launcher icons are cached hard by Android.** After changing them, a reboot may
  be needed before the new icon appears.

## Errors

yt-dlp's raw messages are user-hostile, so `ytdlp_bridge.py` classifies them into a
wire vocabulary (`BOT_CHECK`, `NO_VIDEO`, `PRIVATE`, `GEO`, …) mapped to
`ApiErrorCode` and then to short human headlines in `format_utils.dart`.
Keep errors honest — say what actually happened, never fake success.

## Testing

`flutter test` — 65 tests. Note: the aurora, the equalizer and the Fetch sheen
animate **forever**, so `pumpAndSettle()` will hang on any screen containing them.
Use fixed `pump(Duration)` calls instead.

## State / open items

All work is committed on `main`. Outstanding:

1. **Retest a 4K YouTube download** — the 416 and ffmpeg-merge fixes are in but were
   never confirmed end-to-end (the test IP was blocked at the time).
2. **Eyeball the launcher icon and the animated intro on-device** — both verified by
   asset inspection and tests, never seen running (phone was locked).
3. Settings rows are informational only — they reflect real fixed behaviour
   (MP3 192k, saves to Downloads, dark theme). There is no preferences store; don't
   add toggles that silently do nothing.
