print("STEP 1: integrated_main import started")

from fastapi.middleware.wsgi import WSGIMiddleware
print("STEP 2: WSGIMiddleware imported")

import socketio
print("STEP 3: socketio imported")

from ml_reporting.main import app as app
print("STEP 4: ml_reporting app imported")

from crud.app import create_app
print("STEP 5: create_app imported")

flask_app = create_app()
print("STEP 6: flask app created")

app.mount("/crud", WSGIMiddleware(flask_app))
print("STEP 7: crud mounted")

from alerting.api.routers import alerts, notifications
print("STEP 8: alert routers imported")

app.include_router(alerts.router)
print("STEP 9: alerts router included")

app.include_router(notifications.router)
print("STEP 10: notifications router included")

from alerting.core.socket import sio
print("STEP 11: sio imported")

socket_app = socketio.ASGIApp(sio, other_asgi_app=app)
print("STEP 12: socket_app created")
