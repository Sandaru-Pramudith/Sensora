import socketio

# Single shared async Socket.IO server.
# Imported by services and routers — never instantiated twice.
sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")


@sio.event
async def connect(sid: str, environ: dict) -> None:
    """Client connected — no extra setup needed."""
    pass


@sio.event
async def disconnect(sid: str) -> None:
    """Client disconnected."""
    pass
