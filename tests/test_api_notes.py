"""
Test suite cho Notes API và User Isolation:
- CRUD Notes: create, read, list, update, delete (soft delete/tombstone)
- User Isolation:
  + User A không thể đọc note của User B
  + User A không thể sửa note của User B
  + User A không thể xóa note của User B
  + List notes chỉ hiển thị note thuộc user hiện tại
"""
import pytest

def test_create_note_success(client, auth_headers_user_a, synthetic_user_a):
    payload = {
        "title": "Ghi chú công việc",
        "content": "Nội dung ghi chú của User A",
        "folder": "Công việc",
        "is_pinned": True,
        "is_archived": False,
    }
    response = client.post("/api/notes", json=payload, headers=auth_headers_user_a)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Ghi chú công việc"
    assert data["content"] == "Nội dung ghi chú của User A"
    assert data["is_pinned"] is True
    assert "id" in data
    assert "uuid" in data

def test_get_note_by_id_and_uuid(client, auth_headers_user_a):
    create_resp = client.post("/api/notes", json={"title": "Test Find", "content": "Sample"}, headers=auth_headers_user_a)
    note_data = create_resp.json()
    note_id = note_data["id"]
    note_uuid = note_data["uuid"]

    # Tìm theo id số
    resp_id = client.get(f"/api/notes/{note_id}", headers=auth_headers_user_a)
    assert resp_id.status_code == 200
    assert resp_id.json()["title"] == "Test Find"

    # Tìm theo UUID
    resp_uuid = client.get(f"/api/notes/{note_uuid}", headers=auth_headers_user_a)
    assert resp_uuid.status_code == 200
    assert resp_uuid.json()["title"] == "Test Find"

def test_list_notes_with_query_filter(client, auth_headers_user_a):
    client.post("/api/notes", json={"title": "Học Flutter", "content": "Drift ORM"}, headers=auth_headers_user_a)
    client.post("/api/notes", json={"title": "Học FastAPI", "content": "Python 3.12"}, headers=auth_headers_user_a)

    # Search 'Flutter'
    resp = client.get("/api/notes?q=Flutter", headers=auth_headers_user_a)
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert items[0]["title"] == "Học Flutter"

def test_update_note(client, auth_headers_user_a):
    create_resp = client.post("/api/notes", json={"title": "Original Title", "content": "Original Content"}, headers=auth_headers_user_a)
    note_id = create_resp.json()["id"]

    update_payload = {"title": "Updated Title", "content": "Updated Content", "is_pinned": True}
    update_resp = client.put(f"/api/notes/{note_id}", json=update_payload, headers=auth_headers_user_a)
    assert update_resp.status_code == 200
    updated = update_resp.json()
    assert updated["title"] == "Updated Title"
    assert updated["content"] == "Updated Content"
    assert updated["is_pinned"] is True

def test_delete_note_soft_delete(client, auth_headers_user_a):
    create_resp = client.post("/api/notes", json={"title": "To be deleted", "content": "Gone soon"}, headers=auth_headers_user_a)
    note_id = create_resp.json()["id"]

    del_resp = client.delete(f"/api/notes/{note_id}", headers=auth_headers_user_a)
    assert del_resp.status_code == 200
    assert del_resp.json()["deleted"] is True

    # Truy vấn lại note đã xóa -> 404
    get_resp = client.get(f"/api/notes/{note_id}", headers=auth_headers_user_a)
    assert get_resp.status_code == 404

# --- USER ISOLATION TESTS (BẮT BUỘC) ---

def test_user_isolation_list_notes(client, auth_headers_user_a, auth_headers_user_b):
    # User A tạo 2 notes
    client.post("/api/notes", json={"title": "A Note 1", "content": "Private A1"}, headers=auth_headers_user_a)
    client.post("/api/notes", json={"title": "A Note 2", "content": "Private A2"}, headers=auth_headers_user_a)

    # User B tạo 1 note
    client.post("/api/notes", json={"title": "B Note 1", "content": "Private B1"}, headers=auth_headers_user_b)

    # User A list notes chỉ thấy 2 notes của A
    resp_a = client.get("/api/notes", headers=auth_headers_user_a)
    assert resp_a.status_code == 200
    notes_a = resp_a.json()
    assert len(notes_a) == 2
    assert all("A Note" in n["title"] for n in notes_a)

    # User B list notes chỉ thấy 1 note của B
    resp_b = client.get("/api/notes", headers=auth_headers_user_b)
    assert resp_b.status_code == 200
    notes_b = resp_b.json()
    assert len(notes_b) == 1
    assert notes_b[0]["title"] == "B Note 1"

def test_user_isolation_read_cross_user_denied(client, auth_headers_user_a, auth_headers_user_b):
    # User A tạo note
    create_resp = client.post("/api/notes", json={"title": "A Secret", "content": "Top Secret A"}, headers=auth_headers_user_a)
    note_id = create_resp.json()["id"]

    # User B cố tình đọc note của User A -> 403 Forbidden
    cross_read = client.get(f"/api/notes/{note_id}", headers=auth_headers_user_b)
    assert cross_read.status_code == 403
    assert "Bạn không có quyền truy cập" in cross_read.json()["detail"]

def test_user_isolation_update_cross_user_denied(client, auth_headers_user_a, auth_headers_user_b):
    # User A tạo note
    create_resp = client.post("/api/notes", json={"title": "A Document", "content": "Original Content"}, headers=auth_headers_user_a)
    note_id = create_resp.json()["id"]

    # User B cố tình sửa note của User A -> 403 Forbidden
    cross_update = client.put(f"/api/notes/{note_id}", json={"title": "Hacked Title"}, headers=auth_headers_user_b)
    assert cross_update.status_code == 403
    assert "Bạn không có quyền truy cập" in cross_update.json()["detail"]

def test_user_isolation_delete_cross_user_denied(client, auth_headers_user_a, auth_headers_user_b):
    # User A tạo note
    create_resp = client.post("/api/notes", json={"title": "A Safe File", "content": "Important"}, headers=auth_headers_user_a)
    note_id = create_resp.json()["id"]

    # User B cố tình xóa note của User A -> 403 Forbidden
    cross_delete = client.delete(f"/api/notes/{note_id}", headers=auth_headers_user_b)
    assert cross_delete.status_code == 403
    assert "Bạn không có quyền truy cập" in cross_delete.json()["detail"]

    # User A vẫn có thể đọc bình thường vì chưa bị xóa
    check_read = client.get(f"/api/notes/{note_id}", headers=auth_headers_user_a)
    assert check_read.status_code == 200
