import json
import logging
import mimetypes
import os
import re
import shutil
import tempfile
import threading
import time
import urllib.request
import uuid
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
from starlette.background import BackgroundTask
from yt_dlp import YoutubeDL
from yt_dlp.utils import DownloadError

APP_VERSION = "0.1.0"

# TODO: set this to your app's origin. A Flutter *web* build sends its page origin
# (e.g. "https://app.example.com"); native Android/iOS builds send no Origin header,
# so CORS never applies to them. One constant — edit it here.
ALLOWED_ORIGIN = "http://localhost:8080"  # TODO: replace with your real app origin

RATE_LIMIT = 10      # max requests per client IP ...
RATE_WINDOW = 60.0   # ... within this many seconds

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("woofer")


def _ytdlp_version() -> str:
    try:
        from yt_dlp.version import __version__
        return __version__
    except Exception:
        return "unknown"


def _latest_pypi_version(pkg: str = "yt-dlp", timeout: float = 3.0) -> str | None:
    try:
        with urllib.request.urlopen(f"https://pypi.org/pypi/{pkg}/json", timeout=timeout) as resp:
            return json.load(resp)["info"]["version"]
    except Exception:
        return None


def _norm_version(v: str) -> tuple:
    # yt-dlp uses date versions; PyPI canonicalises "2026.07.04" -> "2026.7.4",
    # so compare numerically rather than by raw string.
    return tuple(int(p) if p.isdigit() else p for p in v.split("."))


def _update_event(current: str, latest: str | None) -> dict:
    if latest is None:
        return {"event": "ytdlp_update_check_skipped", "version": current}
    if _norm_version(latest) != _norm_version(current):
        return {"event": "ytdlp_update_available", "current": current,
                "latest": latest, "hint": "pip install -U yt-dlp"}
    return {"event": "ytdlp_up_to_date", "version": current}


def _check_ytdlp_update() -> None:
    """Best-effort: log whether a newer yt-dlp exists on PyPI. Never raises."""
    log.info(json.dumps(_update_event(_ytdlp_version(), _latest_pypi_version())))


@asynccontextmanager
async def lifespan(_app):
    log.info(json.dumps({"event": "startup", "app_version": APP_VERSION,
                         "ytdlp_version": _ytdlp_version()}))
    # Non-blocking: a slow or offline PyPI must never delay or break startup.
    threading.Thread(target=_check_ytdlp_update, daemon=True).start()
    yield


app = FastAPI(title="Woofer Downloader API", lifespan=lifespan)


# ---- middleware: rate limiting + structured logging + CORS ----
# In-memory, per-process. ponytail: no Redis/DB — a dict of recent hit timestamps
# per IP. With >1 worker each process keeps its own counter (fine for a soft limit).
_rate_hits: dict[str, deque] = defaultdict(deque)


def _rate_limited(ip: str) -> bool:
    now = time.monotonic()
    dq = _rate_hits[ip]
    cutoff = now - RATE_WINDOW
    while dq and dq[0] <= cutoff:
        dq.popleft()
    if len(dq) >= RATE_LIMIT:
        return True
    dq.append(now)
    return False


# Defined BEFORE logging_mw on purpose: Starlette runs the last-added middleware
# outermost, so logging wraps rate limiting and thus also logs 429 responses.
@app.middleware("http")
async def rate_limit_mw(request: Request, call_next):
    ip = request.client.host if request.client else "unknown"
    if _rate_limited(ip):
        return JSONResponse(
            status_code=429,
            content={"error_code": "RATE_LIMITED",
                     "message": f"Rate limit exceeded ({RATE_LIMIT} requests / {int(RATE_WINDOW)}s)."},
            headers={"Retry-After": str(int(RATE_WINDOW))},
        )
    return await call_next(request)


@app.middleware("http")
async def logging_mw(request: Request, call_next):
    rid = uuid.uuid4().hex[:12]
    start = time.perf_counter()
    status, outcome = 500, "error"
    try:
        response = await call_next(request)
        status = response.status_code
        outcome = ("rate_limited" if status == 429
                   else "error" if status >= 500
                   else "client_error" if status >= 400
                   else "ok")
        response.headers["X-Request-ID"] = rid
        return response
    finally:
        log.info(json.dumps({
            "event": "request", "request_id": rid, "method": request.method,
            "endpoint": request.url.path, "status": status,
            "duration_ms": round((time.perf_counter() - start) * 1000, 1),
            "outcome": outcome,
            "ip": request.client.host if request.client else "unknown",
        }))


