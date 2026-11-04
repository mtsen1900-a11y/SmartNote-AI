"""
Test suite cho Repository & Logic của Folders và Tags:
- Folder CRUD: Create, List theo user, Update, Soft delete
- Tag CRUD: Create, List theo user, Delete
- User Isolation: Folder và Tag chỉ thuộc về user tạo ra chúng
"""
import uuid
import pytest
from app.models.folder import Folder
from app.models.tag import Tag
from app.repositories.folder_repository import FolderRepository
from app.repositories.tag_repository import TagRepository

@pytest.fixture
def folder_repo():
    return FolderRepository()

@pytest.fixture
def tag_repo():
    return TagRepository()

def test_folder_crud_and_user_isolation(db_session, folder_repo, synthetic_user_a, synthetic_user_b):
    # 1. User A tạo folder
    folder_a = Folder(
        id=uuid.uuid4(),
        user_id=synthetic_user_a.id,
        name="Thư mục A",
        color="#3498db",
    )
    saved_a = folder_repo.create(db_session, folder_a)
    assert saved_a.id == folder_a.id
    assert saved_a.name == "Thư mục A"
    assert saved_a.version == 1

    # 2. User B tạo folder
    folder_b = Folder(
        id=uuid.uuid4(),
        user_id=synthetic_user_b.id,
        name="Thư mục B",
        color="#e74c3c",
    )
    folder_repo.create(db_session, folder_b)

    # 3. User isolation: User A list chỉ thấy folder của A
    folders_a = folder_repo.list_by_user(db_session, synthetic_user_a.id)
    assert len(folders_a) == 1
    assert folders_a[0].name == "Thư mục A"

    # User B list chỉ thấy folder của B
    folders_b = folder_repo.list_by_user(db_session, synthetic_user_b.id)
    assert len(folders_b) == 1
    assert folders_b[0].name == "Thư mục B"

    # 4. Update folder
    saved_a.name = "Thư mục A (Đã đổi)"
    updated_a = folder_repo.update(db_session, saved_a)
    assert updated_a.name == "Thư mục A (Đã đổi)"
    assert updated_a.version == 2

    # 5. Soft delete folder
    folder_repo.soft_delete(db_session, updated_a)
    assert updated_a.is_deleted is True
    assert updated_a.version == 3

    # List lại không còn folder đã xóa mềm
    active_folders = folder_repo.list_by_user(db_session, synthetic_user_a.id)
    assert len(active_folders) == 0

def test_tag_crud_and_user_isolation(db_session, tag_repo, synthetic_user_a, synthetic_user_b):
    # 1. User A tạo tag
    tag_a = Tag(
        id=uuid.uuid4(),
        user_id=synthetic_user_a.id,
        name="QuanTrọng",
        color="#f39c12",
    )
    saved_a = tag_repo.create(db_session, tag_a)
    assert saved_a.name == "QuanTrọng"

    # 2. User B tạo tag
    tag_b = Tag(
        id=uuid.uuid4(),
        user_id=synthetic_user_b.id,
        name="ÝTưởng",
        color="#2ecc71",
    )
    tag_repo.create(db_session, tag_b)

    # 3. User isolation: list_by_user
    tags_a = tag_repo.list_by_user(db_session, synthetic_user_a.id)
    assert len(tags_a) == 1
    assert tags_a[0].name == "QuanTrọng"

    tags_b = tag_repo.list_by_user(db_session, synthetic_user_b.id)
    assert len(tags_b) == 1
    assert tags_b[0].name == "ÝTưởng"

    # 4. Delete tag
    tag_repo.delete(db_session, saved_a)
    tags_a_after = tag_repo.list_by_user(db_session, synthetic_user_a.id)
    assert len(tags_a_after) == 0
