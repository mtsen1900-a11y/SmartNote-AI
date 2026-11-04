import uuid
from datetime import datetime, timezone
from sqlalchemy import or_, select
from sqlalchemy.orm import Session
from ..models.note import Note
from ..models.id_mapping import NoteIdMapping

class NoteRepository:
    def get_by_id_or_uuid(self, db: Session, identifier: int | str | uuid.UUID) -> Note | None:
        """
        Tìm kiếm Note theo ID số nguyên (cũ) hoặc UUID (mới).
        Đảm bảo tương thích ngược 100% với các mã nguồn cũ.
        """
        # Nếu identifier là số nguyên hoặc chuỗi số nguyên
        if isinstance(identifier, int) or (isinstance(identifier, str) and identifier.isdigit()):
            int_id = int(identifier)
            # Thử tìm trực tiếp theo id số nguyên
            note = db.get(Note, int_id)
            if note:
                return note
            # Nếu không thấy, thử tìm qua bảng mapping
            mapping = db.get(NoteIdMapping, int_id)
            if mapping:
                stmt = select(Note).where(Note.uuid == mapping.note_uuid)
                return db.scalar(stmt)
            return None

        # Nếu identifier là UUID hoặc chuỗi UUID
        try:
            target_uuid = uuid.UUID(str(identifier))
            stmt = select(Note).where(Note.uuid == target_uuid)
            return db.scalar(stmt)
        except ValueError:
            return None

    def list_notes(
        self,
        db: Session,
        q: str | None = None,
        user_id: int | None = None,
        folder_id: uuid.UUID | None = None,
        include_deleted: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> list[Note]:
        stmt = select(Note).order_by(Note.updated_at.desc())
        
        if not include_deleted:
            stmt = stmt.where(Note.is_deleted.is_(False))
        if user_id is not None:
            stmt = stmt.where(Note.user_id == user_id)
        if folder_id is not None:
            stmt = stmt.where(Note.folder_id == folder_id)
        if q:
            search_pattern = f"%{q}%"
            stmt = stmt.where(
                or_(
                    Note.title.ilike(search_pattern),
                    Note.content.ilike(search_pattern),
                )
            )
        stmt = stmt.limit(limit).offset(offset)
        return list(db.scalars(stmt).all())

    def create(self, db: Session, note: Note) -> Note:
        if note.uuid is None:
            note.uuid = uuid.uuid4()
        db.add(note)
        db.commit()
        db.refresh(note)
        return note

    def update(self, db: Session, note: Note) -> Note:
        note.version += 1
        note.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(note)
        return note

    def soft_delete(self, db: Session, note: Note) -> Note:
        note.is_deleted = True
        note.deleted_at = datetime.now(timezone.utc)
        note.version += 1
        db.commit()
        db.refresh(note)
        return note

    def hard_delete(self, db: Session, note: Note) -> None:
        db.delete(note)
        db.commit()