# Added last -> outermost: CORS headers/preflight apply to every response.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[ALLOWED_ORIGIN],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# A download is rejected only when its reported size won't fit in the free disk
# space where temp files are written, minus this reserve (keeps the disk from
# filling to zero and leaves room for the video+audio merge intermediates).
# ponytail: trusts yt-dlp's reported size; no mid-download byte accounting.
DISK_HEADROOM_BYTES = int(os.getenv("DISK_HEADROOM_BYTES", str(256 * 1024 * 1024)))  # 256 MB

# A download is rejected only when its reported size won't fit in the free disk
# space where temp files are written, minus this reserve (keeps the disk from
# filling to zero and leaves room for the video+audio merge intermediates).
# ponytail: trusts yt-dlp's reported size; no mid-download byte accounting.
DISK_HEADROOM_BYTES = int(os.getenv("DISK_HEADROOM_BYTES", str(256 * 1024 * 1024)))  # 256 MB

# Deterministic content types for what we actually produce (Windows mimetypes
# registry is unreliable), falling back to mimetypes for anything else.
_CONTENT_TYPES = {
    "mp3": "audio/mpeg",
    "m4a": "audio/mp4",
    "mp4": "video/mp4",
    "webm": "video/webm",
    "mkv": "video/x-matroska",
}


# ---- models ----
class ExtractRequest(BaseModel):
    url: str


class FormatModel(BaseModel):
    format_id: str
    ext: str | None = None
    resolution: str | None = None
    filesize: int | None = None
    has_audio: bool
    has_video: bool
    note: str | None = None


class ExtractResponse(BaseModel):
    title: str | None = None
    thumbnail: str | None = None
    duration: float | None = None
    uploader: str | None = None
    formats: list[FormatModel]


class ExtractError(BaseModel):
    error_code: str
    message: str


class DownloadRequest(BaseModel):
    url: str
    format_id: str
    mode: Literal["video", "audio"]


# ---- helpers ----
def _valid_url(url: str) -> bool:
    try:
        p = urlparse(url.strip())
    except Exception:
        return False
    return p.scheme in ("http", "https") and bool(p.netloc)


def _classify_error(message: str) -> str:
    """Map a yt-dlp error message to one of the documented error codes."""
    m = message.lower()
    if "private" in m:
        return "PRIVATE"
    if "unsupported url" in m or "unsupported" in m:
        return "UNSUPPORTED"
    if any(k in m for k in (
        "unavailable", "removed", "deleted", "no longer available",
        "not available", "does not exist", "video not found",
    )):
        return "UNAVAILABLE"
    return "UNKNOWN"


def _has(codec) -> bool:
    return codec not in (None, "none", "")


def _resolution(f: dict) -> str | None:
    if f.get("resolution"):
        return f["resolution"]
    w, h = f.get("width"), f.get("height")
    if w and h:
        return f"{w}x{h}"
    if h:
        return f"{h}p"
    if _has(f.get("acodec")) and not _has(f.get("vcodec")):
        return "audio only"
    return None


def _quality_key(f: dict):
    # best-first when sorted reverse=True: video over audio, then height, bitrate, size
    return (
        1 if _has(f.get("vcodec")) else 0,
        f.get("height") or 0,
        f.get("tbr") or 0,
        f.get("filesize") or f.get("filesize_approx") or 0,
    )


def _build_response(info: dict) -> ExtractResponse:
    raw = info.get("formats") or ([info] if info.get("format_id") else [])
    # keep formats that carry usable video OR audio; drop the rest (storyboards, etc.)
    usable = [f for f in raw if _has(f.get("vcodec")) or _has(f.get("acodec"))]
    usable.sort(key=_quality_key, reverse=True)
    formats = [
        FormatModel(
            format_id=str(f.get("format_id", "")),
            ext=f.get("ext"),
            resolution=_resolution(f),
            filesize=f.get("filesize") or f.get("filesize_approx"),
            has_audio=_has(f.get("acodec")),
            has_video=_has(f.get("vcodec")),
            note=f.get("format_note"),
        )
        for f in usable
    ]
    return ExtractResponse(
        title=info.get("title"),
        thumbnail=info.get("thumbnail"),
        duration=info.get("duration"),
        uploader=info.get("uploader"),
        formats=formats,
    )


def _error(code: str, message: str, status: int = 422) -> JSONResponse:
    return JSONResponse(status_code=status, content={"error_code": code, "message": message})


def _find_format(info: dict, format_id: str) -> dict | None:
    for f in info.get("formats", []):
        if str(f.get("format_id")) == str(format_id):
            return f
    return None


def _estimated_size(info: dict, fmt: dict, mode: str) -> int | None:
    """Reported size of the download, incl. the audio stream we'll merge in."""
    size = fmt.get("filesize") or fmt.get("filesize_approx") or 0
    if mode == "video" and _has(fmt.get("vcodec")) and not _has(fmt.get("acodec")):
        audio_sizes = [
            f.get("filesize") or f.get("filesize_approx") or 0
            for f in info.get("formats", [])
            if _has(f.get("acodec")) and not _has(f.get("vcodec"))
        ]
        size += max(audio_sizes) if audio_sizes else 0
    return size or None


