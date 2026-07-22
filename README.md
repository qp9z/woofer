# woofer

Monorepo for an Android social / YouTube downloader.

- **`backend/`** — Python FastAPI service using `yt-dlp` + `ffmpeg`.
- **`app/`** — Flutter Android app (targets Android only).

CI builds and smoke-tests the backend image on every change to `backend/`.

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

### Configuration

Every setting is an environment variable with a working default — see
[`backend/.env.example`](backend/.env.example).

| Variable | Default | Meaning |
| --- | --- | --- |
| `PORT` | `8000` | Port the API listens on. |
| `ALLOWED_ORIGIN` | `http://localhost:8080` | CORS origin. Only matters for browser/Flutter-web clients; native apps send no `Origin`. |
| `MAX_FILE_SIZE` | `0` | Hard per-download byte cap. `0` = no fixed cap. |
| `RATE_LIMIT` / `RATE_WINDOW` | `10` / `60` | Requests per client IP per window; over it returns `429 RATE_LIMITED`. |
| `DISK_HEADROOM_BYTES` | `268435456` | Free space reserved on the temp disk for merges. |
| `FORWARDED_ALLOW_IPS` | `127.0.0.1` | Upstreams trusted to set `X-Forwarded-For`. Must name your reverse proxy. |

With `MAX_FILE_SIZE=0` the only size limit is free disk space: a download is
rejected with `413 TOO_LARGE` when its estimated size exceeds free space minus
`DISK_HEADROOM_BYTES`.

### Docker (bundles ffmpeg)

```bash
cd backend
cp .env.example .env       # edit ALLOWED_ORIGIN at minimum
docker compose up -d --build
curl http://127.0.0.1:8000/ping
```

The image runs as a non-root user (`woofer`, uid 10001) and has a healthcheck on
`/ping`. Without compose: `docker build -t woofer-backend . && docker run -p 8000:8000 --env-file .env woofer-backend`.

## Deploying to a VPS

Any box with Docker works (Ubuntu shown). Nothing is stored on disk between
requests — downloads are staged in the container's `/tmp` and deleted after each
response — so there is no volume or database to back up.

**1. Install Docker**

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # log out and back in
```

**2. Get the code and configure**

```bash
git clone <your-repo-url> woofer && cd woofer/backend
cp .env.example .env
nano .env          # set ALLOWED_ORIGIN; consider MAX_FILE_SIZE and RATE_LIMIT
```

**3. Run it**

```bash
docker compose up -d --build
docker compose ps          # should show "healthy"
curl http://127.0.0.1:8000/ping
```

`restart: unless-stopped` brings the service back after a reboot or crash.

**4. Put TLS in front of it**

The API speaks plain HTTP and binds the port on the host. Expose it through a
reverse proxy rather than opening 8000 to the internet — with Caddy, two lines
gets you an automatic certificate:

```caddy
api.example.com {
    reverse_proxy 127.0.0.1:8000
}
```

Then restrict the firewall to the proxy: `sudo ufw allow 80,443/tcp && sudo ufw deny 8000/tcp`.

Point the Flutter app at the result by setting `baseUrl` in
[`app/lib/config.dart`](app/lib/config.dart) to `https://api.example.com`.

**5. Updating**

```bash
cd woofer && git pull
docker compose up -d --build
```

Rebuild periodically even without code changes: `yt-dlp` is intentionally
unpinned in `requirements.txt` because it breaks whenever sites change, and a
rebuild picks up the newest release. `GET /version` reports the running `yt-dlp`
version and whether a newer one exists.

**Operational notes**

- Rate limiting is per-IP and in-process. The container runs uvicorn with
  `--proxy-headers`, so behind a proxy you **must** set `FORWARDED_ALLOW_IPS` to
  the proxy's address — otherwise every request appears to come from the proxy,
  all clients share one bucket, and legitimate traffic gets `429`d.
- Running more than one replica splits the rate-limit counters per process; the
  effective limit is `RATE_LIMIT × replicas`.
- Logs are capped at 3 × 10 MB by the compose `logging` block.

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
