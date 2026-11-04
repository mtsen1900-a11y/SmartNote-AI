"""
Pytest configuration for isolated in-memory test suite.
Tất cả test đều dùng SQLite in-memory, mock external services (Ollama, ChromaDB),
và không kết nối tới PostgreSQL 5434 hay DA02.
"""
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app
from app.core.security import create_access_token
from app.models.user import User

SQLITE_TEST_URL = "sqlite:///:memory:"

@pytest.fixture(scope="session")
def test_engine():
    engine = create_engine(
        SQLITE_TEST_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db_session(test_engine):
    TestingSessionLocal = sessionmaker(bind=test_engine, autoflush=False, autocommit=False)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        for table in reversed(Base.metadata.sorted_tables):
            session.execute(table.delete())
        session.commit()
        session.close()

@pytest.fixture
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with patch("app.services.note_service.ai_service.index_note", new_callable=AsyncMock) as mock_index, \
         patch("app.services.note_service.ai_service.remove_note_vectors", new_callable=AsyncMock) as mock_remove, \
         patch("app.services.ai_service.ai_service.assign_legacy_chunks", new_callable=MagicMock) as mock_legacy:
        with TestClient(app) as test_client:
            yield test_client
    app.dependency_overrides.clear()

@pytest.fixture
def synthetic_user_a(db_session):
    from app.core.security import get_password_hash
    user = User(
        email="user_alpha@example.com",
        hashed_password=get_password_hash("PasswordA@123!"),
        full_name="User Alpha",
        is_active=True,
        is_system=False,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

@pytest.fixture
def synthetic_user_b(db_session):
    from app.core.security import get_password_hash
    user = User(
        email="user_beta@example.com",
        hashed_password=get_password_hash("PasswordB@123!"),
        full_name="User Beta",
        is_active=True,
        is_system=False,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

@pytest.fixture
def auth_headers_user_a(synthetic_user_a):
    token = create_access_token({"sub": str(synthetic_user_a.id), "email": synthetic_user_a.email})
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def auth_headers_user_b(synthetic_user_b):
    token = create_access_token({"sub": str(synthetic_user_b.id), "email": synthetic_user_b.email})
    return {"Authorization": f"Bearer {token}"}
