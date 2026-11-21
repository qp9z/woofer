"""Offline tests for ytdlp_bridge: no network, no real yt-dlp extraction.

Run from app/android/app with yt-dlp and pytest installed (CI uses the pinned
requirements.txt next to build.gradle.kts):

    python -m pytest src/test/python

The bridge's contract with Dart is a JSON *envelope*; these tests pin that
contract: error classification, envelope validity, the VideoInfo shape, and the
cancel path.
"""

import json

import pytest
import yt_dlp
from yt_dlp.utils import GeoRestrictedError, UnsupportedError

import ytdlp_bridge as bridge


# --- error classification -----------------------------------------------------


@pytest.mark.parametrize(
    "message, code",
    [
        ("Sign in to confirm you're not a bot", "BOT_CHECK"),
        ("There is no video in this post", "NO_VIDEO"),
        ("No video formats found", "NO_VIDEO"),
        ("This video is private", "PRIVATE"),
        ("This video is age-restricted", "PRIVATE"),
        ("Video unavailable", "UNAVAILABLE"),
        ("This video has been removed by the uploader", "UNAVAILABLE"),
        ("HTTP Error 429: Too Many Requests", "RATE_LIMITED"),
        ("Unsupported URL: not-a-site", "INVALID_URL"),
        ("<urlopen error [Errno 7] No address associated with hostname>", "NETWORK"),
        ("Read timed out", "NETWORK"),
        ("something nobody anticipated", "UNKNOWN"),
    ],
)
def test_classify_by_message(message, code):
    assert bridge._classify(Exception(message)) == code


def test_classify_by_exception_type():
    assert bridge._classify(UnsupportedError("https://example.com")) == "UNSUPPORTED"
    assert bridge._classify(GeoRestrictedError("blocked in your country")) == "GEO"


def test_bare_sign_in_is_not_a_bot_check():
    # "Sign in to confirm your age" fronts age restriction, not the IP-reputation
    # gate; only the specific "not a bot" wording may map to BOT_CHECK.
    assert bridge._classify(Exception("Sign in to confirm your age")) != "BOT_CHECK"


# --- envelopes ------------------------------------------------------------------


def test_error_envelope_survives_hostile_messages():
    raw = bridge._error(Exception('bad "quote"\nsecond line \\ backslash'))
    envelope = json.loads(raw)  # must be valid JSON whatever the message holds
    assert envelope["ok"] is False
    assert envelope["code"] == "UNKNOWN"
    assert envelope["message"] == 'bad "quote"'  # first line only


def test_error_envelope_for_an_empty_message():
    envelope = json.loads(bridge._error(Exception("")))
    assert envelope["message"] == "yt-dlp error"


def test_friendly_messages_replace_noisy_ones():
    envelope = json.loads(bridge._error(Exception("Sign in to confirm you're not a bot")))
    assert envelope["code"] == "BOT_CHECK"
    assert "temporarily blocking" in envelope["message"]


# --- version --------------------------------------------------------------------


def test_version_is_the_bundled_ytdlp_release():
    import re

    # Shown in Settings -> About. Not a literal: it must track requirements.txt.
    assert bridge.version() == yt_dlp.version.__version__
    assert re.fullmatch(r"\d{4}\.\d{2}\.\d{2}(\.\d+)?", bridge.version())


# --- VideoInfo shape ------------------------------------------------------------


def test_video_info_filters_and_maps_formats():
    info = {
        "title": "T",
        "thumbnail": "https://img",
        "duration": 12.5,
        "channel": "Chan",  # no `uploader`: falls back to channel
        "formats": [
            {"format_id": None, "vcodec": "avc1", "acodec": "none"},  # no id
            {"format_id": "sb0", "ext": "mhtml", "vcodec": "none", "acodec": "none"},
            {"format_id": "x", "ext": "mp4", "vcodec": "none", "acodec": "none"},  # no media
            {
                "format_id": 137,
                "ext": "mp4",
                "height": 1080,
                "vcodec": "avc1.640028",
                "acodec": "none",
                "filesize_approx": 1000,
            },
            {
                "format_id": "140",
                "ext": "m4a",
                "vcodec": "none",
                "acodec": "mp4a.40.2",
                "abr": 129.5,
                "filesize": 500,
            },
        ],
    }
    data = bridge._video_info(info)
    assert data["uploader"] == "Chan"
    assert [f["format_id"] for f in data["formats"]] == ["137", "140"]  # str ids

    video, audio = data["formats"]
    assert video["has_video"] and not video["has_audio"]
    assert video["resolution"] == "1080p"  # derived from height
    assert video["filesize"] == 1000  # falls back to filesize_approx
    assert audio["has_audio"] and not audio["has_video"]
    assert audio["resolution"] is None  # audio-only has no resolution
    assert audio["abr"] == 129.5


