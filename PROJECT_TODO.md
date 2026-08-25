# WOOFER Project To-Do

Last reviewed: 2026-08-15

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

- [x] Define and implement deterministic format ordering. Completed 2026-08-15.
  - Resolution: choices are ranked highest-quality-first from explicit yt-dlp metadata; video uses resolution, width, FPS, bitrate, and estimated size, while audio uses bitrate, sample rate, channels, and estimated size. Missing values sort behind known values at their tier, with deterministic text and format-ID tie-breakers.
  - Sort video choices by resolution/quality, codec/container, FPS, and estimated size as appropriate.
  - Sort audio choices by bitrate/quality rather than depending on yt-dlp's raw order.
  - Decide whether highest quality or a balanced option should appear first.
  - Add tests for missing filesize, resolution, bitrate, and note fields.

- [x] Choose a sensible default format. Completed 2026-08-15.
  - Resolution: the default is explicitly the highest-ranked video (or audio after switching kinds), matching Settings' “Best available” promise; it is selected independently of yt-dlp's raw order and confirmed by an untouched-Download widget test.
  - Do not blindly select the first raw yt-dlp format.
  - Make the default agree with the behavior advertised in Settings.
  - Confirm that selecting Download without touching the list produces the intended quality.

- [x] Improve best-audio selection for video merges. Completed 2026-08-25.
  - Do not rank solely by filesize, especially when sizes are unknown.
  - Prefer a compatible, high-quality audio codec/bitrate for the selected video container.
  - Test ties and formats with no size metadata.
  - Resolution: best-audio selection now uses bitrate > sample rate > channels > codec > filesize as tiebreakers, with missing metadata sorted behind known values.

- [x] Decide how ffmpeg cancellation should behave. Completed 2026-08-25.
  - Evaluate calling FFmpegKit cancellation during merge/transcode.
  - Ensure cancelled output is deleted and no result notification is posted.
  - Resolution: `MediaProcessor.cancel()` now calls `FFmpegKit.cancel()` (injectable for tests), the controller's `cancel()` aborts an in-flight merge/transcode as well as the transfer, the partial output is deleted by the normal failure path, and a cancelled operation returns to format selection without posting a success or failure notification.

- [x] Harden output filenames. Completed 2026-08-25.
  - Add a maximum byte/character length suitable for Android filesystems and MediaStore.
  - Preserve the extension when truncating.
  - Test invalid characters, blank titles, Unicode, and very long titles.
  - Resolution: `safeMediaFileName()` in `lib/services/filename.dart` sanitizes control/invalid characters, trims ambiguous trailing dots/spaces, truncates multi-byte titles to Android's 255-byte component limit without splitting a codepoint, preserves the extension, and falls back to a timestamped name for blank titles.

- [x] Bound thumbnail downloads. Completed 2026-08-25.
  - Set a maximum accepted response size.
  - Optionally reject clearly invalid content types.
  - Keep artwork best-effort so it can never fail the media download.
  - Resolution: `CoverFetcher` now streams the body with a 5 MB cap (`maxBytes`, injectable) and rejects responses whose content type is clearly not an image, still returning null (never an error) so artwork can't fail a download.

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
  - Test network switching between Wi-Fi and cellular.
  - Test insufficient storage and save failures.
  - Test notification permission denial on Android 13+.
  - Test legacy storage behavior on API 24–28 if those versions remain supported.
  - Status 2026-08-25: device `R5CXA4Q2SHK` is attached but `unauthorized` — the ADB trust prompt on the phone must be accepted first (the machine-side work is committed/ready).

