from fastapi import APIRouter
from .v1.health import router as health_router
from .v1.auth import router as auth_router
from .v1.notes import router as notes_router
from .v1.ai import router as ai_router
from .v1.sync import router as sync_router
from .v1.ingest import router as ingest_router

api_router = APIRouter()

# Đăng ký các router con vào prefix /api
api_router.include_router(health_router)
api_router.include_router(health_router, prefix="/api")
api_router.include_router(auth_router, prefix="/api")
api_router.include_router(notes_router, prefix="/api")
api_router.include_router(ai_router, prefix="/api")
api_router.include_router(sync_router, prefix="/api")
api_router.include_router(ingest_router, prefix="/api")
