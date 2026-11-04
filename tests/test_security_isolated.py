"""
Bộ kiểm thử cô lập cho Security & Cryptography:
- Password Hashing (bcrypt): verify_password, get_password_hash, truncation 72 bytes
- JWT Tokens (HS256): create_access_token, decode_access_token, expiration, invalid token, tampering
- Refresh Tokens: hash_token, generate_refresh_token
Không truy cập Database, không đọc secret thật.
"""
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import pytest
from datetime import timedelta
from app.core import security
from app.core.exceptions import AppException

def test_password_hashing_and_verification():
    raw_password = "SecurePassword@123!"
    hashed = security.get_password_hash(raw_password)
    assert hashed != raw_password
    assert hashed.startswith("$2b$") or hashed.startswith("$2a$")
    assert security.verify_password(raw_password, hashed) is True
    assert security.verify_password("WrongPassword@123!", hashed) is False

def test_password_empty_and_special_chars():
    pwd = "TàiKhoản!@#$_123456_TiếngViệt"
    hashed = security.get_password_hash(pwd)
    assert security.verify_password(pwd, hashed) is True

def test_password_truncation_72_bytes():
    # bcrypt có giới hạn 72 bytes, hàm băm xử lý an toàn bằng slicing [:72]
    long_pwd = "A" * 100
    hashed = security.get_password_hash(long_pwd)
    # 72 ký tự đầu khớp
    assert security.verify_password("A" * 72, hashed) is True
    # Khác ký tự đầu
    assert security.verify_password("B" * 72, hashed) is False

def test_create_and_decode_access_token():
    payload = {"sub": "user-12345-uuid", "email": "test@smartnote.ai"}
    token = security.create_access_token(payload)
    decoded = security.decode_access_token(token)
    assert decoded["sub"] == "user-12345-uuid"
    assert decoded["email"] == "test@smartnote.ai"
    assert decoded["type"] == "access"
    assert "exp" in decoded
    assert "iat" in decoded
    assert "jti" in decoded

def test_access_token_expired():
    payload = {"sub": "expired-user"}
    token = security.create_access_token(payload, expires_delta=timedelta(seconds=-10))
    with pytest.raises(AppException) as exc_info:
        security.decode_access_token(token)
    assert exc_info.value.status_code == 401

def test_access_token_tampered():
    token = security.create_access_token({"sub": "legit-user"})
    tampered = token[:-4] + "abcd"
    with pytest.raises(AppException) as exc_info:
        security.decode_access_token(tampered)
    assert exc_info.value.status_code == 401

def test_token_wrong_type():
    from jose import jwt
    from app.core.config import settings
    # Token loại 'refresh' không được decode qua decode_access_token
    token = jwt.encode({"sub": "user", "type": "refresh"}, settings.jwt_secret, algorithm="HS256")
    with pytest.raises(AppException) as exc_info:
        security.decode_access_token(token)
    assert exc_info.value.status_code == 401

def test_refresh_token_generation():
    raw_token, token_hash, expires_at = security.generate_refresh_token()
    assert raw_token.startswith("rt_")
    assert len(token_hash) == 64  # SHA-256 hex string
    assert security.hash_token(raw_token) == token_hash