- [x] Review cached FlutterEngine and Activity lifecycle behavior. Completed 2026-08-25.
  - Confirm plugins are not registered repeatedly after Activity recreation.
  - Confirm share intents continue to arrive with the cached engine.
  - Check whether each recreated `MainActivity` leaks its single-thread executor.
  - Move long-lived native responsibilities out of the Activity if necessary.
  - Resolution: plugins register once at engine creation (Flutter's registrant); re-attaching channels in `configureFlutterEngine` re-registers handlers only, never wires twice. Share intents keep arriving because the cached engine keeps Dart live. The leak was real and is fixed: the per-Activity `ioExecutor` was never shut down (by design), so every recreation leaked a thread — it is now process-scoped inside `YtdlpBridge` (one thread for the process). Long-lived native work (yt-dlp bridge, process network binding) moved out of the Activity.

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
  - Resolution: application ID and namespace are now `dev.koulei.woofer`; the Kotlin sources moved from `com/example/woofer` to `dev/koulei/woofer` (git-mv to preserve history) with package declarations, the `ACTION_CANCEL` action string, and the CLAUDE.md adb/package references updated. FileProvider authority and the receiver's `setPackage` derive from the new `applicationId` automatically (no hardcoded change needed).

- [x] Configure secure release signing. Completed 2026-08-25.
  - Stop signing release builds with the debug key.
  - Keep the keystore and credentials outside Git.
  - Document backup and recovery of the signing key.
  - Resolution: generated `android/upload-keystore.jks` signed with identity **CN=ABDULRHMAN.ALSMADI, OU=koulei, O=koulei** (RSA 2048, `upload` alias, 10000-day validity) + `android/key.properties`, both gitignored; `build.gradle.kts` reads `key.properties` and signs release with the release keystore (falling back to the debug key when missing, e.g. CI). Verified: `assembleRelease` APK is signed with the real identity, NOT the debug key. Backup the `.jks` + the password/alias in `key.properties` (backup instructions delivered to the owner).

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

- [ ] Define a reproducible yt-dlp update policy.
  - Avoid an unconstrained package silently changing between identical builds.
  - Pin a tested version for releases or inject a controlled version during CI.
  - Schedule frequent compatibility updates because supported sites change often.
  - Record the bundled yt-dlp version in build metadata/About diagnostics.

- [ ] Review available Flutter dependency updates individually.
  - `ffmpeg_kit_flutter_new`: 4.5.2 → 4.6.2.
  - `flutter_riverpod`: 2.6.1 → 3.4.2 (major migration).
  - `permission_handler`: 12.0.3 → 13.0.1 (major migration).
  - Run analyze, tests, Android builds, and device smoke tests after each upgrade group.

- [ ] Remove or document the compile-SDK workaround.
  - Recheck whether `receive_sharing_intent` or current Android tooling still requires forcing plugin modules to SDK 36.
  - Delete the workaround once AGP correctly resolves minor-versioned platforms.

- [ ] Track Gradle/Chaquopy compatibility.
  - Resolve Chaquopy deprecation warnings before moving to Gradle 9.
  - Verify future AGP, Kotlin, Flutter, and Chaquopy upgrades as a tested set.

- [ ] Add native/Python automated checks.
  - Integrate `test_outtmpl.py` into an executable test environment with yt-dlp installed.
  - Add tests for Python error classification and JSON output.
  - Add Android tests for MediaStore cleanup, open/share intents, and notification cancellation where feasible.

## P2 — CI and quality gates

- [ ] Add CI for the current on-device architecture.
  - Run `flutter pub get` with the lockfile.
  - Run `flutter analyze`.
  - Run `flutter test`.
  - Run the Python bridge tests in a pinned Python/yt-dlp environment.
  - Build at least one Android profile or release artifact to exercise Gradle, Chaquopy, and ffmpeg integration.
  - Cache dependencies without weakening reproducibility.

- [ ] Add regression tests for uncovered state-machine behavior.
  - Concurrent and out-of-order extraction.
  - Extract/share intent while downloading.
  - Cancel followed immediately by restart.
  - Malformed MethodChannel JSON.
  - Temporary-directory creation failure.
  - Unexpected processor/storage exception.
  - Muxed WebM MIME.
  - Missing/deleted history files.

- [ ] Decide whether to collect code coverage.
  - Use coverage as a signal, not a target percentage.
  - Prioritize state transitions and platform-boundary failure cases.

## P2 — Documentation and repository hygiene

- [ ] Rewrite the root README for the current architecture.
  - Remove the nonexistent FastAPI/backend instructions and stale CI claims.
  - Explain Flutter + Chaquopy + yt-dlp + ffmpeg_kit.
  - Document build prerequisites, Android-only scope, supported ABIs, and common setup failures.
  - Include accurate analyze/test/build commands.

- [ ] Reconcile project documentation.
  - Update the documented test count from 65 to 75, or avoid hardcoding the count.
  - Keep `CLAUDE.md`, `android/CHAQUOPY.md`, and README consistent.
  - Move historical debugging notes into an architecture decision record if the main guide becomes too dense.

- [ ] Stop tracking generated Graphify output.
  - Preserve or commit any generated report intentionally needed first.
  - Remove `graphify-out` files from Git's index while keeping the directory ignored.
  - Confirm future graph generation no longer dirties the worktree.

- [ ] Remove the tracked Gradle problems report.
  - Untrack `app/android/build/reports/problems/problems-report.html`.
  - Confirm all build directories remain ignored.

- [ ] Review large design assets.
  - Keep the six app font files required at runtime.
  - Decide whether all 54 source font files and the embedded brand-guideline HTML belong in Git, Git LFS, or external design storage.
  - Do not remove brand source assets without confirming their archival value.

- [ ] Add standard repository metadata as appropriate.
  - License file.
  - Contribution/development notes.
  - Security/reporting contact if distributing publicly.
  - Changelog or release-notes process.

## P3 — Product and UX review

- [ ] Make Settings copy match real behavior.
  - Clarify what “Best available” means when users manually select a format.
  - Keep informational rows non-interactive until real preferences exist.

- [ ] Improve history typing.
  - Store media kind and MIME explicitly instead of inferring audio/video from a format string.
  - Add a database migration from schema version 1.
  - Consider storing output extension and original selected format separately.

- [ ] Decide how stale history entries should behave.
  - Offer to remove an entry when its underlying MediaStore item has been deleted.
  - Consider a clear-history action with confirmation.
  - Decide whether “Remove from library” should ever delete the downloaded file; keep the wording explicit.

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

Python regression test, from `app/`, in an environment containing the release's
pinned yt-dlp version:

```powershell
python android/app/src/main/python/test_outtmpl.py
```

## Current baseline

- [x] `flutter analyze` passes with no issues (2026-08-15).
- [x] All 93 Flutter tests pass (2026-08-15).
- [x] Android `:app:testDebugUnitTest` passes, including all 3 MediaStore cleanup-helper tests (2026-08-15).
- [ ] Native end-to-end verification is current; the configured Samsung is now authorized, but the full device matrix remains outstanding.
- [ ] The worktree is clean; generated `graphify-out` files had pre-existing modifications during this review.