# --- extract_info / download against a stubbed YoutubeDL -------------------------


def stub_ydl(monkeypatch, *, info=None, raises=None, during=None):
    """Replace yt_dlp.YoutubeDL with a recorder; returns what the bridge passed in."""
    seen = {}

    class FakeYDL:
        def __init__(self, opts):
            seen["opts"] = opts

        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

        def extract_info(self, url, download=False):
            seen["url"], seen["download"] = url, download
            if during:
                during(seen["opts"])
            if raises:
                raise raises
            return info

        def prepare_filename(self, _info):
            return "/out/fallback.mp4"

    monkeypatch.setattr(yt_dlp, "YoutubeDL", FakeYDL)
    return seen


def test_extract_info_returns_a_data_envelope(monkeypatch):
    seen = stub_ydl(monkeypatch, info={"title": "T", "formats": []})
    envelope = json.loads(bridge.extract_info("https://example.com/v"))
    assert envelope == {"ok": True, "data": bridge._video_info({"title": "T", "formats": []})}
    assert seen["download"] is False
    assert seen["opts"]["skip_download"] is True
    assert seen["opts"]["noplaylist"] is True


def test_extract_info_flattens_a_playlist_to_its_first_entry(monkeypatch):
    stub_ydl(
        monkeypatch,
        info={"_type": "playlist", "entries": [{"title": "first"}, {"title": "second"}]},
    )
    envelope = json.loads(bridge.extract_info("https://example.com/p"))
    assert envelope["data"]["title"] == "first"


def test_extract_info_failure_becomes_an_envelope(monkeypatch):
    stub_ydl(monkeypatch, raises=Exception("Video unavailable"))
    envelope = json.loads(bridge.extract_info("https://example.com/v"))
    assert envelope["ok"] is False and envelope["code"] == "UNAVAILABLE"


class Progress:
    def __init__(self):
        self.calls = []

    def onProgress(self, received, total):  # noqa: N802 - the Kotlin-side name
        self.calls.append((received, total))


def test_download_reports_progress_and_returns_the_saved_path(monkeypatch):
    cb = Progress()

    def during(opts):
        hook = opts["progress_hooks"][0]
        hook({"status": "downloading", "downloaded_bytes": 10, "total_bytes": 100})
        hook({"status": "downloading", "downloaded_bytes": 20, "total_bytes_estimate": 80})
        hook({"status": "finished", "filename": "/out/clip.f137.mp4"})

    stub_ydl(monkeypatch, info={}, during=during)
    envelope = json.loads(bridge.download("https://x", "137", "/out", cb))
    assert envelope == {"ok": True, "path": "/out/clip.f137.mp4"}
    assert cb.calls == [(10, 100), (20, 80)]


def test_download_uses_a_fresh_non_resuming_configuration(monkeypatch):
    seen = stub_ydl(monkeypatch, info={})
    bridge.download("https://x", "137", "/out", None)
    opts = seen["opts"]
    assert opts["format"] == "137"
    assert opts["continuedl"] is False and opts["overwrites"] is True
    assert seen["download"] is True


def test_cancel_during_a_transfer_returns_the_cancelled_envelope(monkeypatch):
    def during(opts):
        bridge.request_cancel()  # what the notification's Cancel button ends up doing
        opts["progress_hooks"][0]({"status": "downloading", "downloaded_bytes": 1})

    stub_ydl(monkeypatch, info={}, during=during)
    envelope = json.loads(bridge.download("https://x", "137", "/out", Progress()))
    assert envelope["ok"] is False and envelope["code"] == "CANCELLED"


def test_a_stale_cancel_flag_does_not_kill_the_next_download(monkeypatch):
    bridge.request_cancel()  # left over from a previous attempt
    stub_ydl(monkeypatch, info={})
    envelope = json.loads(bridge.download("https://x", "137", "/out", None))
    assert envelope["ok"] is True


def test_download_failure_becomes_an_envelope(monkeypatch):
    stub_ydl(monkeypatch, raises=Exception("HTTP Error 429: Too Many Requests"))
    envelope = json.loads(bridge.download("https://x", "137", "/out", None))
    assert envelope["ok"] is False and envelope["code"] == "RATE_LIMITED"
