from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...schemas.note import NoteCreate, NoteUpdate, NoteOut
from ...services.note_service import note_service
from ..dependencies import get_current_user

router = APIRouter(prefix="/notes", tags=["Notes"])

@router.get("", response_model=list[NoteOut])
def list_notes(
    q: str | None = Query(default=None, description="Tìm kiếm theo tiêu đề hoặc nội dung"),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return note_service.list_notes(db=db, user_id=current_user.id, q=q, limit=limit, offset=offset)

@router.post("", response_model=NoteOut, status_code=201)
async def create_note(
    payload: NoteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await note_service.create_note(db=db, data=payload, user_id=current_user.id)

@router.get("/{note_id}", response_model=NoteOut)
def get_note(
    note_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return note_service.get_note(db=db, identifier=note_id, user_id=current_user.id)

@router.put("/{note_id}", response_model=NoteOut)
async def update_note(
    note_id: str,
    payload: NoteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await note_service.update_note(db=db, identifier=note_id, data=payload, user_id=current_user.id)

@router.delete("/{note_id}")
async def delete_note(
    note_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await note_service.delete_note(db=db, identifier=note_id, user_id=current_user.id)
