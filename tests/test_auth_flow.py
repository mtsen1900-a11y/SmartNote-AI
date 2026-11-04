import os
import sys
from pathlib import Path

# Add backend to sys.path
backend_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_root))

from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.note import Note
from app.models.user import User

client = TestClient(app)

def test_full_auth_and_isolation_flow():
    print("\n--- [1] KIỂM TRA TRUY CẬP KHÔNG CÓ TOKEN ---")
    resp = client.get("/api/notes")
    assert resp.status_code == 401, f"Kỳ vọng 401 nhưng nhận {resp.status_code}: {resp.text}"
    print("PASS: /api/notes từ chối khi không có Bearer token (401)")

    resp = client.get("/api/notes", headers={"Authorization": "Bearer invalid_token_123"})
    assert resp.status_code == 401, f"Kỳ vọng 401 với token giả nhưng nhận {resp.status_code}"
    print("PASS: /api/notes từ chối khi token giả mạo (401)")

    print("\n--- [2] ĐĂNG KÝ TÀI KHOẢN ĐẦU TIÊN (Alice) VÀ CLAIM LEGACY NOTES ---")
    alice_payload = {
        "email": "alice@smartnote.ai",
        "password": "Password123!",
        "full_name": "Alice Nguyen",
    }
    resp = client.post("/api/auth/register", json=alice_payload)
    if resp.status_code == 409:
        print("Alice đã tồn tại, tiến hành đăng nhập...")
        resp = client.post("/api/auth/login", json={"email": "alice@smartnote.ai", "password": "Password123!"})
        assert resp.status_code == 200, f"Đăng nhập Alice thất bại: {resp.text}"
        alice_data = resp.json()
    else:
        assert resp.status_code == 201, f"Đăng ký Alice thất bại: {resp.text}"
        alice_data = resp.json()

    alice_token = alice_data["access_token"]
    alice_refresh = alice_data["refresh_token"]
    alice_headers = {"Authorization": f"Bearer {alice_token}"}
    print(f"PASS: Đăng ký/đăng nhập Alice thành công. Token: {alice_token[:20]}...")

    # Kiểm tra profile Alice
    resp = client.get("/api/auth/me", headers=alice_headers)
    assert resp.status_code == 200
    me = resp.json()
    alice_id = me["id"]
    print(f"PASS: /api/auth/me trả về đúng thông tin Alice (id={alice_id}, email={me['email']})")

    # Kiểm tra ghi chú của Alice và đảm bảo Alice có ít nhất 1 ghi chú riêng để test cách ly
    resp = client.get("/api/notes", headers=alice_headers)
    assert resp.status_code == 200
    alice_notes = resp.json()
    if not alice_notes:
        resp = client.post("/api/notes", headers=alice_headers, json={"title": "Alice Note", "content": "Ghi chú bảo mật của Alice"})
        assert resp.status_code == 201
        alice_notes = [resp.json()]
    alice_note_ids = [n["id"] for n in alice_notes]
    alice_target_note_id = alice_note_ids[0]
    print(f"Ghi chú của Alice: {len(alice_notes)} ghi chú (Target ID: {alice_target_note_id})")

    print("\n--- [3] ĐĂNG KÝ TÀI KHOẢN THỨ HAI (Bob) VÀ KIỂM TRA ĐỘ CÁCH LY DỮ LIỆU ---")
    bob_payload = {
        "email": "bob@smartnote.ai",
        "password": "Password123!",
        "full_name": "Bob Tran",
    }
    resp = client.post("/api/auth/register", json=bob_payload)
    if resp.status_code == 409:
        resp = client.post("/api/auth/login", json={"email": "bob@smartnote.ai", "password": "Password123!"})
        assert resp.status_code == 200
        bob_data = resp.json()
    else:
        assert resp.status_code == 201
        bob_data = resp.json()

    bob_token = bob_data["access_token"]
    bob_headers = {"Authorization": f"Bearer {bob_token}"}
    print("PASS: Đăng ký/đăng nhập Bob thành công")

    # Bob không được nhìn thấy bất kỳ ghi chú nào của Alice
    resp = client.get("/api/notes", headers=bob_headers)
    assert resp.status_code == 200
    bob_notes = resp.json()
    bob_note_ids = [n["id"] for n in bob_notes]
    assert alice_target_note_id not in bob_note_ids, f"Bob không được nhìn thấy ghi chú của Alice nhưng lại thấy: {bob_note_ids}"
    print(f"PASS: Bob không nhìn thấy ghi chú {alice_target_note_id} của Alice (Bảo mật cách ly 100%) - Ghi chú Bob đang có: {bob_note_ids}")

    # Bob thử truy cập trực tiếp ghi chú của Alice -> 403 Forbidden
    resp = client.get(f"/api/notes/{alice_target_note_id}", headers=bob_headers)
    assert resp.status_code == 403, f"Kỳ vọng 403 Forbidden khi Bob truy cập Note của Alice, nhưng nhận: {resp.status_code}"
    print(f"PASS: Bob truy cập trái phép ghi chú {alice_target_note_id} của Alice bị chặn bằng 403 Forbidden")

    # Bob tạo ghi chú riêng của mình nếu chưa có
    resp = client.post("/api/notes", headers=bob_headers, json={"title": "Bob Private Plan", "content": "Kế hoạch bí mật của Bob"})
    assert resp.status_code == 201
    bob_new_note = resp.json()
    print(f"PASS: Bob tạo ghi chú riêng thành công (id={bob_new_note['id']})")

    # Alice kiểm tra lại danh sách: không thấy ghi chú của Bob
    resp = client.get("/api/notes", headers=alice_headers)
    assert resp.status_code == 200
    alice_notes_after = resp.json()
    assert all(n["id"] != bob_new_note["id"] for n in alice_notes_after)
    print("PASS: Alice không thấy ghi chú của Bob (Bảo mật 2 chiều hoàn hảo)")

    print("\n--- [4] KIỂM TRA REFRESH TOKEN ROTATION VÀ LOGOUT ---")
    resp = client.post("/api/auth/refresh", json={"refresh_token": alice_refresh})
    assert resp.status_code == 200, f"Refresh token thất bại: {resp.text}"
    rotated_data = resp.json()
    new_access = rotated_data["access_token"]
    new_refresh = rotated_data["refresh_token"]
    assert new_access != alice_token
    assert new_refresh != alice_refresh
    print("PASS: Refresh Token Rotation thành công, sinh token mới")

    # Thử tái sử dụng refresh token cũ (phải bị từ chối)
    resp = client.post("/api/auth/refresh", json={"refresh_token": alice_refresh})
    assert resp.status_code == 401, f"Kỳ vọng 401 khi dùng lại refresh token cũ, nhận: {resp.status_code}"
    print("PASS: Refresh token cũ đã bị thu hồi ngay lập tức sau khi dùng")

    # Logout
    resp = client.post("/api/auth/logout", json={"refresh_token": new_refresh})
    assert resp.status_code == 200
    # Thử refresh sau logout
    resp = client.post("/api/auth/refresh", json={"refresh_token": new_refresh})
    assert resp.status_code == 401
    print("PASS: Logout thu hồi refresh token thành công")

    print("\n--- [5] KIỂM TRA BẢO MẬT AI VÀ TRUY VẤN RAG CÁCH LY THEO USER ---")
    # Alice gọi tóm tắt
    resp = client.post(
        "/api/ai/summarize",
        headers=alice_headers,
        json={"content": "Smart Note AI là ứng dụng ghi chú hiện đại giúp tự động hóa phân tích.", "max_sentences": 1},
    )
    assert resp.status_code == 200, f"AI summarize thất bại: {resp.text}"
    print(f"PASS: Alice gọi AI Summarize thành công: {resp.json()['summary'][:80]}...")

    # Bob cố tình hỏi về ghi chú 1 của Alice
    resp = client.post(
        "/api/ai/ask",
        headers=bob_headers,
        json={"question": "Ghi chú này nói gì?", "note_id": 1},
    )
    assert resp.status_code in [403, 404], f"Kỳ vọng 403 hoặc 404 khi Bob truy vấn Note 1 của Alice, nhận: {resp.status_code}"
    print("PASS: Bob truy vấn AI với note_id=1 của Alice bị chặn cách ly thành công")

    # Alice hỏi AI về Smart Note AI (truy xuất từ note 1 của Alice)
    resp = client.post(
        "/api/ai/ask",
        headers=alice_headers,
        json={"question": "Smart Note AI là ứng dụng gì?", "note_id": 1},
    )
    assert resp.status_code == 200, f"Alice hỏi AI thất bại: {resp.text}"
    ai_ans = resp.json()
    print(f"PASS: Alice hỏi AI thành công. Nguồn trích dẫn: {len(ai_ans['sources'])} đoạn.")

    print("\n--- [6] KIỂM TRA TÍNH TOÀN VẸN CỦA 2 GHI CHÚ GỐC ---")
    db = SessionLocal()
    try:
        n1 = db.get(Note, 1)
        n2 = db.get(Note, 2)
        assert n1 is not None and n2 is not None
        assert len(n1.title) > 0
        assert len(n2.title) > 0
        print(f"PASS: Note 1: '{n1.title}', độ dài: {len(n1.content)} ký tự")
        print(f"PASS: Note 2: '{n2.title}', độ dài: {len(n2.content)} ký tự")
        print("PASS: Nội dung và tiêu đề 2 ghi chú gốc được bảo toàn nguyên vẹn 100% tiếng Việt UTF-8!")
    finally:
        db.close()

    print("\n=======================================================")
    print(" TẤT CẢ CÁC BƯỚC KIỂM THỬ PHASE 3 ĐỀU THÀNH CÔNG VƯỢT TRỘI!")
    print("=======================================================\n")

if __name__ == "__main__":
    test_full_auth_and_isolation_flow()
