from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class NoteCreate(BaseModel):
    title: str = Field(default="Ghi chú mới", max_length=200)
    content: str = ""
    folder: str = Field(default="Cá nhân", max_length=100)
    folder_id: UUID | None = None
    is_pinned: bool = False
    is_archived: bool = False

class NoteUpdate(BaseModel):
    title: str | None = Field(default=None, max_length=200)
    content: str | None = None
    folder: str | None = Field(default=None, max_length=100)
    folder_id: UUID | None = None
    is_pinned: bool | None = None
    is_archived: bool | None = None
    version: int | None = None

class NoteOut(BaseModel):
    id: int
    uuid: UUID | None = None
    title: str
    content: str
    folder: str
    folder_id: UUID | None = None
    is_pinned: bool = False
    is_archived: bool = False
    is_deleted: bool = False
    version: int = 1
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
