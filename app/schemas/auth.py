from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=100, description="Mật khẩu tối thiểu 6 ký tự")
    full_name: str = Field(default="", max_length=100)

class LoginRequest(BaseModel):
    email: str | None = None
    username_or_email: str | None = None
    password: str = Field(min_length=1)

class UserOut(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool
    created_at: datetime
    username: str = ""
    workspace_slug: str = ""
    avatar_url: str = ""

    model_config = ConfigDict(from_attributes=True)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 1800  # 30 phút
    user: UserOut | None = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str
