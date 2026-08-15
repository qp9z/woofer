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

- [ ] Improve best-audio selection for video merges.
  - Do not rank solely by filesize, especially when sizes are unknown.
  - Prefer a compatible, high-quality audio codec/bitrate for the selected video container.
  - Test ties and formats with no size metadata.

- [ ] Decide how ffmpeg cancellation should behave.
  - Evaluate calling FFmpegKit cancellation during merge/transcode.
  - Ensure cancelled output is deleted and no result notification is posted.

- [ ] Harden output filenames.
  - Add a maximum byte/character length suitable for Android filesystems and MediaStore.
  - Preserve the extension when truncating.
  - Test invalid characters, blank titles, Unicode, and very long titles.

- [ ] Bound thumbnail downloads.
  - Set a maximum accepted response size.
  - Optionally reject clearly invalid content types.
  - Keep artwork best-effort so it can never fail the media download.

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

- [ ] Review cached FlutterEngine and Activity lifecycle behavior.
  - Confirm plugins are not registered repeatedly after Activity recreation.
  - Confirm share intents continue to arrive with the cached engine.
  - Check whether each recreated `MainActivity` leaks its single-thread executor.
  - Move long-lived native responsibilities out of the Activity if necessary.

- [ ] Split `MainActivity.kt` into focused components.
  - Candidate responsibilities: yt-dlp bridge, storage/MediaStore, file intents, and download notifications.
  - Preserve the cached-engine and notification-cancellation behavior.
  - Add native tests where practical.

- [ ] Make native error envelopes valid JSON in every case.
  - Use a JSON serializer instead of manually replacing quotes/newlines.
  - Make Dart channel decoding convert malformed/unexpected responses into a typed failure.

- [ ] Review foreground-service requirements for every supported target SDK.
  - Confirm manifest permissions and `dataSync` service behavior.
  - Confirm current Android timeout/background-start rules are handled.
  - Document the behavior when notification permission is denied.

## P1 — Release blockers

- [ ] Replace `com.example.woofer` with the permanent application ID.
  - Update the Gradle namespace/application ID, Kotlin package paths, FileProvider authority, notification actions, and tests/documentation.
  - Treat the final ID as permanent once a public build is distributed.

- [ ] Configure secure release signing.
  - Stop signing release builds with the debug key.
  - Keep the keystore and credentials outside Git.
  - Document backup and recovery of the signing key.

- [ ] Establish one version source of truth.
  - Make the About sheet read the runtime package version/build number.
  - Remove the hardcoded `build 118` mismatch with `pubspec.yaml` (`1.0.0+1`).
  - Define the versioning and build-number process.

- [ ] Review licensing and distribution obligations.
  - Verify the exact ffmpeg package/binary license and codec configuration.
  - Review yt-dlp, Chaquopy, bundled fonts, icons, and other dependency licenses.
  - Add required license notices/source offers before distribution.
  - Confirm whether the selected ffmpeg package is compatible with the intended app license.

- [ ] Finalize user-facing policy and identity.
  - Verify `woofer.app`, email, X, Privacy, and Terms links are live and correct.
  - Add the final privacy policy and terms.
  - Confirm downloader behavior complies with intended store policies and applicable content-platform rules.
  - Replace placeholder pubspec description and remaining Flutter-template comments.

- [ ] Produce release artifacts appropriately.
  - Build and test an Android App Bundle so users receive ABI-specific splits.
  - Verify app size for arm64 and x86_64 delivery.
  - Decide whether x86_64 is needed in production or only for emulators.
  - Verify release-mode shrinking/obfuscation does not break Chaquopy or ffmpeg.

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
