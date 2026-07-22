# woofer

Monorepo for an Android social / YouTube downloader.

- **`backend/`** — Python FastAPI service using `yt-dlp` + `ffmpeg`.
- **`app/`** — Flutter Android app (targets Android only).

No UI or download logic yet — this is the scaffold.

## backend

FastAPI service. Requires Python 3.10+ (and `ffmpeg` on PATH for real downloads).

```bash
cd backend
python -m venv .venv
# Windows:  .venv\Scripts\activate
# Unix:     source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

Health check: `GET http://127.0.0.1:8000/ping` → `{"status": "ok"}`

### Docker (bundles ffmpeg)

```bash
cd backend
docker build -t woofer-backend .
docker run -p 8000:8000 woofer-backend
```

## app

Flutter app, Android only. Requires the Flutter SDK.

```bash
cd app
flutter pub get
flutter run          # on a connected Android device/emulator
flutter build apk    # release APK
```

Dependencies: `dio` (HTTP), `permission_handler` (storage/permissions),
`path_provider` (download paths), `sqflite` (local download history).
