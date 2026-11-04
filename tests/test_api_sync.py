"""
Test suite cho Offline-First Two-Way Sync API:
- Push Batch: CREATE, UPDATE, DELETE
- Idempotency khi push lặp lại cùng event
- Optimistic Concurrency Control: phát hiện CONFLICT khi server_version > client base_version
- Pull Changes: Cursor phân trang ổn định, bảo đảm chỉ nhận dữ liệu của authenticated user
- User Isolation: User A không thể push thay đổi cho entity của User B hoặc pull events của User B
"""
import uuid
import pytest

def test_sync_push_create_note(client, auth_headers_user_a):
    note_uuid = str(uuid.uuid4())
    payload = {
        "items": [
            {
                "entity_type": "note",
                "entity_id": note_uuid,
                "action": "CREATE",
                "version": 1,
                "client_id": "client-android-01",
                "payload": {
                    "title": "Ghi chú tạo khi offline",
                    "content": "Nội dung offline push lên server",
                    "folder": "Công việc",
                    "is_pinned": True,
                },
            }
        ]
    }
    response = client.post("/api/sync/push", json=payload, headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert len(data["results"]) == 1
    res = data["results"][0]
    assert res["status"] == "SUCCESS"
    assert res["entity_id"] == note_uuid
    assert res["server_version"] == 1

def test_sync_push_idempotency(client, auth_headers_user_a):
    note_uuid = str(uuid.uuid4())
    push_item = {
        "entity_type": "note",
        "entity_id": note_uuid,
        "action": "CREATE",
        "version": 1,
        "payload": {"title": "Idempotent Note", "content": "Sample"},
    }
    # Gửi lần 1
    res1 = client.post("/api/sync/push", json={"items": [push_item]}, headers=auth_headers_user_a)
    assert res1.json()["results"][0]["status"] == "SUCCESS"

    # Gửi lại lần 2 (do retry timeout) -> Server nhận diện đã tồn tại và trả SUCCESS mà không nhân bản dữ liệu
    res2 = client.post("/api/sync/push", json={"items": [push_item]}, headers=auth_headers_user_a)
    assert res2.json()["results"][0]["status"] == "SUCCESS"
    assert "idempotency" in res2.json()["results"][0]["message"]

def test_sync_push_update_and_conflict(client, auth_headers_user_a):
    note_uuid = str(uuid.uuid4())
    # 1. Tạo note version 1
    client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "CREATE",
            "version": 1,
            "payload": {"title": "Version 1", "content": "Base content"}
        }]
    }, headers=auth_headers_user_a)

    # 2. Update thành công từ thiết bị 1 -> Server version thành 2
    res_up1 = client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "UPDATE",
            "version": 1, # base version hợp lệ
            "payload": {"title": "Version 2 from Device 1"}
        }]
    }, headers=auth_headers_user_a)
    assert res_up1.json()["results"][0]["status"] == "SUCCESS"
    assert res_up1.json()["results"][0]["server_version"] == 2

    # 3. Thiết bị 2 gửi update với base version cũ là 1 -> Server phát hiện CONFLICT
    res_conflict = client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "UPDATE",
            "version": 1, # base version lỗi thời
            "payload": {"title": "Conflicting Update from Device 2"}
        }]
    }, headers=auth_headers_user_a)
    assert res_conflict.json()["results"][0]["status"] == "CONFLICT"
    assert res_conflict.json()["results"][0]["server_version"] == 2
    assert res_conflict.json()["results"][0]["server_copy"]["title"] == "Version 2 from Device 1"

def test_sync_push_delete_tombstone(client, auth_headers_user_a):
    note_uuid = str(uuid.uuid4())
    client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "CREATE",
            "version": 1,
            "payload": {"title": "Note to delete"}
        }]
    }, headers=auth_headers_user_a)

    del_resp = client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "DELETE",
            "version": 1,
        }]
    }, headers=auth_headers_user_a)
    assert del_resp.json()["results"][0]["status"] == "SUCCESS"

def test_sync_pull_changes(client, auth_headers_user_a):
    note_uuid = str(uuid.uuid4())
    client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid,
            "action": "CREATE",
            "version": 1,
            "payload": {"title": "Pull Test Note", "content": "Pull content"}
        }]
    }, headers=auth_headers_user_a)

    # Pull từ cursor 0
    pull_res = client.get("/api/sync/pull?cursor=0", headers=auth_headers_user_a)
    assert pull_res.status_code == 200
    data = pull_res.json()
    assert len(data["events"]) >= 1
    assert data["new_cursor"] > 0
    latest_event = data["events"][-1]
    assert latest_event["entity_type"] == "note"
    assert latest_event["entity_id"] == note_uuid
    assert latest_event["action"] == "CREATE"
    assert latest_event["data"]["title"] == "Pull Test Note"

def test_sync_user_isolation(client, auth_headers_user_a, auth_headers_user_b):
    # User A tạo note qua sync push
    note_uuid_a = str(uuid.uuid4())
    client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid_a,
            "action": "CREATE",
            "version": 1,
            "payload": {"title": "User A Private Sync Note"}
        }]
    }, headers=auth_headers_user_a)

    # User B cố tình push UPDATE vào note của User A -> REJECTED
    cross_push = client.post("/api/sync/push", json={
        "items": [{
            "entity_type": "note",
            "entity_id": note_uuid_a,
            "action": "UPDATE",
            "version": 1,
            "payload": {"title": "User B Hacked"}
        }]
    }, headers=auth_headers_user_b)
    assert cross_push.json()["results"][0]["status"] == "REJECTED"

    # User B pull events -> Không thấy sự kiện nào của User A
    pull_b = client.get("/api/sync/pull?cursor=0", headers=auth_headers_user_b)
    assert len(pull_b.json()["events"]) == 0
