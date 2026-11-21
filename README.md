# WOOFER

An Android media downloader. **Everything runs on the device — there is no
backend, account, or telemetry.** Paste a link (or share one into the app), pick a
quality, and the file lands in `Downloads/woofer`.

| Piece | What it does |
| --- | --- |
| Flutter (`app/lib`) | UI, the download state machine ([Riverpod](https://riverpod.dev)), history (sqflite) |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) via [Chaquopy](https://chaquo.com/chaquopy/) | Extracts formats and downloads the chosen stream, in-process on an embedded CPython 3.12 |
| [ffmpeg_kit](https://pub.dev/packages/ffmpeg_kit_flutter_new) | Merges video-only + audio streams, transcodes audio to MP3 192k |
| Kotlin (`app/android/.../dev/koulei/woofer`) | Channel host, foreground service + notifications, MediaStore saving, open/share intents |

Video-only formats are merged with the best audio track (container chosen from the
codecs — a 4K YouTube download legitimately saves as `.webm`); audio-only choices
transcode to MP3 with the thumbnail embedded as cover art.

## Scope

- **Android only**, `minSdk 24` (Chaquopy's floor), ABIs `arm64-v8a` and `x86_64`
  (Python 3.12 has no 32-bit ARM build).
- Package id `dev.koulei.woofer`. Proprietary — see [LICENSE](LICENSE) and
  [THIRD_PARTY.md](THIRD_PARTY.md).

## Prerequisites

| Need | Notes |
| --- | --- |
| Flutter | 3.47.1 stable (Dart 3.13) |
| JDK 17–24 | Java/Kotlin targets are 17 (CI uses Temurin 17). **Gradle 8.14 cannot run on JDK 25** — see below |
| Android SDK | Platform `android-37.0` (`compileSdk 37`) and build-tools; `adb` is not on PATH on the dev machine |
| Python 3.12 | **Chaquopy's build toolchain requires exactly 3.12.** `uv python install 3.12` is the easy way |
| `app/android/local.properties` | Gitignored. Flutter writes `sdk.dir` and `flutter.sdk`; you add `chaquopy.buildPython=<path to a Python 3.12>` (`uv python find 3.12`) if 3.12 isn't your default `python` |

## Build, test, run

All from `app/`:

```bash
flutter pub get
flutter analyze && flutter test                  # Dart tests + analyzer
flutter run                                      # connected device/emulator
flutter build apk --profile
flutter build apk --release                      # signed with key.properties if present
flutter build appbundle --release                # Play Store bundle
```

Native and Python tests:

```bash
cd app/android && ./gradlew :app:testDebugUnitTest   # Kotlin (incl. Robolectric)
# Windows hosts skip the 3 FileProvider file-path cases (androidx matches roots
# with a literal '/'); they run on the Linux CI job.

cd app/android/app                                   # Python bridge, offline
uv run --python 3.12 --with-requirements requirements.txt --with pytest \
  python -m pytest src/test/python
```

CI (`.github/workflows/ci.yml`) runs the same three suites plus a profile build.

### Release signing

`app/android/key.properties` + `upload-keystore.jks` are gitignored. With them,
`flutter build … --release` signs with the upload key; without them (fresh clone,
CI) it falls back to the debug key so the build still works. Back both files up —
losing the keystore means losing the ability to update the published app.

### Versioning

Bump `version:` in `app/pubspec.yaml` (`1.0.0+1` = semver `+` build number). It
flows to the Android `versionName`/`versionCode` and to Settings → About, which
also shows the bundled yt-dlp version.

## Common setup failures

- **A bare `./gradlew` fails with just `25.0.2`** — Gradle 8.14 can't run on JDK 25
  (`JAVA_HOME` points at one). `flutter build` is unaffected because Flutter uses
  Android Studio's bundled JDK; for direct Gradle runs set
  `JAVA_HOME` to that (`…/Android Studio/jbr`) or any JDK 17–24.
- **`Couldn't find Python 3.12`** — set `chaquopy.buildPython` in `local.properties`.
- **`Python 3.12 is not available for the ABI 'armeabi-v7a'`** — `gradle.properties`
  must keep `disable-abi-filtering=true`.
- **Python DNS fails ("No address associated with hostname")** — the process must be
  bound to the active network; `YtdlpBridge` does this before each call.
- **`flutter build appbundle` says "failed to strip debug symbols"** — the Android
  SDK *cmdline-tools* component is missing (`flutter doctor` reports it); Flutter's
  post-build check needs it. Install it from Android Studio's SDK Manager (SDK
  Tools), then run `flutter doctor --android-licenses`. (The `.aab` itself is still
  built, but the command exits 1.)
- **`adb devices` shows `unauthorized`** — `adb kill-server && adb start-server`, then
  accept the prompt on the phone.

More detail: [app/android/CHAQUOPY.md](app/android/CHAQUOPY.md) (Chaquopy, the
tested toolchain, the yt-dlp update policy) and
[app/android/FOREGROUND_SERVICE.md](app/android/FOREGROUND_SERVICE.md) (how a
download survives the app being backgrounded).

## Repository layout

```
app/                    Flutter app (the whole product)
  lib/{ui,state,services,models}
  android/              Gradle project, Kotlin host, Python bridge (src/main/python)
  android/app/src/test  Kotlin + Python tests (Python tests are not shipped in the APK)
design/                 Brand source: identity assets, guidelines, Inter font files
PROJECT_TODO.md         Working backlog
CLAUDE.md               Contributor/agent guide (architecture, gotchas)
```

`design/` is kept in Git deliberately (~10 MB packed): it is the brand source of
truth and only the six Inter weights in `app/fonts/` ship in the app.

Report security issues per [SECURITY.md](SECURITY.md); release history is in
[CHANGELOG.md](CHANGELOG.md).
