from unittest.mock import MagicMock

from fastapi.testclient import TestClient
from yt_dlp.utils import DownloadError

import main
from main import app

client = TestClient(app)

FAKE_INFO = {
    "title": "Test Video",
    "thumbnail": "https://img/thumb.jpg",
    "duration": 212,
    "uploader": "Test Channel",
    "formats": [
        # audio-only
        {"format_id": "140", "ext": "m4a", "acodec": "mp4a", "vcodec": "none",
         "filesize": 3_000_000, "format_note": "audio"},
        # 360p muxed (video + audio)
        {"format_id": "18", "ext": "mp4", "acodec": "mp4a", "vcodec": "avc1",
         "height": 360, "tbr": 500, "filesize": 10_000_000, "format_note": "360p"},
        # 1080p video-only
        {"format_id": "137", "ext": "mp4", "acodec": "none", "vcodec": "avc1",
         "height": 1080, "tbr": 4000, "filesize": 50_000_000, "format_note": "1080p"},
        # storyboard: no audio AND no video -> must be filtered out
        {"format_id": "sb0", "ext": "mhtml", "acodec": "none", "vcodec": "none",
         "format_note": "storyboard"},
    ],
}


def _mock_ydl(monkeypatch, *, info=None, exc=None):
    inst = MagicMock()
    if exc is not None:
        inst.extract_info.side_effect = exc
    else:
        inst.extract_info.return_value = info
    ctx = MagicMock()
    ctx.__enter__.return_value = inst
    ctx.__exit__.return_value = False
    monkeypatch.setattr(main, "YoutubeDL", MagicMock(return_value=ctx))
    return inst


def test_extract_success(monkeypatch):
    _mock_ydl(monkeypatch, info=FAKE_INFO)
    r = client.post("/extract", json={"url": "https://www.youtube.com/watch?v=abc"})
    assert r.status_code == 200
    data = r.json()
    assert data["title"] == "Test Video"
    assert data["duration"] == 212
    assert data["uploader"] == "Test Channel"

    ids = [f["format_id"] for f in data["formats"]]
    # no-audio-no-video format dropped
    assert "sb0" not in ids
    assert len(ids) == 3
    # best quality first, worst last
    assert ids[0] == "137"   # 1080p
    assert ids[-1] == "140"  # audio-only

    f137 = next(f for f in data["formats"] if f["format_id"] == "137")
    assert f137["has_video"] is True and f137["has_audio"] is False
    f140 = next(f for f in data["formats"] if f["format_id"] == "140")
    assert f140["has_video"] is False and f140["has_audio"] is True


def test_extract_private(monkeypatch):
    _mock_ydl(monkeypatch, exc=DownloadError("ERROR: Private video. Sign in to view."))
    r = client.post("/extract", json={"url": "https://www.youtube.com/watch?v=abc"})
    assert r.status_code == 422
    assert r.json()["error_code"] == "PRIVATE"


def test_extract_unavailable(monkeypatch):
    _mock_ydl(monkeypatch, exc=DownloadError("ERROR: Video unavailable"))
    r = client.post("/extract", json={"url": "https://www.youtube.com/watch?v=abc"})
    assert r.status_code == 422
    assert r.json()["error_code"] == "UNAVAILABLE"


def test_extract_invalid_url():
    r = client.post("/extract", json={"url": "not a url"})
    assert r.status_code == 422
    assert r.json()["error_code"] == "INVALID_URL"
