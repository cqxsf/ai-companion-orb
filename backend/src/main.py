"""
AI Companion Orb — FastAPI application entry point.
"""

from __future__ import annotations

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.database import close_redis, init_db, init_redis
from src.routes import (
    alerts_router,
    auth_router,
    behavior_router,
    conversation_router,
    devices_router,
    family_router,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AI Companion Orb API",
    description="Backend API for the AI Companion Orb (小光) project",
    version="0.1.0",
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
_V1 = "/api/v1"
app.include_router(auth_router, prefix=_V1)
app.include_router(devices_router, prefix=_V1)
app.include_router(conversation_router, prefix=_V1)
app.include_router(family_router, prefix=_V1)
app.include_router(behavior_router, prefix=_V1)
app.include_router(alerts_router, prefix=_V1)

# ---------------------------------------------------------------------------
# Startup / shutdown
# ---------------------------------------------------------------------------


@app.on_event("startup")
async def startup() -> None:
    logger.info("Initialising database …")
    await init_db()
    logger.info("Initialising Redis …")
    await init_redis()
    logger.info("Startup complete.")


@app.on_event("shutdown")
async def shutdown() -> None:
    await close_redis()
    logger.info("Shutdown complete.")


# ---------------------------------------------------------------------------
# Global exception handler
# ---------------------------------------------------------------------------


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.error("Unhandled exception on %s: %s", request.url, exc, exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------


@app.get("/health", tags=["health"])
async def health() -> dict[str, str]:
    return {"status": "ok"}
