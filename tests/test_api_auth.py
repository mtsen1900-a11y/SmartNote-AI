"""
Test suite cho Authentication API:
- Register: hợp lệ, sai định dạng email, thiếu trường, email trùng
- Login: đúng thông tin, sai password, user không tồn tại
- Token: access token protected endpoint (/api/auth/me), token hết hạn, sai chữ ký
- Refresh token: xoay vòng token (rotation), token hết hạn, logout hủy token
"""
import pytest
from app.core.security import create_access_token
from datetime import timedelta

def test_register_success(client):
    payload = {
        "email": "newuser@example.com",
        "password": "StrongPassword@123!",
        "full_name": "New User"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "newuser@example.com"
    assert data["user"]["full_name"] == "New User"
    assert "hashed_password" not in data["user"]

def test_register_invalid_email(client):
    payload = {
        "email": "not-an-email",
        "password": "Password123!",
        "full_name": "Invalid"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 422

def test_register_missing_field(client):
    payload = {
        "email": "missing_pass@example.com"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 422

def test_register_duplicate_email(client, synthetic_user_a):
    payload = {
        "email": synthetic_user_a.email,
        "password": "AnotherPassword@123!",
        "full_name": "Duplicate User"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 409
    assert "Email này đã được sử dụng" in response.json()["detail"]

def test_login_success(client, synthetic_user_a):
    payload = {
        "email": synthetic_user_a.email,
        "password": "PasswordA@123!"
    }
    response = client.post("/api/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == synthetic_user_a.email

def test_login_wrong_password(client, synthetic_user_a):
    payload = {
        "email": synthetic_user_a.email,
        "password": "WrongPassword@123!"
    }
    response = client.post("/api/auth/login", json=payload)
    assert response.status_code == 401

def test_login_nonexistent_user(client):
    payload = {
        "email": "doesnotexist@example.com",
        "password": "Password123!"
    }
    response = client.post("/api/auth/login", json=payload)
    assert response.status_code == 401

def test_me_protected_endpoint(client, auth_headers_user_a, synthetic_user_a):
    response = client.get("/api/auth/me", headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == synthetic_user_a.email
    assert data["id"] == synthetic_user_a.id
    assert "username" in data
    assert "workspace_slug" in data
    assert data["workspace_slug"] == f"u/{data['username']}"

def test_me_without_token(client):
    response = client.get("/api/auth/me")
    assert response.status_code == 401

def test_me_with_tampered_token(client):
    response = client.get("/api/auth/me", headers={"Authorization": "Bearer fake.tampered.token"})
    assert response.status_code == 401

def test_me_with_expired_token(client, synthetic_user_a):
    expired_token = create_access_token(
        {"sub": str(synthetic_user_a.id), "email": synthetic_user_a.email},
        expires_delta=timedelta(seconds=-10)
    )
    response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert response.status_code == 401

def test_refresh_token_rotation_and_reuse(client):
    # 1. Đăng ký để có refresh token
    reg = client.post("/api/auth/register", json={
        "email": "rotation_test@example.com",
        "password": "RotationPassword@123!",
        "full_name": "Rotation User"
    })
    tokens = reg.json()
    rt1 = tokens["refresh_token"]

    # 2. Dùng rt1 để refresh -> nhận rt2
    refresh_resp = client.post("/api/auth/refresh", json={"refresh_token": rt1})
    assert refresh_resp.status_code == 200
    tokens2 = refresh_resp.json()
    rt2 = tokens2["refresh_token"]
    assert rt1 != rt2

    # 3. Thử dùng lại rt1 (đã bị xoay vòng và thu hồi) -> Phải bị từ chối 401
    reuse_resp = client.post("/api/auth/refresh", json={"refresh_token": rt1})
    assert reuse_resp.status_code == 401

def test_logout_revokes_refresh_token(client):
    reg = client.post("/api/auth/register", json={
        "email": "logout_test@example.com",
        "password": "LogoutPassword@123!",
        "full_name": "Logout User"
    })
    tokens = reg.json()
    rt = tokens["refresh_token"]

    # Logout
    logout_resp = client.post("/api/auth/logout", json={"refresh_token": rt})
    assert logout_resp.status_code == 200

    # Sau khi logout, refresh token không còn dùng được
    refresh_resp = client.post("/api/auth/refresh", json={"refresh_token": rt})
    assert refresh_resp.status_code == 401
