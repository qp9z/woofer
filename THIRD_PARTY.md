# THIRD-PARTY NOTICES

WOOFER (dev.koulei.woofer) bundles third-party open-source components. Each is
governed by its own license; this file summarises the obligations that matter
for distribution and points at the canonical text.

## yt-dlp
- License: **Unlicense** (public domain — no obligations).
- Home: https://github.com/yt-dlp/yt-dlp
- Runs in-process via Chaquopy (pip-installed at build time). Public-domain:
  no attribution or source-offer requirement.

## FFmpeg via ffmpeg_kit_flutter_new
- Package: `ffmpeg_kit_flutter_new` **full-gpl** build (4.5.x).
- The bundled FFmpeg binary is a **GPL-2.0-or-later** build. It includes
  GPL-licensed components (e.g. x264, libx265-class codecs). **Distributing a
  GPL FFmpeg binary makes that binary subject to the GPL** — most relevantly the
  offer-of-source requirement for the GPL parts.
- WOOFER itself only invokes `-c:a libmp3lame` (transcode) plus built-in
  muxers (merge). It does not compile or invoke the GPL encoders the full-gpl
  binary carries. But the *binary* is what ships.
- Options before public release:
  1. Keep `full-gpl` and ship GPL source offer / make WOOFER GPL-compliant for
     the FFmpeg parts (conflicts with the proprietary-only intent if taken to
     the whole app), OR
  2. Switch to the LGPL/audio variant (`ffmpeg_kit_flutter_new_audio`), which
     drops GPL encoders and keeps libmp3lame — LGPL obligations only, clean for
     a proprietary app. This is the recommended path for closed distribution.
- Upstream: https://github.com/sk3llo/ffmpeg_kit_flutter (maintained fork of
  arthenica/ffmpeg-kit).

## Chaquopy
- License: **proprietary**, free to use (personal and commercial), no
  redistribution of the SDK itself.
- Home: https://chaquo.com/chaquopy/
- Used to embed CPython + yt-dlp. No GPL coupling; distribution of WOOFER as an
  app that uses Chaquopy is permitted by its terms.

## Other Dart dependencies
- flutter_riverpod (MIT), permission_handler (MIT), path_provider (BSD-3),
  sqflite (MIT), receive_sharing_intent (MIT), url_launcher (MIT),
  package_info_plus (BSD-3), cupertino_icons (MIT), ffmpeg_kit_flutter_new
  (LGPL-3.0 wrapper / see above).
- These impose no source-offer obligation on a distributed binary.

## Action needed before public distribution
Confirm the FFmpeg build variant (GPL full vs LGPL audio) and reconcile with the
proprietary-only license in `LICENSE`. Recommended: switch to the **audio (LGPL)**
variant unless GPL compliance is acceptable. Each published build should ship a
copy of this file and the relevant license texts.