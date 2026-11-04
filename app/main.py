from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from .core.config import settings
from .core.logging import logger, setup_logging
from .core.exceptions import AppException
from .api.router import api_router

setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Khởi động {settings.app_name} v{settings.app_version}...")
    logger.info("Database: Initialization complete")
    logger.info(f"ChromaDB: {settings.chroma_host}:{settings.chroma_port}")
    yield
    logger.info(f"Tắt {settings.app_name}...")

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)

# Cấu hình CORS chặt chẽ và an toàn cho Web Client
origins = [x.strip() for x in settings.cors_origins.split(",") if x.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Exception handlers tập trung - Đảm bảo luôn trả về JSON hợp lệ kèm CORS headers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
    )

@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    logger.error(f"Lỗi truy vấn cơ sở dữ liệu: {exc}")
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"detail": "Dịch vụ cơ sở dữ liệu tạm thời không phản hồi. Vui lòng thử lại sau."},
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Lỗi hệ thống không xử lý được: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Máy chủ đang gặp sự cố. Vui lòng thử lại sau."},
    )

# Đăng ký toàn bộ router
app.include_router(api_router)

# Endpoint /health trực tiếp ở root
@app.get("/health", tags=["Health"])
def root_health():
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
    }
