from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from sqlalchemy.engine import make_url

# Xác định đường dẫn tuyệt đối đến thư mục backend
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
ENV_PATH = BACKEND_DIR / ".env"

INSECURE_JWT_SECRETS = {
    "isolated-smartnote-ai-secret-key-2026",
    "replace-with-a-very-long-random-secret-for-isolated-smartnote",
    "your-secret-key-here",
    "<GENERATE_WITH_PYTHON_SECRETS_TOKEN_HEX_32>",
}

class Settings(BaseSettings):
    # DATABASE_URL và JWT_SECRET là bắt buộc (không có giá trị mặc định)
    database_url: str
    jwt_secret: str

    chroma_host: str = "localhost"
    chroma_port: int = 8002
    ollama_url: str = "http://localhost:11434"
    ollama_chat_model: str = "qwen2.5:3b"
    ollama_embed_model: str = "nomic-embed-text"
    cors_origins: str = "http://localhost:3000,http://localhost:8080,http://localhost:5000,http://127.0.0.1:3000,http://127.0.0.1:8080"
    app_name: str = "Smart Note AI API"
    app_version: str = "0.2.0"
    debug: bool = False

    @field_validator("jwt_secret")
    @classmethod
    def validate_jwt_secret(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("JWT_SECRET không được để trống.")
        clean_v = v.strip()
        if clean_v in INSECURE_JWT_SECRETS or (clean_v.startswith("<") and clean_v.endswith(">")):
            raise ValueError("JWT_SECRET không được sử dụng giá trị mặc định hoặc placeholder không an toàn.")
        if len(clean_v) < 32:
            raise ValueError("JWT_SECRET phải có độ dài tối thiểu 32 ký tự.")
        return clean_v

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("DATABASE_URL không được để trống.")
        clean_v = v.strip()
        try:
            url = make_url(clean_v)
        except Exception:
            raise ValueError("DATABASE_URL không đúng định dạng URL hợp lệ.")
        pwd = url.password or ""
        if pwd == "change_this_password" or pwd == "<YOUR_DB_PASSWORD>" or (pwd.startswith("<") and pwd.endswith(">")):
            raise ValueError("DATABASE_URL đang sử dụng mật khẩu placeholder không an toàn.")
        return clean_v

    # Luôn đọc backend/.env bằng đường dẫn tuyệt đối; OS environment variables vẫn có độ ưu tiên cao hơn
    model_config = SettingsConfigDict(
        env_file=str(ENV_PATH),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
