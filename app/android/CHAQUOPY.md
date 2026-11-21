# On-device yt-dlp via Chaquopy

The `ytdlp` MethodChannel runs [yt-dlp](https://github.com/yt-dlp/yt-dlp) in an
embedded CPython interpreter ([Chaquopy](https://chaquo.com/chaquopy/)) — no
server. The Dart side is [`lib/services/ytdlp_extractor.dart`](../lib/services/ytdlp_extractor.dart);
the Kotlin side is [`YtdlpBridge.kt`](app/src/main/kotlin/dev/koulei/woofer/YtdlpBridge.kt);
the Python is [`app/src/main/python/ytdlp_bridge.py`](app/src/main/python/ytdlp_bridge.py).

## Build changes

| File | Change | Why |
| --- | --- | --- |
| `settings.gradle.kts` | `id("com.chaquo.python") version "17.2.0" apply false` in the `plugins {}` block. | Declares the Chaquopy plugin (from `mavenCentral()`). **17.x**, not 16.x: 16.x can't find AGP under Flutter's plugins-DSL and fails with `Failed to find plugin com.android.tools.build:gradle`; 17.x detects AGP through the plugins DSL, so no buildscript-classpath hack is needed. |
| `app/build.gradle.kts` | Applied `id("com.chaquo.python")` (after the Android plugin, before Flutter's). | Enables the `chaquopy {}` DSL and bundles Python. |
| `app/build.gradle.kts` | **`minSdk` 24** (was `flutter.minSdkVersion`). | Chaquopy requires API 24+. The one install-base change — devices below Android 7.0 are dropped. |
| `app/build.gradle.kts` | `defaultConfig { ndk { abiFilters += listOf("arm64-v8a", "x86_64") } }` — **no `armeabi-v7a`**. | Chaquopy's Python 3.12 has no 32-bit ARM build; including it fails with `Python 3.12 is not available for the ABI 'armeabi-v7a'`. Every current device is arm64. |
| `gradle.properties` | `disable-abi-filtering=true`. | Flutter otherwise force-overrides `abiFilters` to all ABIs (incl. armeabi-v7a), re-breaking Chaquopy. This opt-out makes Flutter honor the `abiFilters` above (see `FlutterPlugin.configureAbiWithoutSplits`). |
| `app/build.gradle.kts` | `chaquopy { defaultConfig { version = "3.12"; buildPython(<local.properties path>); pip { install("-r", "requirements.txt") } } }`. | Pins Python 3.12 and pip-installs the **pinned** yt-dlp from [`app/requirements.txt`](app/requirements.txt) at build time (pure Python, no NDK compile). `buildPython` is read from `local.properties` — see below. |
| `app/build.gradle.kts` | `compileSdk = 37`; the old per-plugin `compileSdkVersion(36)` workaround in `android/build.gradle.kts` is gone. | `receive_sharing_intent` and `permission_handler_android` 14 need 37. AGP 8.11.1 now resolves the installed `android-37.0` platform, so the workaround is not needed. |
| `AndroidManifest.xml` | Added `INTERNET` **and `ACCESS_NETWORK_STATE`**. | yt-dlp fetches over the network; `ACCESS_NETWORK_STATE` lets us read the active network to bind the process (below). |
| `YtdlpBridge.kt` | `Python.start(AndroidPlatform(appContext))` + the `ytdlp` channel, created once per process and re-attached to the cached Flutter engine on every Activity recreation. | Boots the interpreter and wires the methods. (Originally in `MainActivity`; split out so the bridge is process-scoped, not tied to an Activity.) |
| `YtdlpBridge.kt` | `ConnectivityManager.bindProcessToNetwork(activeNetwork)` before each Python network call. | **Critical.** Android auto-binds Java/Flutter sockets to a network, but Python's C sockets are unbound, so their DNS fails with `[Errno 7] No address associated with hostname`. Binding the process fixes Python DNS. Re-bound per call to follow Wi-Fi ↔ cellular switches. |
| `pubspec.yaml` | `ffmpeg_kit_flutter` → **`ffmpeg_kit_flutter_new` (full-gpl)**. | The original arthenica binaries were pulled from Maven Central (404). The fork re-hosts them and ships `libmp3lame` for `toMp3`. |

## Build-time requirement: Python 3.12

Chaquopy 17 needs a **Python 3.12** toolchain on the build host to run pip (it
rejects other minor versions — e.g. a host default of 3.14 fails with
`Couldn't find Python 3.12`). If 3.12 isn't your default `python`, install a
standalone one and point Chaquopy at it via **`local.properties`** (gitignored,
per-machine) — `app/build.gradle.kts` reads the key and calls `buildPython(...)`:

```bash
uv python install 3.12          # or install Python 3.12 any other way
uv python find 3.12             # prints the interpreter path
```

```properties
# android/local.properties
chaquopy.buildPython=C:/Users/you/AppData/Roaming/uv/python/cpython-3.12-.../python.exe
```

CI puts Python 3.12 on `PATH` instead (no override needed).

## Channel contract (`ytdlp`)

- `extract_info(url)` → `{"ok":true,"data":<VideoInfo>}` | `{"ok":false,"code","message"}`
- `download(url, format_id, dir?)` → `{"ok":true,"path":"…"}` | error envelope
  (`CANCELLED` when the user cancelled)
- `cancel_download()` → `true`. Runs on its own thread, not the IO executor: that
  thread is blocked inside the download being stopped.
- `rebind_network()` → `true`. Re-binds the process after a Wi-Fi ↔ cellular switch.
- `version()` → the bundled yt-dlp release as a plain string (e.g. `2026.10.26`), or
  `null`. Also on its own thread. Shown in Settings → About.
- native → Dart `onProgress({received,total})` fires during a download

`data` uses our exact snake_case keys, so `VideoInfo.fromJson` parses it unchanged.

## yt-dlp update policy

yt-dlp breaks whenever a site changes, and an unpinned dependency meant two builds
of the same commit could ship different extractors. So:

- **The pin lives in one file:** [`app/requirements.txt`](app/requirements.txt)
  (`yt-dlp==YYYY.MM.DD`). Chaquopy installs it into the APK and CI's Python job
  installs the same file, so the tests run against what ships.
- **When to bump:** for every release, and within days of a site breaking (the
  YouTube bot gate is the usual cause — see the gotchas in `CLAUDE.md`).
- **How to bump:**
  1. Check the latest stable on PyPI (`pip index versions yt-dlp`) — not a `.dev` build.
  2. Edit `requirements.txt`.
  3. Run the Python suite (below) — it checks the bridge's contract against the new release.
  4. Build, and check `build/app/python/pip/<variant>/common/yt_dlp/version.py`.
  5. Smoke-test a real extraction + download on a device.
  6. Settings → About shows the bundled version; put it in the changelog.
- **Never** float it (`yt-dlp` with no pin) or add it to another file: the pin and
  the version shown in About must stay the single source of truth.

## Tests

```bash
# Python bridge — offline, against the pinned yt-dlp (from app/android/app):
uv run --python 3.12 --with-requirements requirements.txt --with pytest \
  python -m pytest src/test/python

# Kotlin, incl. Robolectric (from app/android; needs JAVA_HOME on a JDK 21–24):
./gradlew :app:testDebugUnitTest
```

The Python tests live in `src/test/python`, **not** `src/main/python`: Chaquopy
packages everything under `main`, and a test module there ships in the APK.

## Tested toolchain

Upgrade these **as a set** — Chaquopy trails AGP, and Flutter's Gradle plugin
constrains the rest. Last verified together on 2026-11-21 (build + all suites; not
yet on a device).

| Component | Version | Note |
| --- | --- | --- |
| Flutter / Dart | 3.47.1 / 3.13.1 | pinned in CI |
| Android Gradle Plugin | 8.11.1 | Chaquopy 17.2 supports 8.9–8.13 and 9.x |
| Gradle | 8.14 | |
| Kotlin | 2.2.20 | |
| Chaquopy | 17.2.0 | |
| Python (build + runtime) | 3.12 | exact match required |
| yt-dlp | pinned in `requirements.txt` | |
| `compileSdk` / `minSdk` / `targetSdk` | 37 / 24 / Flutter default | |
| JDK | 21 in CI; 21–24 locally | Robolectric needs 21+ for SDK 35; Gradle 8.14 can't run on JDK 25 |
| Robolectric / androidx.test core | 4.18.1 / 1.7.0 | test-only |

`gradle.properties` keeps `android.builtInKotlin=false` and `android.newDsl=false`
(Flutter's migrator opt-outs for AGP 9's changes).

**Known follow-up:** Flutter 3.47 warns on every build that it "will soon drop"
support for Gradle < 9.1.0, AGP < 9.0.1 and Kotlin < 2.3.20. Moving to that set
(Gradle 9.1, AGP 9, Kotlin 2.3.20) is a toolchain migration of its own — Chaquopy
17.2 lists AGP 9.x as supported — and needs a full build plus on-device test.
`--android-skip-build-dependency-validation` silences it meanwhile.

Gradle deprecation pass (`--warning-mode all`, 2026-11-21): none from our scripts
or Chaquopy. Every warning is in third-party plugin build files (`jni`,
`jni_flutter`, `permission_handler_android`, `receive_sharing_intent`,
`sqflite_android`) and is theirs to fix.

## Caveats

- **AGP alignment:** Chaquopy trails AGP releases; 16.x can't apply under
  Flutter's plugins DSL. If a future AGP bump breaks the sync, check for a newer
  Chaquopy first.
- **No merging in yt-dlp:** yt-dlp can't merge video-only + audio without ffmpeg
  on the device PATH. Pass a single `format_id`; merging a video-only + audio
  selection is the app's `MediaProcessor` (ffmpeg_kit) step, not yt-dlp's.
- **APK size:** the interpreter + stdlib + yt-dlp + ffmpeg make a universal profile
  APK ~183 MB (arm64-v8a + x86_64). Ship an app-bundle (`flutter build appbundle`)
  so Play delivers a single-ABI split (~half that) rather than a universal APK.
- **yt-dlp can't subprocess:** on Android it can't `exec` ffmpeg/ffprobe (blocked),
  so it logs a benign `_posixsubprocess` signal and continues without them. Fine —
  merging/transcoding is `MediaProcessor` (ffmpeg_kit), not yt-dlp's job.
- **Last verified on a device** (Samsung, Android 16): extract formats → download an
  audio format → ffmpeg_kit transcodes to a 192 kbps MP3 → saved to
  `Download/woofer/…` via MediaStore. **Not re-verified** since the 2026-11
  dependency upgrades (Chaquopy 17.2, Riverpod 3, permission_handler 13,
  ffmpeg_kit 4.7, compileSdk 37): the phone is unauthorized in ADB.
