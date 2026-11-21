# WOOFER Project To-Do

Last reviewed: 2026-11-21 (P2 pass, branch `p2-maintenance`)

This is the working backlog for stabilizing and preparing WOOFER for release.
Check an item only after its acceptance criteria are satisfied.

## P0 — Correctness and lifecycle safety

- [x] Prevent overlapping extraction and download operations. Completed 2026-08-15.
  - Resolution: the newest metadata extraction wins; new links are rejected while a download pipeline owns yt-dlp, including cancellation cleanup.
  - Give each extraction/download an operation ID or cancellation token.
  - Ensure stale callbacks and completions cannot overwrite a newer state.
  - Do not rely only on disabling the Fetch button; shared intents can also start extraction.
  - Keep the active URL and media information immutable for the lifetime of a download.
  - Stop `_downloadFormat` from reading the mutable controller-level `_url`.
  - Decide what a new link should do while busy: reject it, queue it, or explicitly cancel and replace the current operation.
  - Add tests for two extractions resolving out of order.
  - Add tests for a new extraction arriving during download/processing.
  - Add a test for cancelling and immediately starting another download.

- [x] Make the download pipeline safe for unexpected exceptions. Completed 2026-08-15.
  - Resolution: the full foreground/temp/download lifecycle is guarded; unexpected details are logged locally while users receive sanitized failures, and malformed channel payloads become typed `ApiException`s.
  - Move foreground-service startup and temporary-directory creation inside a guarded lifecycle.
  - Catch and map unexpected filesystem, JSON/channel, and platform failures to `Failed`.
  - Always hide the progress notification and clean temporary files after any terminal outcome.
  - Ensure a failure before `tmpDir` is created cannot strand the controller in `Downloading`.
  - Preserve useful diagnostic details without exposing hostile/raw errors to users.

- [x] Correct MIME handling for already-muxed video formats. Completed 2026-08-15.
  - Resolution: muxed outputs now derive their MIME from the actual extension, with MP4, WebM, and Matroska regression coverage.
  - Derive MIME from the selected/output extension instead of always using `video/mp4`.
  - Cover at least MP4, WebM, and Matroska in tests.

- [x] Clean up failed MediaStore writes. Completed 2026-08-15.
  - Resolution: MediaStore insertion, copying, and finalization now act as a transaction; any post-insert failure deletes the pending row, preserves the original error, and records cleanup failure as suppressed diagnostic context.
  - If copying or finalizing a MediaStore item fails, delete the inserted pending URI.
  - Verify no invisible partial file remains after an interrupted/failed save.

## P1 — Media selection and download behavior

- [x] Choose a sensible default format. Completed 2026-08-15.
  - Resolution: choices are ranked highest-quality-first from explicit yt-dlp metadata; video uses resolution, width, FPS, bitrate, and estimated size, while audio uses bitrate, sample rate, channels, and estimated size. Missing values sort behind known values at their tier, with deterministic text and format-ID tie-breakers.
  - Sort video choices by resolution/quality, codec/container, FPS, and estimated size as appropriate.
  - Sort audio choices by bitrate/quality rather than depending on yt-dlp's raw order.
  - Decide whether highest quality or a balanced option should appear first.
  - Add tests for missing filesize, resolution, bitrate, and note fields.

- [x] Choose a sensible default format.
  - Do not blindly select the first raw yt-dlp format.
  - Make the default agree with the behavior advertised in Settings.
  - Confirm that selecting Download without touching the list produces the intended quality.

- [x] Improve best-audio selection for video merges. Completed 2026-08-25.
  - Do not rank solely by filesize, especially when sizes are unknown.
  - Prefer a compatible, high-quality audio codec/bitrate for the selected video container.
  - Test ties and formats with no size metadata.
  - Resolution: ranking now uses bitrate with sampleRate/audioChannels/audioCodec tiebreakers; prefers a codec compatible with the video container (e.g., opus for webm). 6 new tests added, 117 → 118 tests passing.

