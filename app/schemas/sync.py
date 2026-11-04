from datetime import datetime
from uuid import UUID
from typing import Any
from pydantic import BaseModel, Field

class SyncPushItem(BaseModel):
    client_event_id: str | None = None
    entity_type: str = Field(description="Loại thực thể: note, folder, tag")
    entity_id: UUID = Field(description="UUID của thực thể")
    action: str = Field(description="CREATE, UPDATE, DELETE")
    version: int = Field(default=1, description="Lamport version tại client")
    client_id: str | None = None
    payload: dict[str, Any] = Field(default_factory=dict, description="Dữ liệu chi tiết của thực thể")

class SyncPushRequest(BaseModel):
    items: list[SyncPushItem] = Field(default_factory=list)

class SyncPushResult(BaseModel):
    entity_id: UUID
    entity_type: str
    status: str = Field(description="SUCCESS, CONFLICT, REJECTED")
    server_version: int
    server_copy: dict[str, Any] | None = None
    message: str | None = None

class SyncPushResponse(BaseModel):
    results: list[SyncPushResult] = Field(default_factory=list)

class SyncPullEvent(BaseModel):
    id: int
    entity_type: str
    entity_id: UUID
    action: str
    version: int
    client_id: str | None = None
    created_at: datetime
    data: dict[str, Any] | None = None

class SyncPullResponse(BaseModel):
    events: list[SyncPullEvent] = Field(default_factory=list)
    new_cursor: int = Field(description="ID của sync event mới nhất để làm cursor")
