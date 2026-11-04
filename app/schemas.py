"""
Backward compatibility proxy module.
Re-exports from app.schemas package.
"""
from .schemas.note import NoteCreate, NoteUpdate, NoteOut
from .schemas.folder import FolderCreate, FolderUpdate, FolderOut
from .schemas.tag import TagCreate, TagOut
from .schemas.ai import AskRequest, AskResponse, SourceOut, SummarizeRequest, SummarizeResponse

__all__ = [
    "NoteCreate",
    "NoteUpdate",
    "NoteOut",
    "FolderCreate",
    "FolderUpdate",
    "FolderOut",
    "TagCreate",
    "TagOut",
    "AskRequest",
    "AskResponse",
    "SourceOut",
    "SummarizeRequest",
    "SummarizeResponse",
]