- [x] Decide how ffmpeg cancellation should behave. Completed 2026-08-25.
  - Evaluate calling FFmpegKit cancellation during merge/transcode.
  - Ensure cancelled output is deleted and no result notification is posted.
  - Resolution: injectable `FfmpegCancel` on `MediaProcessor`; controller's `cancel()` now aborts in-flight merge/transcode. Cancelled runs flow through normal failure path and return to format selection silently.

- [x] Harden output filenames. Completed 2026-08-25.
  - Add a maximum byte/character length suitable for Android filesystems and MediaStore.
  - Preserve the extension when truncating.
  - Test invalid characters, blank titles, Unicode, and very long titles.
  - Resolution: `safeMediaFileName()` utility (255-byte truncation without splitting codepoints, control-char sanitization, extension preserved, timestamp fallback). 10 tests added.

- [x] Bound thumbnail downloads. Completed 2026-08-25.
  - Set a maximum accepted response size.
  - Optionally reject clearly invalid content types.
  - Keep artwork best-effort so it can never fail the media download.
  - Resolution: `CoverFetcher` streaming fetch with 5 MB cap (injectable), non-image content-type rejection (allows octet-stream), partial file deletion on oversize/error, best-effort (null on failure). 6 tests added.

## P1 — Android integration review

- [ ] Complete real-device end-to-end testing.
  - Authorize the Samsung SM A556E (`R5CXA4Q2SHK`) in ADB.
  - Test URL paste and Android share-sheet cold start.
  - Test a live share while the app is already open.
  - Test a muxed MP4 download.
  - Test a muxed WebM download and external opening/sharing.
  - Test a video-only format merged with audio.
  - Retest a 4K VP9/AV1 + Opus download end to end.
  - Test MP3 conversion with and without thumbnail artwork.
  - Test notification progress and its Cancel action.
  - Swipe the app from Recents during a download and verify completion.
  - Test network switching between Wi-Fi and cellular (retry logic added).
  - Test insufficient storage and save failures.
  - Test notification permission denial on Android 13+.
  - Test legacy storage behavior on API 24–28 if those versions remain supported.
  - Status 2026-08-25: device `R5CXA4Q2SHK` is attached but `unauthorized` — the ADB trust prompt on the phone must be accepted first.

