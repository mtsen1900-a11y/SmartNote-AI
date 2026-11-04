from sqlalchemy import select, update
from sqlalchemy.orm import Session
from ..models.user import User
from ..models.refresh_token import RefreshToken
from ..models.note import Note

class UserRepository:
    def get_by_id(self, db: Session, user_id: int) -> User | None:
        return db.get(User, user_id)

    def get_by_email(self, db: Session, email: str) -> User | None:
        stmt = select(User).where(User.email == email.lower().strip())
        return db.scalar(stmt)

    def create(self, db: Session, user: User) -> User:
        user.email = user.email.lower().strip()
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def count_real_users(self, db: Session) -> int:
        stmt = select(User).where(User.is_system.is_(False))
        return len(list(db.scalars(stmt).all()))

    def claim_legacy_notes(self, db: Session, new_user_id: int) -> int:
        """
        Chuyển nhượng 2 ghi chú gốc từ user kỹ thuật (id=1) sang tài khoản thật đầu tiên.
        """
        stmt = (
            update(Note)
            .where(Note.user_id == 1)
            .values(user_id=new_user_id)
        )
        result = db.execute(stmt)
        db.commit()
        return result.rowcount

    def store_refresh_token(self, db: Session, token: RefreshToken) -> RefreshToken:
        db.add(token)
        db.commit()
        db.refresh(token)
        return token

    def get_refresh_token_by_hash(self, db: Session, token_hash: str) -> RefreshToken | None:
        stmt = select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.is_revoked.is_(False),
        )
        return db.scalar(stmt)

    def revoke_refresh_token(self, db: Session, token: RefreshToken) -> None:
        token.is_revoked = True
        db.commit()

user_repository = UserRepository()
