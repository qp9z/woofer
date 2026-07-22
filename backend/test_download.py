from pathlib import Path
from urllib.parse import unquote

from fastapi.testclient import TestClient
from yt_dlp.utils import DownloadError

import main
from main import app

client = TestClient(app)

# 137 = 1080p video-only, 140 = audio-only, 18 = 360p muxed
PROBE_INFO = {
    "title": "My Cool Video: Part 1/2",
    "id": "abc123",
    "formats": [
        {"format_id": "137", "vcodec": "avc1", "acodec": "none", "height": 1080, "filesize": 5_000_000},
        {"format_id": "140", "vcodec": "none", "acodec": "mp4a", "filesize": 1_000_000},
        {"format_id": "18", "vcodec": "avc1", "acodec": "mp4a", "height": 360, "filesize": 8_000_000},
    ],
}


def _fake_download(ext: str, data: bytes, captured: dict | None = None):
    def _dl(url, selector, to_mp3, tmpdir):
        if captured is not None:
            captured.update(url=url, selector=selector, to_mp3=to_mp3, tmpdir=tmpdir)
        p = Path(tmpdir) / f"abc123.{ext}"
        p.write_bytes(data)
        return p
    return _dl


def test_download_video_streams_with_headers(monkeypatch):
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)
    monkeypatch.setattr(main, "_download_to_file", _fake_download("mp4", b"FAKEMP4DATA"))

    r = client.post("/download", json={
        "url": "https://www.youtube.com/watch?v=abc123", "format_id": "137", "mode": "video",
    })
    assert r.status_code == 200
    assert r.headers["content-type"] == "video/mp4"
    cd = unquote(r.headers["content-disposition"])  # header may be RFC-5987 percent-encoded
    assert cd.startswith("attachment;")
    # unsafe title chars ('/' ':') sanitized to '_' in the filename
    assert "My Cool Video_ Part 1_2.mp4" in cd
    assert "/" not in cd.split("filename", 1)[1]
    assert ":" not in cd.split("filename", 1)[1]
    assert r.content == b"FAKEMP4DATA"


def test_download_audio_is_mp3(monkeypatch):
    captured = {}
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)
    monkeypatch.setattr(main, "_download_to_file", _fake_download("mp3", b"ID3FAKE", captured))

    r = client.post("/download", json={
        "url": "https://y.com/x", "format_id": "140", "mode": "audio",
    })
    assert r.status_code == 200
    assert r.headers["content-type"] == "audio/mpeg"
    assert captured["to_mp3"] is True
    assert captured["selector"] == "140"


def test_download_video_only_gets_merged(monkeypatch):
    captured = {}
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)
    monkeypatch.setattr(main, "_download_to_file", _fake_download("mp4", b"X", captured))

    r = client.post("/download", json={
        "url": "https://y.com/x", "format_id": "137", "mode": "video",
    })
    assert r.status_code == 200
    # 137 is video-only -> selector must pull in bestaudio for the merge
    assert "bestaudio" in captured["selector"]


def test_download_muxed_not_merged(monkeypatch):
    captured = {}
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)
    monkeypatch.setattr(main, "_download_to_file", _fake_download("mp4", b"X", captured))

    r = client.post("/download", json={
        "url": "https://y.com/x", "format_id": "18", "mode": "video",
    })
    assert r.status_code == 200
    # 18 already has audio -> no merge selector
    assert captured["selector"] == "18"


def test_download_rejected_when_it_wont_fit_on_disk(monkeypatch):
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)  # 137+140 ~= 6 MB
    monkeypatch.setattr(main, "_free_disk_bytes", lambda path: 1_000_000)  # only ~1 MB free
    r = client.post("/download", json={"url": "https://y.com/x", "format_id": "137", "mode": "video"})
    assert r.status_code == 413
    assert r.json()["error_code"] == "TOO_LARGE"


def test_download_allowed_when_it_fits_on_disk(monkeypatch):
    captured = {}
    monkeypatch.setattr(main, "_probe", lambda url: PROBE_INFO)
    monkeypatch.setattr(main, "_free_disk_bytes", lambda path: 50 * 1024 * 1024 * 1024)  # 50 GB free
    monkeypatch.setattr(main, "_download_to_file", _fake_download("mp4", b"X", captured))
    r = client.post("/download", json={"url": "https://y.com/x", "format_id": "137", "mode": "video"})
    assert r.status_code == 200


def test_download_private(monkeypatch):
    def boom(url):
        raise DownloadError("ERROR: Private video. Sign in to view.")
    monkeypatch.setattr(main, "_probe", boom)
    r = client.post("/download", json={"url": "https://y.com/x", "format_id": "137", "mode": "video"})
    assert r.status_code == 422
    assert r.json()["error_code"] == "PRIVATE"


def test_download_invalid_url():
    r = client.post("/download", json={"url": "not a url", "format_id": "137", "mode": "video"})
    assert r.status_code == 422
    assert r.json()["error_code"] == "INVALID_URL"


def test_download_bad_mode_is_422():
    r = client.post("/download", json={"url": "https://y.com/x", "format_id": "137", "mode": "gif"})
    assert r.status_code == 422  # pydantic rejects the Literal
