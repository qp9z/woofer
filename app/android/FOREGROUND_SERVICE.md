# Foreground-service & notification review

How a download survives the app being backgrounded, and the Android version
rules WOOFER must satisfy. Reviewed 2026-08-25 against every supported target
(minSdk 24 → current target SDK).

## Why a foreground service exists at all

The whole download pipeline (transfer, merge/transcode, MediaStore copy) runs in
the **Dart isolate** — not native code. Without a foreground service, Android is
free to reclaim the process the moment the user leaves the app, killing a
mid-download or mid-merge with zero warning. `DownloadService` pins the process
at foreground priority for the lifetime of a download, and `stopWithTask=false`
means swiping WOOFER off Recents does **not** stop it.

## Manifest requirements (all present and correct)

| Target SDK behaviour | Requirement | Present |
| --- | --- | --- |
| Any | `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>` | ✅ |
| API 34+ (Android 14) | Declare a `foregroundServiceType` on the service **and** its matching permission. WOOFER uses `dataSync` + `FOREGROUND_SERVICE_DATA_SYNC`. | ✅ |
| API 34+ | A `dataSync` FGS requires that the app hold the data-sync **type permission** at start (a runtime `SecurityException` otherwise). Declared, never revoked. | ✅ |
| API 33+ (Android 13) | `POST_NOTIFICATIONS` runtime permission for any notification (incl. the FGS alert). | ✅, denial handled — see below |
| API 29+ | MediaStore path needs **no** storage permission. `WRITE_EXTERNAL_STORAGE` is present `maxSdkVersion=28` only, for the legacy path. | ✅ |

The service is `android:exported="false"` (only the app starts it) and every
`PendingIntent` is `FLAG_IMMUTABLE` (Android 12+ requirement) — both already set.

## Background-start restrictions (API 31+)

Android 12+ forbids starting a foreground service while the app is in the
**background**, except for a narrow set of exemptions (`dataSync` is **not**
exempt). WOOFER never does this: `showProgress` is called from the Dart pipeline
while the app is foregrounded (the user just tapped Download), so the start is
always allowed. A cold-start share intent also shows the activity first. If a
future feature ever tried to start a download from a truly background context it
would throw `ForegroundServiceStartNotAllowedException` — do not "fix" that by
blindly catching it; start the service from a visible activity or a user action.

## API 35 (Android 15) `dataSync` timeout

Android 15 imposes a **6-hour** cap on `dataSync` foreground services before it
stops them (and throws on `startForeground` after the timeout). A normal woofer
download is seconds to a few minutes, so this is never reached; but an enormous
or very slow transfer could theoretically hit it. The Dart pipeline already treats
an unexpected stop as a failure path (sanitized `Failed`, cleanup of partial
files), so the app fails cleanly rather than appearing to hang. No code change
needed today; revisit only if downloads routinely exceed the cap.

## When notification permission is denied (API 33+)

Denying `POST_NOTIFICATIONS` costs only the visible chrome, never the download:

- The **progress** notification simply isn't shown; `startForeground` still runs
  (a FGS must present a notification channel but does not require the runtime
  permission to run), so the download and the process pin keep working.
- The **result** notification is posted through `NotificationManagerCompat.notify`
  inside a `try/catch (SecurityException)` — song/drop, the in-app toast already
  told the user the outcome.
- Channels are created once (`woofer_downloads`, `woofer_download_results`);
  their descriptions tell the user what each is for in Settings.

## Where this lives

- `MainActivity.kt` — wires `showProgress` / `hide` / `showResult` into the
  `woofer/storage` MethodChannel.
- `DownloadService.kt` — the service, both channels, and `showResult` (posted
  through `NotificationManager` directly so it outlives the service stop).
- `DownloadActionReceiver.kt` — the progress notification's Cancel button routed
  back into Dart via the cached engine's channel.
- `AndroidManifest.xml` — every permission and the service declaration above.
