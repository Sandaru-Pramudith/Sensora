"""
main.py — Sensora FastAPI application entry point

Project layout
--------------
sensora/
├── main.py                        ← you are here
├── .env                           ← environment variables (copy from .env.example)
├── requirements.txt
├── core/
│   ├── config.py                  ← pydantic-settings (all env vars)
│   └── socket.py                  ← shared Socket.IO async server
├── db/
│   └── session.py                 ← get_db() FastAPI dependency
├── api/
│   ├── routers/
│   │   ├── alerts.py              ← /api/alerts/* endpoints
│   │   └── notifications.py       ← /api/notifications/* endpoints
│   └── schemas/
│       ├── alerts.py              ← Pydantic request/response models
│       └── notifications.py
├── services/
│   ├── alert_service.py           ← alert business logic (no HTTP)
│   └── notification_service.py    ← notification business logic (no HTTP)
└── templates/
    └── dashboard.html
"""

from contextlib import asynccontextmanager

import socketio
import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from core.config import settings
from core.socket import sio
from api.routers import alerts, notifications


# ── Lifespan ──────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup: add anything here (e.g. connection pool warm-up)
    yield
    # shutdown: clean up resources here


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Sensora Monitoring API",
    description=(
        "IoT sensor monitoring for fruit storage batches.\n\n"
        "Real-time events are pushed via **Socket.IO** — connect to `/socket.io/`.\n\n"
        "Events emitted by the server:\n"
        "- `new_alert` — sensor threshold crossed\n"
        "- `alert_acknowledged` — alert was acknowledged\n"
        "- `batch_acknowledged` — all alerts in a batch acknowledged\n"
        "- `new_notification` — new in-app notification\n"
        "- `notification_read` — notification marked read\n"
        "- `all_notifications_read` — all notifications marked read\n"
        "- `notification_deleted` — notification deleted\n"
    ),
    version="2.0.0",
    lifespan=lifespan,
)

# Allow local Flutter web/dev server origins (localhost or 127.0.0.1 on any port).
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://127.0.0.1",
    ],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(alerts.router)
app.include_router(notifications.router)

# ── Templates ─────────────────────────────────────────────────────────────────

templates = Jinja2Templates(directory="templates")


# ── Core routes ───────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def dashboard(request: Request):
    return templates.TemplateResponse("dashboard.html", {"request": request})


@app.get("/health", tags=["System"], summary="Health check")
async def health():
    """Returns `{"status": "ok"}` — use for load-balancer / uptime probes."""
    return {"status": "ok"}


# ── Mount Socket.IO (ASGI wrapper) ────────────────────────────────────────────

# Wrap FastAPI with the Socket.IO ASGI app so both share one process.
socket_app = socketio.ASGIApp(sio, other_asgi_app=app)


# ── Dev entrypoint ────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run(
        "main:socket_app",
        host="0.0.0.0",
        port=settings.port,
        reload=settings.debug,
    )
