import hashlib
import uuid
from datetime import datetime, timedelta, timezone
import bcrypt
from jose import JWTError, jwt
from .config import settings
from .exceptions import AppException

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 14

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        pwd_bytes = plain_password.encode("utf-8")[:72]
        return bcrypt.checkpw(pwd_bytes, hashed_password.encode("utf-8"))
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    pwd_bytes = password.encode("utf-8")[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode("utf-8")

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({
        "exp": expire,
        "iat": now,
        "jti": uuid.uuid4().hex,
        "type": "access",
    })
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=ALGORITHM)

def decode_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
        if payload.get("type") != "access":
            raise AppException(status_code=401, detail="Token không hợp lệ hoặc sai loại")
        return payload
    except JWTError:
        raise AppException(status_code=401, detail="Token không hợp lệ hoặc đã hết hạn")

def hash_token(raw_token: str) -> str:
    """Băm token (refresh token) bằng SHA-256 để lưu trữ an toàn."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

def generate_refresh_token() -> tuple[str, str, datetime]:
    """
    Sinh Refresh Token ngẫu nhiên bảo mật cao và mã băm SHA-256 để lưu DB.
    Trả về: (raw_token, token_hash, expires_at)
    """
    raw_token = f"rt_{uuid.uuid4().hex}_{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    expires_at = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    return raw_token, token_hash, expires_at
