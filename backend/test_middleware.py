from fastapi.testclient import TestClient

import main
from main import app

client = TestClient(app)


def test_version_endpoint():
    r = client.get("/version")
    assert r.status_code == 200
    body = r.json()
    assert body["app"] == main.APP_VERSION
    assert isinstance(body["yt_dlp"], str) and body["yt_dlp"]


def test_request_id_header():
    r = client.get("/ping")
    assert r.status_code == 200
    assert r.headers.get("x-request-id")  # structured-logging correlation id


def test_rate_limit(monkeypatch):
    monkeypatch.setattr(main, "RATE_LIMIT", 3)  # tighten so the test is quick
    main._rate_hits.clear()
    codes = [client.get("/ping").status_code for _ in range(5)]
    assert codes.count(200) == 3
    assert codes.count(429) == 2
    r = client.get("/ping")
    assert r.status_code == 429
    assert r.json()["error_code"] == "RATE_LIMITED"
    assert r.headers.get("retry-after") == str(int(main.RATE_WINDOW))


def test_cors_allows_configured_origin():
    r = client.get("/ping", headers={"Origin": main.ALLOWED_ORIGIN})
    assert r.headers.get("access-control-allow-origin") == main.ALLOWED_ORIGIN


def test_cors_blocks_other_origin():
    r = client.get("/ping", headers={"Origin": "https://evil.example.com"})
    # request still succeeds, but no allow-origin header is echoed for a bad origin
    assert r.headers.get("access-control-allow-origin") != "https://evil.example.com"


def test_ytdlp_version_is_reported():
    assert main._ytdlp_version() != "unknown"


def test_update_event_ignores_version_formatting():
    # PyPI canonicalises "2026.07.04" to "2026.7.4" -> not an update
    assert main._update_event("2026.07.04", "2026.7.4")["event"] == "ytdlp_up_to_date"


def test_update_event_detects_newer():
    assert main._update_event("2026.07.04", "2026.08.01")["event"] == "ytdlp_update_available"


def test_update_event_skipped_when_offline():
    assert main._update_event("2026.07.04", None)["event"] == "ytdlp_update_check_skipped"
