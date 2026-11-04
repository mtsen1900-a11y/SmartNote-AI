from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    UserOut,
)
from ...services.auth_service import auth_service
from ..dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    """
    Đăng ký tài khoản người dùng mới.
    Nếu là người dùng thật đầu tiên, tự động liên kết an toàn 2 ghi chú gốc từ hệ thống.
    """
    return auth_service.register(db, data)

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    """
    Đăng nhập bằng email và mật khẩu, trả về Access Token (JWT 30m) và Refresh Token (7d).
    """
    return auth_service.login(db, data)

@router.post("/refresh", response_model=TokenResponse)
def refresh_token(data: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Cấp mới cặp Access Token / Refresh Token bằng cơ chế Rotation (thu hồi token cũ).
    """
    return auth_service.refresh(db, data.refresh_token)

@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(data: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Thu hồi refresh token đã cung cấp để hủy phiên làm việc.
    """
    auth_service.logout(db, data.refresh_token)
    return {"message": "Đăng xuất thành công"}

@router.get("/me", response_model=UserOut)
def get_profile(current_user: User = Depends(get_current_user)):
    """
    Lấy thông tin tài khoản đang đăng nhập từ Bearer token.
    """
    return current_user
