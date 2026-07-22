from urllib.parse import urlparse

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from yt_dlp import YoutubeDL
from yt_dlp.utils import DownloadError

app = FastAPI(title="Woofer Downloader API")


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


def _error(code: str, message: str) -> JSONResponse:
    return JSONResponse(status_code=422, content={"error_code": code, "message": message})


# ---- routes ----
@app.get("/ping")
def ping():
    """Health check."""
    return {"status": "ok"}


@app.post("/extract")
def extract(req: ExtractRequest):
    if not _valid_url(req.url):
        return _error("INVALID_URL", "URL must be a valid http(s) URL.")
    try:
        with YoutubeDL({"quiet": True, "no_warnings": True, "skip_download": True}) as ydl:
            info = ydl.extract_info(req.url, download=False)
    except DownloadError as e:
        return _error(_classify_error(str(e)), str(e))
    except Exception as e:  # yt-dlp raises many extractor-specific types
        return _error("UNKNOWN", str(e))
    if not info:
        return _error("UNAVAILABLE", "No information could be extracted for this URL.")
    return _build_response(info)
