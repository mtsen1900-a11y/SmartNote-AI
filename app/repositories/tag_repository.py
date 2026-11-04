import uuid
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..models.tag import Tag

class TagRepository:
    def get_by_id(self, db: Session, tag_id: uuid.UUID) -> Tag | None:
        return db.get(Tag, tag_id)

    def list_by_user(self, db: Session, user_id: int) -> list[Tag]:
        stmt = select(Tag).where(Tag.user_id == user_id).order_by(Tag.name.asc())
        return list(db.scalars(stmt).all())

    def create(self, db: Session, tag: Tag) -> Tag:
        db.add(tag)
        db.commit()
        db.refresh(tag)
        return tag

    def delete(self, db: Session, tag: Tag) -> None:
        db.delete(tag)
        db.commit()
