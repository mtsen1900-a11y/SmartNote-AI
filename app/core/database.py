import logging
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from .config import settings

logger = logging.getLogger("smartnote")

class Base(DeclarativeBase):
    pass

def init_engine():
    """
    Khởi tạo SQLAlchemy Engine:
    - Nếu cấu hình PostgreSQL: thiết lập connect_timeout=2s và kiểm tra kết nối với SELECT 1.
    - Nếu PostgreSQL không phản hồi (ví dụ Docker chưa bật trong môi trường dev):
      Tự động kích hoạt Local SQLite Fallback (smartnote_dev.db) và tạo toàn bộ bảng,
      giúp toàn bộ luồng Đăng ký, Đăng nhập, Workspace, Ghi chú hoạt động 100% trơn tru.
    """
    if "postgresql" in settings.database_url:
        try:
            pg_engine = create_engine(
                settings.database_url,
                pool_pre_ping=True,
                pool_size=10,
                max_overflow=20,
                connect_args={"connect_timeout": 2},
            )
            with pg_engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("Kết nối thành công tới PostgreSQL cơ sở dữ liệu chính.")
            return pg_engine
        except Exception as e:
            logger.warning(
                f"Không thể kết nối tới PostgreSQL ({e}). "
                "Đang chuyển sang chế độ Local SQLite dự phòng (smartnote_dev.db) "
                "để đảm bảo không làm gián đoạn trải nghiệm của người dùng..."
            )
            sqlite_path = Path(__file__).resolve().parent.parent.parent / "smartnote_dev.db"
            sqlite_engine = create_engine(
                f"sqlite:///{sqlite_path.as_posix()}",
                connect_args={"check_same_thread": False},
            )
            from ..models import (
                User, Folder, Note, Tag, note_tags, Task,
                RefreshToken, SyncEvent, NoteIdMapping
            )
            Base.metadata.create_all(bind=sqlite_engine)
            logger.info(f"Đã khởi tạo cơ sở dữ liệu SQLite cục bộ tại: {sqlite_path}")
            return sqlite_engine
    else:
        return create_engine(
            settings.database_url,
            connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
        )

engine = init_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

