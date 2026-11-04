"""
Test suite cho AI API Endpoint (/api/ai/ask, /api/ai/summarize) với Mocks:
- Mock ChromaDB retrieval & Ollama chat
- User-specific metadata filter verification
- AI service failure / 503 error handling
- Note authorization check khi ask với note_id
"""
from unittest.mock import AsyncMock, patch
import pytest

def test_ask_ai_with_mock_rag(client, auth_headers_user_a, synthetic_user_a):
    mock_hits = [
        {"note_id": 10, "title": "Ghi chú A", "text": "Nội dung quan trọng về FastAPI"}
    ]
    with patch("app.api.v1.ai.ai_service.retrieve", new_callable=AsyncMock) as mock_retrieve, \
         patch("app.api.v1.ai.ai_service.chat", new_callable=AsyncMock) as mock_chat:
        mock_retrieve.return_value = mock_hits
        mock_chat.return_value = "FastAPI là framework hiệu năng cao."

        payload = {"question": "FastAPI là gì?"}
        response = client.post("/api/ai/ask", json=payload, headers=auth_headers_user_a)
        assert response.status_code == 200
        data = response.json()
        assert data["answer"] == "FastAPI là framework hiệu năng cao."
        assert len(data["sources"]) == 1
        assert data["sources"][0]["title"] == "Ghi chú A"

        # Kiểm chứng RAG retrieve bắt buộc filter theo user_id
        mock_retrieve.assert_called_once_with(
            question="FastAPI là gì?",
            note_id=None,
            user_id=synthetic_user_a.id,
        )

def test_ask_ai_unavailable_service_returns_503(client, auth_headers_user_a):
    with patch("app.api.v1.ai.ai_service.retrieve", side_effect=Exception("Ollama connection refused")):
        payload = {"question": "Câu hỏi test"}
        response = client.post("/api/ai/ask", json=payload, headers=auth_headers_user_a)
        assert response.status_code == 503
        assert "Dịch vụ AI chưa sẵn sàng" in response.json()["detail"]

def test_ask_ai_cross_user_note_denied(client, auth_headers_user_a, auth_headers_user_b):
    # User B tạo 1 note
    create_resp = client.post("/api/notes", json={"title": "Private B", "content": "Secret"}, headers=auth_headers_user_b)
    note_id_b = create_resp.json()["id"]

    # User A cố hỏi AI về note_id của User B -> 404 (do get_note phát hiện cross-user và raise exception)
    response = client.post("/api/ai/ask", json={"question": "Tóm tắt note này", "note_id": note_id_b}, headers=auth_headers_user_a)
    assert response.status_code == 404
    assert "Không tìm thấy ghi chú tham chiếu" in response.json()["detail"]

def test_ai_writing_assist(client, auth_headers_user_a):
    with patch("app.api.v1.ai.ai_service.chat", new_callable=AsyncMock) as mock_chat:
        mock_chat.return_value = "- Ý 1: Nội dung tốt\n- Ý 2: Kế hoạch rõ ràng"
        payload = {
            "content": "Kế hoạch phát triển SmartNoteAI trong tuần tới.",
            "action": "checklist"
        }
        response = client.post("/api/ai/writing-assist", json=payload, headers=auth_headers_user_a)
        assert response.status_code == 200
        data = response.json()
        assert data["action"] == "checklist"
        assert "Ý 1" in data["result"]

