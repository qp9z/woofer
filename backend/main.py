from fastapi import FastAPI

app = FastAPI(title="Woofer Downloader API")


@app.get("/ping")
def ping():
    """Health check."""
    return {"status": "ok"}
