from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class FolderCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    color: str = Field(default="#4A90E2", max_length=20)
    parent_id: UUID | None = None

class FolderUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=100)
    color: str | None = Field(default=None, max_length=20)
    parent_id: UUID | None = None

class FolderOut(BaseModel):
    id: UUID
    name: str
    color: str
    parent_id: UUID | None = None
    version: int = 1
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