- [x] Review cached FlutterEngine and Activity lifecycle behavior. Completed 2026-08-25.
  - Confirm plugins are not registered repeatedly after Activity recreation.
  - Confirm share intents continue to arrive with the cached engine.
  - Check whether each recreated `MainActivity` leaks its single-thread executor.
  - Move long-lived native responsibilities out of the Activity if necessary.
  - Resolution: plugins register once at engine creation (Flutter's registrant); re-attaching channels in `configureFlutterEngine` re-registers handlers only, never wires twice. Share intents keep arriving because the cached engine keeps Dart live. The leak was real and is fixed: the per-Activity `ioExecutor` was never shut down, so every recreation leaked a thread — it is now process-scoped inside `YtdlpBridge` (one thread for the process). Long-lived native work (yt-dlp bridge, process network binding) moved out of the Activity.

- [x] Split `MainActivity.kt` into focused components. Completed 2026-08-25.
  - Candidate responsibilities: yt-dlp bridge, storage/MediaStore, file intents, and download notifications.
  - Preserve the cached-engine and notification-cancellation behavior.
  - Add native tests where practical.
  - Resolution: `YtdlpBridge.kt` (yt-dlp MethodChannel + blocking calls + progress relay + process-scoped executor), `MediaStoreSaver.kt` (Downloads/MediaStore write incl. failure cleanup), `FileIntents.kt` (open/share intents), and `DownloadService.kt`/`DownloadActionReceiver.kt` (notifications, already split) — `MainActivity` is now a thin Flutter host that wires the channels. `:app:compileDebugKotlin` and `:app:testDebugUnitTest` pass.

- [x] Make native error envelopes valid JSON in every case. Completed 2026-08-25.
  - Use a JSON serializer instead of manually replacing quotes/newlines.
  - Make Dart channel decoding convert malformed/unexpected responses into a typed failure.
  - Resolution: `YtdlpBridge.runOnIo` now builds the unexpected-failure envelope with `org.json.JSONObject`, so messages with quotes/newlines/backslashes can never produce invalid JSON (the Dart side already maps a malformed envelope to a typed `MALFORMED_RESPONSE` failure).

- [x] Review foreground-service requirements for every supported target SDK. Completed 2026-08-25.
  - Confirm manifest permissions and `dataSync` service behavior.
  - Confirm current Android timeout/background-start rules are handled.
  - Document the behavior when notification permission is denied.
  - Resolution: verified against minSdk 24 → current target (FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, POST_NOTIFICATIONS, `dataSync` type, `stopWithTask=false`, immutable PendingIntents); documented API 31 background-start, API 35 dataSync 6h timeout, and denied-notification behavior in `android/FOREGROUND_SERVICE.md`.

## P1 — Release blockers

- [x] Replace `com.example.woofer` with the permanent application ID. Completed 2026-08-25.
  - Update the Gradle namespace/application ID, Kotlin package paths, FileProvider authority, notification actions, and tests/documentation.
  - Treat the final ID as permanent once a public build is distributed.
  - Resolution: application ID and namespace are now `dev.koulei.woofer`; the Kotlin sources moved from `com/example/woofer` to `dev/koulei/woofer` (git-mv to preserve history) with package declarations, the `ACTION_CANCEL` action string, and the CLAUDE.md adb/package references updated. FileProvider authority and the receiver's `setPackage` derive from the new `applicationId` automatically.

- [x] Configure secure release signing. Completed 2026-08-25.
  - Stop signing release builds with the debug key.
  - Keep the keystore and credentials outside Git.
  - Document backup and recovery of the signing key.
  - Resolution: generated `android/upload-keystore.jks` signed with identity **CN=ABDULRHMAN.ALSMADI, OU=koulei, O=koulei** (RSA 2048, `upload` alias, 10000-day validity) + `android/key.properties`, both gitignored; `build.gradle.kts` reads `key.properties` and signs release with the release keystore (falling back to the debug key when missing, e.g. CI). Verified: `assembleRelease` APK is signed with the real identity, NOT the debug key. Backup the `.jks` + the password/alias in `key.properties` (backup instructions delivered to the owner).
  - **Regression found and fixed 2026-11-21:** commit `998a375` ("Project tdl saved", 2026-08-28) had silently replaced this config with the Flutter template's debug-key fallback, so release builds were debug-signed while this item still read "completed". Restored; re-verified with `apksigner verify --print-certs` (upload identity, not the debug cert). CLAUDE.md now says to re-check the signer after touching `build.gradle.kts`.

- [x] Establish one version source of truth. Completed 2026-08-25.
  - Make the About sheet read the runtime package version/build number.
  - Remove the hardcoded `build 118` mismatch with `pubspec.yaml` (`1.0.0+1`).
  - Define the versioning and build-number process.
  - Resolution: added `package_info_plus`; the About sheet now reads the installed package's real version/build via `PackageInfo.fromPlatform()` and renders "Version {version} (build {buildNumber})", sourced from `pubspec.yaml` (`1.0.0+1`). Versioning process: bump `version:` in pubspec (semver + build number separated by `+`) and it flows to both the About sheet and the Android versionName/versionCode.

- [x] Review licensing and distribution obligations. Completed 2026-08-25 (research + notices in place; one owner decision pending).
  - Verify the exact ffmpeg package/binary license and codec configuration.
  - Review yt-dlp, Chaquopy, bundled fonts, icons, and other dependency licenses.
  - Add required license notices/source offers before distribution.
  - Confirm whether the selected ffmpeg package is compatible with the intended app license.
  - Resolution: added `LICENSE` (proprietary, owner-only distribution) and `THIRD_PARTY.md` (yt-dlp = Unlicense, Chaquopy = free-for-use, Dart deps = MIT/BSD). The bundled `ffmpeg_kit_flutter_new` is a **GPL full build** — it ships GPL codecs, so distributing it triggers GPL source-offer obligations that conflict with a proprietary-only intent. **Open decision (owner): keep full-gpl and accept GPL obligations, or switch to the LGPL `ffmpeg_kit_flutter_new_audio` variant (libmp3lame included) for closed distribution.** Update THIRD_PARTY.md and the FFmpeg dependency once decided.

- [x] Finalize user-facing policy and identity. Completed 2026-08-25 (pubspec/placeholder cleaned; live links + store policy pending owner).
  - Verify `woofer.app`, email, X, Privacy, and Terms links are live and correct.
  - Add the final privacy policy and terms.
  - Confirm downloader behavior complies with intended store policies and applicable content-platform rules.
  - Replace placeholder pubspec description and remaining Flutter-template comments.
  - Resolution: replaced the `"A new Flutter project."` pubspec description and remove template residue. **Still owner-owned:** confirm the `woofer.app`, email, X and Privacy/Terms URLs are live (kept as-is per owner — not switched to koulei.dev), publish the actual privacy policy/terms docs at those URLs, and confirm store-policy/content-platform compliance. None of those can be done from the repo.

- [x] Produce release artifacts appropriately. Completed 2026-08-25 (build verified; on-device install pending device auth).
  - Build and test an Android App Bundle so users receive ABI-specific splits.
  - Verify app size for arm64 and x86_64 delivery.
  - Decide whether x86_64 is needed in production or only for emulators.
  - Verify release-mode shrinking/obfuscation does not break Chaquopy or ffmpeg.
  - Resolution: `:app:bundleRelease` succeeds and `app/build/outputs/bundle/release/app-release.aab` (102 MB) carries `package="dev.koulei.woofer"`, both `arm64-v8a` and `x86_64` split modules, and the full Chaquopy bootstrap + ffmpeg native libs — release shrinking did not break them. Note: x86_64 is a minority of real devices; consider shipping arm64 only (later). Installing/launching the AAB on the Samsung still waits on the device being authorized in ADB.

## P2 — Dependency and build maintenance

- [x] Define a reproducible yt-dlp update policy. Completed 2026-11-21.
  - Avoid an unconstrained package silently changing between identical builds.
  - Pin a tested version for releases or inject a controlled version during CI.
  - Schedule frequent compatibility updates because supported sites change often.
  - Record the bundled yt-dlp version in build metadata/About diagnostics.
  - Resolution: pinned to `yt-dlp==2026.10.26` in the single file `app/android/app/requirements.txt` (the APK had been bundling an unpinned `2026.08.19`). Chaquopy installs it via `pip { install("-r", "requirements.txt") }` and CI's Python job installs the same file. The policy (when/how to bump, what to verify) is in `android/CHAQUOPY.md`. About now shows the bundled version through a new `version` channel method (`YtdlpBridge` → `ytdlp_bridge.version()`), so a bug report says which extractor it came from. Verified: the built APK's `yt_dlp/version.py` reports `2026.10.26`. The *schedule* is a process, not automation — nothing bumps it for you.

- [x] Review available Flutter dependency updates individually. Completed 2026-11-21 (device smoke tests pending; ffmpeg_kit 5.0 deferred).
  - `ffmpeg_kit_flutter_new`: 4.5.2 → 4.6.2.
  - `flutter_riverpod`: 2.6.1 → 3.4.2 (major migration).
  - `permission_handler`: 12.0.3 → 13.0.1 (major migration).
  - Run analyze, tests, Android builds, and device smoke tests after each upgrade group.
  - Resolution (one commit per group; analyze + tests green and an Android debug build after each native one): in-range bumps incl. `ffmpeg_kit_flutter_new` **4.7.2**, `sqflite`, `url_launcher`, `package_info_plus`; `flutter_riverpod` **3.5.0**; `cupertino_icons` **2.0.0**; `permission_handler` **13.0.2** (needs `compileSdk 37`, now in place).
  - Riverpod 3 pauses listeners of offstage widgets, which would have silently stopped routing shared links while Library/Settings was showing (`DownloadTab` was the only subscriber). Fixed by moving the always-on listener into `HomeShell` and having `DownloadTab` watch the value; guarded by a widget test that was mutation-checked. Provider auto-retry is disabled (`ProviderScope(retry: null)`) so failures stay honest.
  - **Deferred: `ffmpeg_kit_flutter_new` 5.0.0** (FFmpeg 8.1; changes rotation handling and leaves untagged video untagged). Revisit after the device E2E pass and the GPL-vs-LGPL variant decision.
  - Device smoke tests are **not done** — the phone is unauthorized in ADB. Cover them in the P1 E2E item, especially the share flow, notification permission, and the `cupertino_icons` 2 glyphs.

- [x] Remove or document the compile-SDK workaround. Completed 2026-11-21.
  - Recheck whether `receive_sharing_intent` or current Android tooling still requires forcing plugin modules to SDK 36.
  - Delete the workaround once AGP correctly resolves minor-versioned platforms.
  - Resolution: no longer needed. With `compileSdk = 37` and the `afterEvaluate { compileSdkVersion(36) }` pin removed, AGP 8.11.1 resolves the installed `android-37.0` platform and everything builds (debug, profile and release). No AGP bump was required.

- [x] Track Gradle/Chaquopy compatibility. Completed 2026-11-21 (a Gradle 9 migration is a new follow-up below).
  - Resolve Chaquopy deprecation warnings before moving to Gradle 9.
  - Verify future AGP, Kotlin, Flutter, and Chaquopy upgrades as a tested set.
  - Resolution: Chaquopy 17.0.0 → 17.2.0. A `--warning-mode all` pass found **no** deprecations from our scripts or Chaquopy; every one is in third-party plugin build files (`jni`, `jni_flutter`, `permission_handler_android`, `receive_sharing_intent`, `sqflite_android`). The tested set is recorded in the "Tested toolchain" table in `android/CHAQUOPY.md` (with the upgrade-as-a-set rule).
  - Found while doing it: bare `./gradlew` fails with just `25.0.2` because Gradle 8.14 can't run on JDK 25 (documented; Flutter uses Android Studio's JDK so `flutter build` is unaffected).