def _free_disk_bytes(path: str) -> int:
    return shutil.disk_usage(path).free


def _content_type(ext: str) -> str:
    ext = ext.lstrip(".").lower()
    return _CONTENT_TYPES.get(ext) or mimetypes.guess_type(f"x.{ext}")[0] or "application/octet-stream"


def _safe_filename(title: str | None, ext: str) -> str:
    base = re.sub(r'[\\/:*?"<>|\x00-\x1f]', "_", title or "download")
    base = re.sub(r"\s+", " ", base).strip().strip(".")[:120] or "download"
    return f"{base}.{ext.lstrip('.')}"


def _probe(url: str) -> dict | None:
    """Metadata only, no download."""
    with YoutubeDL({"quiet": True, "no_warnings": True, "skip_download": True}) as ydl:
        return ydl.extract_info(url, download=False)


def _download_to_file(url: str, format_selector: str, to_mp3: bool, tmpdir: str) -> Path:
    """Download (and post-process) into tmpdir; return the final media file."""
    opts = {
        "quiet": True,
        "no_warnings": True,
        "format": format_selector,
        "outtmpl": os.path.join(tmpdir, "%(id)s.%(ext)s"),
        "merge_output_format": "mp4",  # only applies when a merge actually happens
    }
    if to_mp3:
        opts["postprocessors"] = [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "mp3",
            "preferredquality": "192",
        }]
    with YoutubeDL(opts) as ydl:
        ydl.download([url])

    leftovers = [
        p for p in Path(tmpdir).iterdir()
        if p.is_file() and p.suffix.lower() not in (".part", ".ytdl", ".temp")
    ]
    if not leftovers:
        raise FileNotFoundError("yt-dlp produced no output file")
    return max(leftovers, key=lambda p: p.stat().st_size)  # the merged/converted result


# ---- routes ----
@app.get("/ping")
def ping():
    """Health check."""
    return {"status": "ok"}


@app.get("/version")
def version():
    """yt-dlp and app version."""
    return {"app": APP_VERSION, "yt_dlp": _ytdlp_version()}


@app.post("/extract")
def extract(req: ExtractRequest):
    if not _valid_url(req.url):
        return _error("INVALID_URL", "URL must be a valid http(s) URL.")
    try:
        info = _probe(req.url)
    except DownloadError as e:
        return _error(_classify_error(str(e)), str(e))
    except Exception as e:  # yt-dlp raises many extractor-specific types
        return _error("UNKNOWN", str(e))
    if not info:
        return _error("UNAVAILABLE", "No information could be extracted for this URL.")
    return _build_response(info)


@app.post("/download")
def download(req: DownloadRequest):
    if not _valid_url(req.url):
        return _error("INVALID_URL", "URL must be a valid http(s) URL.")

    try:
        info = _probe(req.url)
    except DownloadError as e:
        return _error(_classify_error(str(e)), str(e))
    except Exception as e:
        return _error("UNKNOWN", str(e))
    if not info:
        return _error("UNAVAILABLE", "No information could be extracted for this URL.")

    fmt = _find_format(info, req.format_id)
    if fmt is None:
        return _error("UNKNOWN", f"format_id '{req.format_id}' not found for this URL.")

    est = _estimated_size(info, fmt, req.mode)
    if est is not None:
        free = _free_disk_bytes(tempfile.gettempdir())
        if est > free - DISK_HEADROOM_BYTES:
            return _error(
                "TOO_LARGE",
                f"Download is ~{est} bytes; only {free} bytes free where temp files are written.",
                status=413,
            )

    to_mp3 = req.mode == "audio"
    if to_mp3:
        selector = req.format_id
    elif _has(fmt.get("vcodec")) and not _has(fmt.get("acodec")):
        selector = f"{req.format_id}+bestaudio/{req.format_id}"  # video-only -> merge audio
    else:
        selector = req.format_id

    tmpdir = tempfile.mkdtemp(prefix="woofer_")
    try:
        path = _download_to_file(req.url, selector, to_mp3, tmpdir)
    except DownloadError as e:
        shutil.rmtree(tmpdir, ignore_errors=True)
        return _error(_classify_error(str(e)), str(e))
    except Exception as e:
        shutil.rmtree(tmpdir, ignore_errors=True)
        return _error("UNKNOWN", str(e))

    ext = path.suffix.lstrip(".") or ("mp3" if to_mp3 else "mp4")
    return FileResponse(
        path,
        media_type=_content_type(ext),
        filename=_safe_filename(info.get("title"), ext),
        background=BackgroundTask(shutil.rmtree, tmpdir, ignore_errors=True),
    )
