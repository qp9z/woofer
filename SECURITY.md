# Security policy

WOOFER runs entirely on the device: there is no server, account, or telemetry.
The surface worth reporting is therefore local — the bundled yt-dlp / ffmpeg
binaries, the file/intent handling, and the release signing material.

## Reporting a vulnerability

Email **woofer@koulei.dev** with:

- what you found and the version (Settings → About shows version, build and the
  bundled yt-dlp release),
- steps to reproduce, and
- whether you want to be credited.

Please don't open a public issue for anything exploitable. Expect an
acknowledgement within a few days.

## Supported versions

Only the latest published release is supported. yt-dlp is pinned per release in
`app/android/app/requirements.txt` and bumped regularly — see
[`app/android/CHAQUOPY.md`](app/android/CHAQUOPY.md#yt-dlp-update-policy).

## Handling secrets

`app/android/key.properties` and `app/android/upload-keystore.jks` are the
release signing material. They are gitignored and must never be committed,
pasted into issues, or shared. If either leaks, rotate the upload key.
