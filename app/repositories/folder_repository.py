import uuid
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..models.folder import Folder

class FolderRepository:
    def get_by_id(self, db: Session, folder_id: uuid.UUID) -> Folder | None:
        return db.get(Folder, folder_id)

    def list_by_user(self, db: Session, user_id: int) -> list[Folder]:
        stmt = (
            select(Folder)
            .where(Folder.user_id == user_id, Folder.is_deleted.is_(False))
            .order_by(Folder.name.asc())
        )
        return list(db.scalars(stmt).all())

    def create(self, db: Session, folder: Folder) -> Folder:
        db.add(folder)
        db.commit()
        db.refresh(folder)
        return folder

    def update(self, db: Session, folder: Folder) -> Folder:
        folder.version += 1
        folder.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(folder)
        return folder

    def soft_delete(self, db: Session, folder: Folder) -> Folder:
        folder.is_deleted = True
        folder.version += 1
        db.commit()
        db.refresh(folder)
        return folder
