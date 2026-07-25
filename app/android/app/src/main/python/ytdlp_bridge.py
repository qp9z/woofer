"""yt-dlp bridge for the "ytdlp" MethodChannel.

Both entry points return a JSON *envelope* string — never raise across the
Chaquopy boundary for expected failures — so the Dart side gets a uniform
`{"ok": true, ...}` / `{"ok": false, "code", "message"}` shape. The `data`
object matches our Dart VideoInfo/MediaFormat JSON exactly (snake_case keys),
so VideoInfo.fromJson parses it unchanged.
"""

import json
import os

import yt_dlp
from yt_dlp.utils import GeoRestrictedError, UnsupportedError

# YouTube's default web clients frequently hit "Sign in to confirm you're not a
# bot" on mobile/residential IPs. These extra player clients need no cookies and
# aren't gated that way; yt-dlp merges formats across all of them and downgrades a
# bot-checked client to a warning instead of failing the whole extraction.
# ponytail: YouTube's anti-bot is a moving target — if this list stops working,
# check the yt-dlp wiki (Extractors#youtube) for the current bot-resistant clients.
_COMMON = {
    "quiet": True,
    "no_warnings": True,
    "noplaylist": True,
    "extractor_args": {"youtube": {"player_client": ["default", "tv_embedded", "android_vr"]}},
}


def extract_info(url):
    try:
        opts = {**_COMMON, "skip_download": True}
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)
        if info.get("_type") == "playlist" and info.get("entries"):
            info = info["entries"][0]
        return json.dumps({"ok": True, "data": _video_info(info)})
    except Exception as e:  # noqa: BLE001 - deliberately funnel everything to an envelope
        return _error(e)


def download(url, format_id, out_dir, callback=None):
    """Download a single format to out_dir. `callback.onProgress(recv, total)` is
    invoked during the transfer (a Java object passed from Kotlin)."""
    try:
        state = {"path": None}

        def hook(d):
            status = d.get("status")
            if status == "downloading" and callback is not None:
                total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
                callback.onProgress(int(d.get("downloaded_bytes") or 0), int(total))
            elif status == "finished":
                state["path"] = d.get("filename")

        opts = {
            **_COMMON,
            "format": format_id,
            # The format id has to be in the name. A merge downloads the video and
            # the audio track into the same dir, and YouTube's VP9/AV1 tiers pair a
            # .webm video with a .webm (Opus) audio — title+ext alone collides, and
            # `overwrites` then clobbers the video with the audio. ffmpeg gets one
            # audio-only file, `-map 0:v:0` matches nothing, exit 1. This is what
            # broke every 4K (and most 1080p+) download.
            "outtmpl": os.path.join(out_dir, "%(title).150B.f%(format_id)s.%(ext)s"),
            "restrictfilenames": True,
            "progress_hooks": [hook],
            # Never resume a leftover .part (a range past EOF => HTTP 416) and always
            # overwrite a stale file rather than reuse it. The Dart side also hands us
            # a fresh dir per download, so this is belt-and-suspenders.
            "continuedl": False,
            "overwrites": True,
        }
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
            path = state["path"] or ydl.prepare_filename(info)
        return json.dumps({"ok": True, "path": path})
    except Exception as e:  # noqa: BLE001
        return _error(e)


def _video_info(info):
    formats = []
    for f in info.get("formats", []):
        if f.get("format_id") is None:
            continue
        # Skip storyboards (image tiles) and other non-media entries.
        if f.get("ext") == "mhtml" or (f.get("protocol") or "") == "mhtml":
            continue
        vcodec, acodec = f.get("vcodec"), f.get("acodec")
        has_video = bool(vcodec) and vcodec != "none"
        has_audio = bool(acodec) and acodec != "none"
        if not has_video and not has_audio:
            continue
        height = f.get("height")
        formats.append(
            {
                "format_id": str(f["format_id"]),
                "ext": f.get("ext"),
                "resolution": (f.get("resolution") or (f"{height}p" if height else None))
                if has_video
                else None,
                "filesize": f.get("filesize") or f.get("filesize_approx"),
                "has_audio": has_audio,
                "has_video": has_video,
                "note": f.get("format_note"),
            }
        )
    return {
        "title": info.get("title"),
        "thumbnail": info.get("thumbnail"),
        "duration": info.get("duration"),
        "uploader": info.get("uploader") or info.get("channel"),
        "formats": formats,
    }


# ponytail: heuristic classification — yt-dlp doesn't expose clean typed errors
# for private/removed/rate-limit, so we sniff the message. Tokens mirror the
# Dart ApiErrorCode wire vocabulary (see ytdlp_extractor.ytdlpErrorCode).
def _classify(e):
    if isinstance(e, UnsupportedError):
        return "UNSUPPORTED"
    if isinstance(e, GeoRestrictedError):
        return "GEO"
    low = str(e).lower()
    # YouTube's anti-bot gate (IP reputation). "not a bot" is specific — don't
    # match bare "sign in to confirm", which also fronts age-restriction.
    if "not a bot" in low:
        return "BOT_CHECK"
    # A photo/carousel post (not a reel/video). yt-dlp phrases this several ways.
    if any(p in low for p in ("no video in this post", "no video formats found", "there is no video")):
        return "NO_VIDEO"
    if "private" in low or ("age" in low and "restrict" in low):
        return "PRIVATE"
    if any(k in low for k in ("unavailable", "removed", "deleted", "not available", "does not exist")):
        return "UNAVAILABLE"
    if "429" in low or "too many requests" in low or ("rate" in low and "limit" in low):
        return "RATE_LIMITED"
    if "unsupported url" in low or "is not a valid url" in low or "invalid url" in low:
        return "INVALID_URL"
    if any(k in low for k in ("urlopen error", "timed out", "timeout", "connection", "getaddrinfo", "network")):
        return "NETWORK"
    return "UNKNOWN"


# Clean messages for cases where yt-dlp's own text is noisy or user-hostile.
# Anything not listed falls back to yt-dlp's first line.
_FRIENDLY = {
    "NO_VIDEO": "This post doesn't have a video to download.",
    "BOT_CHECK": "YouTube is temporarily blocking requests from this network. "
    "Give it a few minutes and try again.",
}


def _error(e):
    code = _classify(e)
    message = _FRIENDLY.get(code) or (str(e).splitlines() or ["yt-dlp error"])[0]
    return json.dumps({"ok": False, "code": code, "message": message})
