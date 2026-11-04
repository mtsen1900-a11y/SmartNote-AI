from pydantic import BaseModel, Field, HttpUrl
from typing import Literal

class IngestTextRequest(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    content: str = Field(min_length=1)
    source_type: Literal["direct", "paste", "markdown", "txt"] = "direct"
    source_reference: str | None = None
    folder: str = "Tài liệu nhập"
    tags: list[str] = Field(default_factory=lambda: ["imported"])

class IngestUrlRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2048)
    folder: str = "Web Clippings"
    tags: list[str] = Field(default_factory=lambda: ["web", "clipping"])

class IngestResponse(BaseModel):
    status: str
    message: str
    note_id: int
    title: str
    content_hash: str
    source_type: str
    source_reference: str | None = None
    chunk_count: int
    is_duplicate: bool = False