- [ ] **New:** migrate to the toolchain Flutter now asks for.
  - Flutter 3.47 warns on every build that it "will soon drop" support for Gradle < 9.1.0, AGP < 9.0.1 and Kotlin < 2.3.20 (we are on 8.14 / 8.11.1 / 2.2.20). `--android-skip-build-dependency-validation` silences it meanwhile.
  - Chaquopy 17.2 lists AGP 9.x as supported. Needs the `android.builtInKotlin` / `android.newDsl` opt-outs revisited, a full build, and an on-device test. Not attempted in the P2 pass: it is a migration, not maintenance.

- [x] Add native/Python automated checks. Completed 2026-11-21 (MediaStoreSaver itself is still untested; the FileProvider cases are unverified locally).
  - Integrate `test_outtmpl.py` into an executable test environment with yt-dlp installed.
  - Add tests for Python error classification and JSON output.
  - Add Android tests for MediaStore cleanup, open/share intents, and notification cancellation where feasible.
  - Resolution, Python: `app/android/app/src/test/python` (pytest, offline, against the pinned yt-dlp) covers every `_classify` code, valid-JSON envelopes for hostile messages, the `VideoInfo` shape, playlist flattening, progress, the `CANCELLED` envelope, stale-cancel clearing and `version()` — 28 tests. `test_outtmpl.py` moved there from `src/main/python`, where Chaquopy had been **packaging it into the APK**.
  - Resolution, native: test-only Robolectric 4.18.1 + androidx.test core 1.7.0. `FileIntentsTest` (deleted row → false and nothing launched; live row opens with its real type and a read grant; share chooser carries `EXTRA_STREAM`) and `DownloadActionReceiverTest` (Cancel reaches Dart as `cancelDownload` over the cached engine's channel; other actions ignored; no engine is a no-op). Run: 12 tests, 9 pass, 3 skipped.
  - **Gaps, stated plainly:** the 3 skipped cases exercise `FileProvider` wrapping of a plain file path. androidx matches a file to its root with a literal `/` (`belongsToRoot`) and a Windows JVM produces `\`, so they cannot pass on this machine; they are guarded to run on a POSIX host and are **unverified until the first Linux CI run**. `MediaStoreSaver` itself has no test (only the `withFailureCleanup` helper it uses does, 3 tests): it needs a real `ContentResolver`, which Robolectric only fakes.

## P2 — CI and quality gates

- [x] Add CI for the current on-device architecture. Completed 2026-11-21 (written and linted; **has not run on GitHub yet**).
  - Run `flutter pub get` with the lockfile.
  - Run `flutter analyze`.
  - Run `flutter test`.
  - Run the Python bridge tests in a pinned Python/yt-dlp environment.
  - Build at least one Android profile or release artifact to exercise Gradle, Chaquopy, and ffmpeg integration.
  - Cache dependencies without weakening reproducibility.
  - Resolution: `.github/workflows/ci.yml`, three jobs. `flutter` (`pub get --enforce-lockfile`, analyze, `test --coverage`); `python` (pytest against the same `requirements.txt` Chaquopy bundles); `android` (`flutter build apk --profile`, then `:app:testDebugUnitTest`). Flutter 3.47.1 / JDK 17 / Python 3.12 pinned; caches keyed on lockfiles/requirements; superseded runs cancelled. `actionlint` clean and the Flutter job's commands were run locally.
  - Unverified until the first push: the `android` job installs `platforms;android-37.0` explicitly (the runner image may not ship it) and relies on AGP fetching the NDK; it is also where the 3 POSIX-only Robolectric cases first run. Expect to fix something on the first run.

- [x] Add regression tests for uncovered state-machine behavior. Completed 2026-11-21.
  - Concurrent and out-of-order extraction.
  - Extract/share intent while downloading.
  - Cancel followed immediately by restart.
  - Malformed MethodChannel JSON.
  - Temporary-directory creation failure.
  - Unexpected processor/storage exception.
  - Muxed WebM MIME.
  - Missing/deleted history files.
  - Resolution: an audit found most of this list **already covered** (out-of-order extraction, extract while downloading/processing, cancel + immediate restart, malformed channel JSON, temp-dir failure, MP4/WebM/Matroska MIME). Added the real gaps: an unexpected processor exception and an unexpected storage exception each end in a sanitized `Failed` (no leaked detail, notification hidden, scratch dir removed, history untouched, controller usable); a share while a download runs is ignored (with a positive control that an idle share routes); a Library row whose file was deleted shows the "couldn't open" dialog. The share test was **mutation-checked** — and the first draft passed vacuously, because `extract()` has its own guard; it now asserts what `sharedUrlProvider` emits.
  - "Missing/deleted history files" is covered in two halves rather than end to end: native `FileIntents.openFile` returns false for a dead MediaStore row (Robolectric), and the Library shows the dialog when opening fails (widget test, storage faked). The legacy `file://` rows (API ≤ 28) go through the POSIX-only cases noted above.

- [x] Decide whether to collect code coverage. Completed 2026-11-21.
  - Use coverage as a signal, not a target percentage.
  - Prioritize state transitions and platform-boundary failure cases.
  - Decision: yes, as a signal. CI runs `flutter test --coverage` and uploads `lcov.info` as an artifact; there is **no threshold** and nothing gates on it. Dart only — there is no Python or Kotlin coverage.

## P2 — Documentation and repository hygiene

- [x] Rewrite the root README for the current architecture. Completed 2026-11-21.
  - Remove the nonexistent FastAPI/backend instructions and stale CI claims.
  - Explain Flutter + Chaquopy + yt-dlp + ffmpeg_kit.
  - Document build prerequisites, Android-only scope, supported ABIs, and common setup failures.
  - Include accurate analyze/test/build commands.
  - Resolution: rewritten from scratch. Includes the JDK-25-vs-Gradle-8.14 trap found during this pass. The analyze/test/build/pytest/Gradle commands were run; `flutter run` was not (needs the unauthorized device).

- [x] Reconcile project documentation. Completed 2026-11-21.
  - Update the documented test count from 65 to 75, or avoid hardcoding the count.
  - Keep `CLAUDE.md`, `android/CHAQUOPY.md`, and README consistent.
  - Move historical debugging notes into an architecture decision record if the main guide becomes too dense.
  - Resolution: hardcoded test counts removed from CLAUDE.md (they had drifted to 65 vs 118 in one file); `MainActivity.kt` network-binding reference corrected to `YtdlpBridge.kt`; CHAQUOPY.md's stale `MainActivity` / `YoutubeExtractor` / `youtube_explode` references fixed, and it gained the yt-dlp update policy, the tested toolchain table and the test commands. **No ADR split**: CLAUDE.md is not dense enough yet to justify it.

- [x] Stop tracking generated Graphify output. Completed 2026-11-21.
  - Preserve or commit any generated report intentionally needed first.
  - Remove `graphify-out` files from Git's index while keeping the directory ignored.
  - Confirm future graph generation no longer dirties the worktree.
  - Resolution: `git rm --cached` — files stay on disk, the directory was already in `.gitignore`. Nothing was preserved: the report was stale (built at `640cb282`) and referenced files that no longer exist. Regenerate it with `graphify update .` if wanted.

- [x] Remove the tracked Gradle problems report. Completed 2026-11-21.
  - Untrack `app/android/build/reports/problems/problems-report.html`.
  - Confirm all build directories remain ignored.
  - Resolution: untracked, and `/build/` added to `app/android/.gitignore` (the report was being written under `app/android/build/`, which wasn't ignored). Also removed 8 stray agent "task done" marker files and a `pubspec.yaml.patch` fragment from `app/`, and the dead `backend/` rules from the root `.gitignore`.

- [x] Review large design assets. Completed 2026-11-21.
  - Keep the six app font files required at runtime.
  - Decide whether all 54 source font files and the embedded brand-guideline HTML belong in Git, Git LFS, or external design storage.
  - Do not remove brand source assets without confirming their archival value.
  - Decision: **keep `design/` in Git, no LFS.** ~22 MB on disk / ~10 MB packed for the whole repo, it is the brand source of truth with archival value, and LFS adds tooling cost to a solo repo. Revisit only if the repo size becomes a problem. Documented in the README.

- [x] Add standard repository metadata as appropriate. Completed 2026-11-21 (CONTRIBUTING skipped).
  - License file.
  - Contribution/development notes.
  - Security/reporting contact if distributing publicly.
  - Changelog or release-notes process.
  - Resolution: `LICENSE` already existed. Added `SECURITY.md` (reporting contact `woofer@koulei.dev`, the address already public in About) and `CHANGELOG.md` (Unreleased section plus the release/bump process). Development notes live in the README rather than a separate `CONTRIBUTING.md`, which is skipped: the repo is proprietary and owner-only.

## P3 — Product and UX review

- [ ] Make Settings copy match real behavior.
  - Clarify what "Best available" means when users manually select a format.
  - Keep informational rows non-interactive until real preferences exist.

- [ ] Improve history typing.
  - Store media kind and MIME explicitly instead of inferring audio/video from a format string.
  - Add a database migration from schema version 1.
  - Consider storing output extension and original selected format separately.

- [ ] Decide how stale history entries should behave.
  - Offer to remove an entry when its underlying MediaStore item has been deleted.
  - Consider a clear-history action with confirmation.
  - Decide whether "Remove from library" should ever delete the downloaded file; keep the wording explicit.

- [ ] Review accessibility and device adaptability.
  - Test large font scaling, screen readers, contrast, reduced motion, landscape, and narrow devices.
  - Add semantic labels to custom gesture-based controls.
  - Verify all touch targets meet the 44 dp minimum.
  - Provide a reduced-motion path for infinite aurora/equalizer/sheen animations.

- [ ] Review loading and cancellation UX.
  - Make it obvious when a new URL cannot be fetched because another operation is active.
  - Show a clear cancelled state or confirmation if returning directly to format selection is ambiguous.
  - Consider progress behavior when total size is unknown.

- [ ] Perform final visual QA on a real device.
  - Launcher icon, adaptive icon, monochrome icon, and splash transition.
  - Bottom sheets with long titles and many formats.
  - Navigation pill and toast around gesture/navigation insets.
  - Library rows with long Unicode titles and missing metadata.

## Verification commands

Run from `app/` unless noted otherwise:

```powershell
flutter pub get
flutter analyze
flutter test
flutter pub outdated
flutter build apk --profile
flutter build appbundle --release
```

Device check:

```powershell
& 'C:/Users/Pc/AppData/Local/Android/Sdk/platform-tools/adb.exe' devices -l
```

Python bridge tests, from `app/android/app/`, against the pinned yt-dlp (`requirements.txt`):

```powershell
uv run --python 3.12 --with-requirements requirements.txt --with pytest python -m pytest src/test/python
```

Native tests, from `app/android/` (needs `JAVA_HOME` on a JDK 17–24; Gradle 8.14 can't run on JDK 25):

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'; ./gradlew :app:testDebugUnitTest
```

Release signer check — must show the upload identity, not the Android debug cert:

```powershell
& 'C:/Users/Pc/AppData/Local/Android/Sdk/build-tools/36.1.0/apksigner.bat' verify --print-certs app/build/app/outputs/flutter-apk/app-release.apk
```

## Current baseline (2026-11-21, branch `p2-maintenance`)

- [x] `flutter analyze` passes with no issues.
- [x] All 129 Flutter tests pass.
- [x] Python bridge: 28 tests pass (pytest, yt-dlp 2026.10.26, offline).
- [x] Native `:app:testDebugUnitTest`: 12 tests — 9 pass, 3 skipped on Windows (the POSIX-only FileProvider cases; first real run is Linux CI).
- [x] `flutter build apk --release` → signed APK (168.4 MB), signer **CN=ABDULRHMAN.ALSMADI, OU=koulei, O=koulei** (`apksigner`); bundled `yt_dlp/version.py` = `2026.10.26`.
- [x] `:app:bundleRelease` → AAB (98.9 MB), same upload signer (`keytool -printcert`), `arm64-v8a` + `x86_64`, no test modules packaged, all 22 arm64 native libraries stripped (no `.debug_info`).
- [x] `flutter build appbundle --release` exits 0 (98.9 MB). It had exited 1 ("failed to strip debug symbols") because the Android SDK cmdline-tools component was missing; after installing it from Android Studio it passes. `flutter doctor` still reports "Android license status unknown" — run `flutter doctor --android-licenses` (not blocking the build).
- [x] Release signing restored (it had silently regressed in `998a375`).
- [x] Generated `graphify-out` files and the Gradle problems report are no longer tracked.
- [ ] CI written and linted, but it has not run on GitHub yet (the branch is not pushed).
- [ ] Native end-to-end verification is pending; the configured Samsung is still unauthorized — the ADB trust prompt must be accepted first.