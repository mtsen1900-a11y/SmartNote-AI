import os
import sys
from pathlib import Path
import pytest
from pydantic import ValidationError

# Đảm bảo import app chính xác dù chạy pytest từ workspace root hay từ backend
BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import Settings, INSECURE_JWT_SECRETS, BACKEND_DIR, ENV_PATH

# Giá trị hợp lệ giả lập phục vụ test (không dùng dữ liệu thật)
DUMMY_VALID_DB_URL = "postgresql+psycopg://test_user:strong_test_pass_12345@127.0.0.1:5434/test_db"
DUMMY_VALID_JWT_SECRET = "a" * 32  # 32 ký tự, không thuộc danh sách insecure

def test_missing_database_url_fail_fast(monkeypatch):
    """1. Thiếu DATABASE_URL -> bị từ chối (ValidationError)."""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("JWT_SECRET", DUMMY_VALID_JWT_SECRET)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    errors = exc_info.value.errors()
    assert any(err["loc"] == ("database_url",) for err in errors)

def test_missing_jwt_secret_fail_fast(monkeypatch):
    """2. Thiếu JWT_SECRET -> bị từ chối (ValidationError)."""
    monkeypatch.delenv("JWT_SECRET", raising=False)
    monkeypatch.setenv("DATABASE_URL", DUMMY_VALID_DB_URL)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    errors = exc_info.value.errors()
    assert any(err["loc"] == ("jwt_secret",) for err in errors)

@pytest.mark.parametrize("insecure_secret", list(INSECURE_JWT_SECRETS))
def test_insecure_jwt_secret_rejected(monkeypatch, insecure_secret):
    """3. JWT_SECRET là secret mặc định đã biết -> bị từ chối."""
    monkeypatch.setenv("DATABASE_URL", DUMMY_VALID_DB_URL)
    monkeypatch.setenv("JWT_SECRET", insecure_secret)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "JWT_SECRET không được sử dụng giá trị mặc định hoặc placeholder không an toàn" in msg

def test_jwt_secret_placeholder_pattern_rejected(monkeypatch):
    """JWT_SECRET là placeholder dạng <...> bất kỳ dài hơn 32 ký tự -> bị từ chối."""
    monkeypatch.setenv("DATABASE_URL", DUMMY_VALID_DB_URL)
    monkeypatch.setenv("JWT_SECRET", "<CUSTOM_PLACEHOLDER_LONGER_THAN_32_CHARS>")
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "JWT_SECRET không được sử dụng giá trị mặc định hoặc placeholder không an toàn" in msg

def test_short_jwt_secret_rejected(monkeypatch):
    """4. JWT_SECRET ngắn hơn 32 ký tự -> bị từ chối."""
    monkeypatch.setenv("DATABASE_URL", DUMMY_VALID_DB_URL)
    monkeypatch.setenv("JWT_SECRET", "short_secret_only_24_chars_!")
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "JWT_SECRET phải có độ dài tối thiểu 32 ký tự" in msg

def test_database_url_with_placeholder_password_rejected(monkeypatch):
    """5. DATABASE_URL chứa password placeholder 'change_this_password' -> bị từ chối."""
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://smartnote:change_this_password@127.0.0.1:5434/smartnote")
    monkeypatch.setenv("JWT_SECRET", DUMMY_VALID_JWT_SECRET)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "placeholder" in msg

@pytest.mark.parametrize("placeholder_pwd", ["<YOUR_DB_PASSWORD>", "<CUSTOM_DB_PASS>", "<FOO>"])
def test_database_url_with_bracket_placeholder_rejected(monkeypatch, placeholder_pwd):
    """DATABASE_URL chứa password dạng <...> placeholder -> bị từ chối."""
    url = f"postgresql+psycopg://smartnote:{placeholder_pwd}@127.0.0.1:5434/smartnote"
    monkeypatch.setenv("DATABASE_URL", url)
    monkeypatch.setenv("JWT_SECRET", DUMMY_VALID_JWT_SECRET)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "placeholder" in msg

def test_invalid_database_url_format_rejected(monkeypatch):
    """Kiểm tra DATABASE_URL sai định dạng URL -> bị từ chối."""
    monkeypatch.setenv("DATABASE_URL", "not_a_valid_url")
    monkeypatch.setenv("JWT_SECRET", DUMMY_VALID_JWT_SECRET)
    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=None)
    msg = str(exc_info.value)
    assert "DATABASE_URL" in msg

def test_valid_configuration_accepted(monkeypatch):
    """6. Cấu hình hợp lệ -> được chấp nhận."""
    monkeypatch.setenv("DATABASE_URL", DUMMY_VALID_DB_URL)
    monkeypatch.setenv("JWT_SECRET", DUMMY_VALID_JWT_SECRET)
    cfg = Settings(_env_file=None)
    assert cfg.database_url == DUMMY_VALID_DB_URL
    assert cfg.jwt_secret == DUMMY_VALID_JWT_SECRET
    assert cfg.chroma_port == 8002

def test_mock_env_file_independent_of_cwd(tmp_path, monkeypatch):
    """Nạp cấu hình từ file giả lập độc lập với working directory mà không đọc .env thật."""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("JWT_SECRET", raising=False)
    
    mock_env = tmp_path / "mock.env"
    mock_env.write_text(
        f"DATABASE_URL={DUMMY_VALID_DB_URL}\nJWT_SECRET={DUMMY_VALID_JWT_SECRET}\nCHROMA_PORT=8999\n",
        encoding="utf-8"
    )
    
    cfg = Settings(_env_file=str(mock_env))
    assert cfg.database_url == DUMMY_VALID_DB_URL
    assert cfg.jwt_secret == DUMMY_VALID_JWT_SECRET
    assert cfg.chroma_port == 8999

def test_absolute_env_path_configuration():
    """7. Đường dẫn tuyệt đối backend/.env được xác định chính xác."""
    assert BACKEND_DIR.is_dir()
    assert ENV_PATH == BACKEND_DIR / ".env"
    assert ENV_PATH.is_file()
