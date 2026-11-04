from pydantic import BaseModel, Field
from typing import Literal

class AskRequest(BaseModel):
    question: str = Field(min_length=1, max_length=2000)
    note_id: int | str | None = None

class SourceOut(BaseModel):
    note_id: int | str
    title: str
    excerpt: str

class AskResponse(BaseModel):
    answer: str
    sources: list[SourceOut]

class SummarizeRequest(BaseModel):
    content: str = Field(min_length=1)
    max_sentences: int = Field(default=3, ge=1, le=10)

class SummarizeResponse(BaseModel):
    summary: str

class WritingAssistRequest(BaseModel):
    content: str = Field(min_length=1)
    action: Literal["improve", "fix_spelling", "expand", "shorten", "checklist", "action_plan"] = Field(
        default="improve",
        description="Loại trợ giúp viết: improve, fix_spelling, expand, shorten, checklist, action_plan"
    )

class WritingAssistResponse(BaseModel):
    action: str
    result: str

class FlashcardItem(BaseModel):
    id: str
    question: str
    answer: str
    hint: str | None = None

class FlashcardResponse(BaseModel):
    note_id: int | str | None = None
    flashcards: list[FlashcardItem]

class NluRequest(BaseModel):
    query: str = Field(min_length=1, max_length=2000, description="Yêu cầu bằng ngôn ngữ tự nhiên tiếng Việt")
    context_note_id: int | str | None = None

class ToolAction(BaseModel):
    name: str
    description: str
    parameters: dict = Field(default_factory=dict)
    requires_confirmation: bool = False

class NluResponse(BaseModel):
    intent: str
    summary_message: str
    tool_action: ToolAction | None = None
    sources: list[SourceOut] = Field(default_factory=list)
    result_data: dict | None = None
