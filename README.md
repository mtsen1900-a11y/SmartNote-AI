# Smart Note AI — starter project

Ứng dụng ghi chú + LLM/RAG chạy cục bộ, không dùng Gemini.

## Yêu cầu
- Python 3.11+
- Node.js 20+
- Docker Desktop
- Ollama: https://ollama.com

## 1. Chạy cơ sở dữ liệu
Tại thư mục dự án:
```bash
docker compose up -d
docker compose ps
```

## 2. Chạy LLM và embedding
```bash
ollama pull qwen2.5:3b
ollama pull nomic-embed-text
ollama list
```
Nếu máy có RAM/GPU hạn chế, Qwen 3B thường dễ thử hơn các mô hình lớn. Chất lượng và tốc độ phụ thuộc phần cứng.

## 3. Chạy backend
Làm theo `backend/README.md`. API docs: http://localhost:8000/docs

## 4. Chạy frontend
Mở terminal khác:
```bash
cd frontend
npm install
npm run dev
```
Mở http://localhost:3000

## 5. Thử nghiệm
1. Tạo ghi chú, ví dụ tiêu đề `SVM`, nội dung giải thích siêu phẳng và support vector.
2. Nhấn Lưu ghi chú.
3. Đặt câu hỏi: `Siêu phẳng là gì trong ghi chú?`
4. Kiểm tra câu trả lời và phần nguồn tham chiếu.
5. Sửa ghi chú rồi hỏi lại; thử xóa ghi chú và kiểm tra vector được xóa.

## Lưu ý quan trọng về phạm vi
Đây là **MVP để chạy thử luồng CRUD + LLM/RAG**, chưa phải bản production. Hiện chưa có đăng nhập và phân quyền theo người dùng, upload PDF, thư mục thực sự trong database, lịch sử chat, migrations, streaming, hoặc cơ chế đồng bộ chỉ mục nền. Không mở API ra Internet và không lưu dữ liệu nhạy cảm cho tới khi hoàn thiện bảo mật.
