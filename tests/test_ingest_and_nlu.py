import io
from unittest.mock import AsyncMock, patch

def test_ingest_text_success(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.index_note", new_callable=AsyncMock) as mock_index:
        payload = {
            "title": "Tài liệu kiến trúc hệ thống",
            "content": "SmartNoteAI kết hợp Flutter, FastAPI, SQLite Drift và ChromaDB để mang lại hiệu năng cao.",
            "source_type": "direct",
            "folder": "Kiến trúc",
            "tags": ["architecture", "ai"]
        }
        res = client.post("/api/ingest/text", json=payload, headers=auth_headers_user_a)
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "success"
        assert data["title"] == "Tài liệu kiến trúc hệ thống"
        assert data["is_duplicate"] is False
        mock_index.assert_called_once()

def test_ingest_text_deduplication(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.index_note", new_callable=AsyncMock):
        payload = {
            "title": "Bản ghi trùng",
            "content": "Nội dung này được nhập 2 lần để kiểm tra trùng lặp mã băm SHA-256.",
            "source_type": "direct"
        }
        res1 = client.post("/api/ingest/text", json=payload, headers=auth_headers_user_a)
        assert res1.status_code == 200
        assert res1.json()["is_duplicate"] is False

        # Nhập lại nội dung giống hệt
        res2 = client.post("/api/ingest/text", json=payload, headers=auth_headers_user_a)
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["is_duplicate"] is True
        assert "đã tồn tại" in data2["message"]

def test_ingest_url_ssrf_blocked(client, auth_headers_user_a):
    # Cố tình truyền IP nội bộ nguy hiểm -> 400 Bad Request
    payload = {"url": "http://127.0.0.1:8000/admin/secrets"}
    res = client.post("/api/ingest/url", json=payload, headers=auth_headers_user_a)
    assert res.status_code == 400
    assert "SSRF Protection" in res.json()["detail"]

    # Thử localhost
    payload2 = {"url": "http://localhost:5433/sensitive"}
    res2 = client.post("/api/ingest/url", json=payload2, headers=auth_headers_user_a)
    assert res2.status_code == 400

def test_ingest_file_txt(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.index_note", new_callable=AsyncMock):
        file_bytes = b"Day la noi dung tep tin text import vao SmartNoteAI"
        files = {"file": ("document.txt", io.BytesIO(file_bytes), "text/plain")}
        res = client.post("/api/ingest/file", files=files, headers=auth_headers_user_a)
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "success"
        assert data["title"] == "document.txt"
        assert data["source_type"] == "file_upload"

def test_ingest_file_docx(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.index_note", new_callable=AsyncMock):
        import docx
        doc = docx.Document()
        doc.add_paragraph("Noi dung file Word SmartNoteAI testing.")
        doc_io = io.BytesIO()
        doc.save(doc_io)
        doc_io.seek(0)

        files = {"file": ("test_report.docx", doc_io, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        res = client.post("/api/ingest/file", files=files, headers=auth_headers_user_a)
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "success"
        assert data["title"] == "test_report.docx"

def test_nlu_create_note_intent(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.chat", new_callable=AsyncMock) as mock_chat:
        mock_chat.return_value = '{"title": "Kế hoạch sprint mới", "content": "Triển khai Phase 5", "folder": "Công việc", "tags": ["sprint"]}'
        payload = {"query": "Tạo một ghi chú mới về kế hoạch sprint mới của dự án"}
        res = client.post("/api/ai/nlu", json=payload, headers=auth_headers_user_a)
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == "create_note"
        assert data["tool_action"]["requires_confirmation"] is True
        assert data["tool_action"]["name"] == "create_note"

def test_nlu_generate_flashcards(client, auth_headers_user_a):
    with patch("app.services.ai_service.ai_service.chat", new_callable=AsyncMock) as mock_chat:
        mock_chat.return_value = '[{"id": "1", "question": "Flutter là gì?", "answer": "UI toolkit của Google", "hint": "Framework"}]'
        payload = {"query": "Hãy tạo thẻ flashcard ôn tập kiến thức Flutter"}
        res = client.post("/api/ai/nlu", json=payload, headers=auth_headers_user_a)
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == "generate_flashcards"
        assert len(data["result_data"]["flashcards"]) == 1
        assert data["result_data"]["flashcards"][0]["question"] == "Flutter là gì?"
