from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class TagCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    color: str = Field(default="#10B981", max_length=20)

class TagOut(BaseModel):
    id: UUID
    name: str
    color: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
