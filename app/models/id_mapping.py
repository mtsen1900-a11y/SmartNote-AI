from datetime import datetime, timezone
import uuid
from sqlalchemy import DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from ..core.database import Base

class NoteIdMapping(Base):
    __tablename__ = "note_id_mappings"

    legacy_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    note_uuid: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("notes.uuid", ondelete="CASCADE"), unique=True, nullable=False
    )
    migrated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
