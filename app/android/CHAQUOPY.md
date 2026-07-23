# On-device yt-dlp via Chaquopy

The `ytdlp` MethodChannel runs [yt-dlp](https://github.com/yt-dlp/yt-dlp) in an
embedded CPython interpreter ([Chaquopy](https://chaquo.com/chaquopy/)) — no
server. The Dart side is [`lib/services/ytdlp_extractor.dart`](../lib/services/ytdlp_extractor.dart);
the Python is [`app/src/main/python/ytdlp_bridge.py`](app/src/main/python/ytdlp_bridge.py).

## Build changes

| File | Change | Why |
| --- | --- | --- |
| `settings.gradle.kts` | Added `id("com.chaquo.python") version "17.0.0" apply false` to the `plugins {}` block. | Declares the Chaquopy plugin (from `mavenCentral()`). **17.0.0**, not 16.x: 16.x can't find AGP under Flutter's plugins-DSL and fails with `Failed to find plugin com.android.tools.build:gradle`; 17.0.0 detects AGP through the plugins DSL, so no buildscript-classpath hack is needed. |
| `app/build.gradle.kts` | Applied `id("com.chaquo.python")` (after the Android plugin, before Flutter's). | Enables the `chaquopy {}` DSL and bundles Python. |
| `app/build.gradle.kts` | **`minSdk` 24** (was `flutter.minSdkVersion`). | Chaquopy requires API 24+. The one install-base change — devices below Android 7.0 are dropped. |
| `app/build.gradle.kts` | `defaultConfig { ndk { abiFilters += listOf("arm64-v8a", "x86_64") } }` — **no `armeabi-v7a`**. | Chaquopy's Python 3.12 has no 32-bit ARM build; including it fails with `Python 3.12 is not available for the ABI 'armeabi-v7a'`. Every current device is arm64. |
| `gradle.properties` | `disable-abi-filtering=true`. | Flutter otherwise force-overrides `abiFilters` to all ABIs (incl. armeabi-v7a), re-breaking Chaquopy. This opt-out makes Flutter honor the `abiFilters` above (see `FlutterPlugin.configureAbiWithoutSplits`). |
| `app/build.gradle.kts` | `chaquopy { defaultConfig { version = "3.12"; buildPython(<local.properties path>); pip { install("yt-dlp") } } }`. | Pins Python 3.12 and pip-installs yt-dlp at build time (pure Python, no NDK compile). `buildPython` is read from `local.properties` — see below. |
| `AndroidManifest.xml` | Added `INTERNET` **and `ACCESS_NETWORK_STATE`**. | yt-dlp fetches over the network; `ACCESS_NETWORK_STATE` lets us read the active network to bind the process (below). |
| `MainActivity.kt` | `Python.start(AndroidPlatform(this))` + the `ytdlp` channel. | Boots the interpreter and wires the two methods. |
| `MainActivity.kt` | `ConnectivityManager.bindProcessToNetwork(activeNetwork)` before each Python network call. | **Critical.** Android auto-binds Java/Flutter sockets to a network, but Python's C sockets are unbound, so their DNS fails with `[Errno 7] No address associated with hostname`. Binding the process fixes Python DNS. Re-bound per call to follow Wi-Fi ↔ cellular switches. |
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

## Channel contract (`ytdlp`)

- `extract_info(url)` → `{"ok":true,"data":<VideoInfo>}` | `{"ok":false,"code","message"}`
- `download(url, format_id, dir?)` → `{"ok":true,"path":"…"}` | error envelope
- native → Dart `onProgress({received,total})` fires during a download

`data` uses our exact snake_case keys, so `VideoInfo.fromJson` parses it and the
result is model-interchangeable with `YoutubeExtractor`.

## Caveats

- **AGP alignment:** Chaquopy trails AGP releases. This project (AGP 8.11) needs
  Chaquopy **17.0.0**; on 16.x the plugin fails to apply. If a future AGP bump
  breaks the sync, check for a newer Chaquopy first.
- **No merging in yt-dlp:** yt-dlp can't merge video-only + audio without ffmpeg
  on the device PATH. Pass a single `format_id`; merging a video-only + audio
  selection is the app's `MediaProcessor` (ffmpeg_kit) step, not yt-dlp's.
- **APK size:** the interpreter + stdlib + yt-dlp + ffmpeg push the profile APK to
  ~155 MB per ABI. Ship an app-bundle (`flutter build appbundle`) so Play delivers
  a single-ABI split (~half that) rather than a universal APK.
- **yt-dlp can't subprocess:** on Android it can't `exec` ffmpeg/ffprobe (blocked),
  so it logs a benign `_posixsubprocess` signal and continues without them. Fine —
  merging/transcoding is `MediaProcessor` (ffmpeg_kit), not yt-dlp's job.
- **Verified on device** (Samsung, Android 16): share a YouTube link → youtube_explode
  429s → yt-dlp fallback extracts 27 formats → download an audio format → ffmpeg_kit
  transcodes to a 192 kbps MP3 → saved to `Download/woofer/…` via MediaStore.
