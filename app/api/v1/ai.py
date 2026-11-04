from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...schemas.ai import (
    AskRequest,
    AskResponse,
    SourceOut,
    SummarizeRequest,
    SummarizeResponse,
    WritingAssistRequest,
    WritingAssistResponse,
    NluRequest,
    NluResponse,
    FlashcardResponse,
)
from ...services.ai_service import ai_service
from ...services.note_service import note_service
from ..dependencies import get_current_user, get_optional_current_user

router = APIRouter(prefix="/ai", tags=["AI"])

@router.post("/ask", response_model=AskResponse)
async def ask_ai(
    payload: AskRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    q_lower = payload.question.lower().strip()
    is_personal = (
        payload.note_id is not None
        or any(kw in q_lower for kw in [
            "ghi chú của tôi", "note của tôi", "kho tri thức", "tài liệu của tôi",
            "dự án của tôi", "tìm ghi chú", "đã lưu", "trong sổ", "tìm trong"
        ])
    )

    # Bảo vệ Chế độ Khách (Guest Security): Không dùng chung user_id = 0, tách biệt hoàn toàn RAG
    if not current_user:
        if is_personal:
            return AskResponse(
                answer="Bạn đang ở Chế độ Khách. Tính năng truy xuất kho ghi chú cá nhân (RAG) chỉ khả dụng khi đăng nhập để đảm bảo quyền riêng tư và cách ly dữ liệu.",
                sources=[],
            )
        # Chat thông thường qua Ollama
        prompt = (
            f"Câu hỏi của người dùng: {payload.question}\n\n"
            "Hãy trả lời câu hỏi trên một cách thông minh, chính xác, lịch sự và dễ hiểu bằng tiếng Việt."
        )
        answer = await ai_service.chat(prompt)
        return AskResponse(answer=answer, sources=[])

    user_id = current_user.id
    if payload.note_id is not None:
        try:
            note_service.get_note(db, payload.note_id, user_id=user_id)
        except Exception:
            raise HTTPException(
                status_code=404,
                detail="Không tìm thấy ghi chú tham chiếu hoặc bạn không có quyền truy cập",
            )

    try:
        hits = await ai_service.retrieve(
            question=payload.question,
            note_id=payload.note_id,
            user_id=user_id,
        )
        if hits:
            context = "\n\n".join(
                f"[Nguồn: ghi chú #{h['note_id']} — {h['title']}]\n{h['text']}" for h in hits
            )
            prompt = (
                f"Dưới đây là các đoạn trích từ ghi chú cá nhân của người dùng:\n{context}\n\n"
                f"Câu hỏi của người dùng: {payload.question}\n\n"
                "HƯỚNG DẪN TRẢ LỜI:\n"
                "1. Hãy trả lời câu hỏi trực tiếp, ngắn gọn và chính xác bằng tiếng Việt dựa trên các thông tin có trong đoạn trích trên.\n"
                "2. Nếu trong đoạn trích ghi chú hoàn toàn không có thông tin để trả lời câu hỏi, hãy nói rõ rằng trong ghi chú chưa có thông tin này, tuyệt đối không tự bịa đặt số liệu hoặc chi tiết sai.\n"
                "3. Nêu tên ghi chú nguồn làm dẫn chứng."
            )
            answer = await ai_service.chat(prompt)
            ans_lower = answer.lower()
            if any(phrase in ans_lower for phrase in [
                "chưa có thông tin", "không có thông tin", "không tìm thấy", "chưa tìm thấy", "hoàn toàn không có"
            ]):
                sources = []
            else:
                sources = [
                    SourceOut(note_id=h["note_id"], title=h["title"], excerpt=h["text"][:240])
                    for h in hits
                ]
            return AskResponse(answer=answer, sources=sources)
        else:
            if is_personal:
                return AskResponse(
                    answer="Chưa tìm thấy ghi chú nào trong kho tri thức cá nhân của bạn phù hợp với câu hỏi.",
                    sources=[],
                )
            else:
                prompt = (
                    f"Câu hỏi của người dùng: {payload.question}\n\n"
                    "Hãy trả lời câu hỏi trên một cách thông minh, chính xác, lịch sự và dễ hiểu bằng tiếng Việt."
                )
                answer = await ai_service.chat(prompt)
                return AskResponse(answer=answer, sources=[])
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Dịch vụ AI chưa sẵn sàng. Kiểm tra Ollama, embedding và ChromaDB. Chi tiết: {exc}",
        )

from pydantic import BaseModel

class ActionRequest(BaseModel):
    action: str = "summarize"
    content: str
    target_tone: str | None = "chuyên nghiệp"

@router.post("/action")
async def ai_action(
    payload: ActionRequest,
    current_user: User | None = Depends(get_optional_current_user),
):
    action = payload.action
    content = payload.content
    target_tone = payload.target_tone or "chuyên nghiệp"

    action_map = {
        "summarize": "Hãy tóm tắt ngắn gọn đoạn văn bản sau thành các ý chính quan trọng nhất:",
        "extract_points": "Hãy trích xuất danh sách các việc cần làm (To-Do list) và các điểm cốt lõi từ nội dung sau:",
        "grammar": "Hãy kiểm tra và sửa toàn bộ lỗi chính tả, ngữ pháp, câu từ trong đoạn văn sau mà không làm mất ý gốc:",
        "explain": "Hãy giải thích rõ ràng, chi tiết, dễ hiểu các khái niệm và nội dung trong văn bản sau:",
        "rewrite": f"Hãy viết lại văn bản sau theo phong cách {target_tone}, mạch lạc, tự nhiên:",
        "quiz": "Hãy tạo 3 câu hỏi trắc nghiệm kèm đáp án và giải thích ngắn dựa trên nội dung sau:",
    }
    instruction = action_map.get(action, f"Hãy phân tích và xử lý nội dung sau theo yêu cầu '{action}':")
    prompt = f"{instruction}\n\n[Nội dung]:\n{content}\n\n[Kết quả bằng tiếng Việt]:"
    result = await ai_service.chat(prompt)
    return {"result": result, "action": action}

@router.post("/summarize", response_model=SummarizeResponse)
async def summarize(
    payload: SummarizeRequest,
    current_user: User | None = Depends(get_optional_current_user),
):
    prompt = (
        f"Hãy tóm tắt ngắn gọn đoạn văn bản sau thành tối đa {payload.max_sentences} ý chính quan trọng nhất:\n\n"
        f"{payload.content}\n\n"
        "Tóm tắt bằng tiếng Việt rõ ràng, giữ nguyên các thông số kỹ thuật nếu có."
    )
    summary = await ai_service.chat(prompt)
    return SummarizeResponse(summary=summary)

@router.post("/writing-assist", response_model=WritingAssistResponse)
async def writing_assist(
    payload: WritingAssistRequest,
    current_user: User | None = Depends(get_optional_current_user),
):
    action_prompts = {
        "improve": "Hãy trau chuốt và cải thiện cách diễn đạt của đoạn văn bản sau, giữ nguyên ý nghĩa cốt lõi, làm cho câu từ chuyên nghiệp, mạch lạc hơn:",
        "fix_spelling": "Hãy sửa toàn bộ lỗi chính tả, ngữ pháp và dấu câu trong đoạn văn bản sau mà không làm thay đổi cấu trúc ý:",
        "expand": "Hãy mở rộng các ý tưởng trong đoạn văn bản sau, bổ sung luận điểm và diễn giải chi tiết, rõ ràng hơn:",
        "shorten": "Hãy rút gọn đoạn văn bản sau, loại bỏ các từ ngữ dư thừa nhưng vẫn giữ đầy đủ các ý chính quan trọng nhất:",
        "checklist": "Hãy chuyển đoạn văn bản hoặc ghi chú sau thành một danh sách công việc kiểm tra (Checklist) với các gạch đầu dòng rõ ràng, có thể hành động được:",
        "action_plan": "Hãy phân tích nội dung sau và chuyển nó thành một Kế hoạch hành động cụ thể (Action Plan) gồm các bước thực hiện, mục tiêu và lưu ý:",
    }
    instruction = action_prompts.get(payload.action, action_prompts["improve"])
    full_prompt = f"{instruction}\n\n[Văn bản gốc]:\n{payload.content}\n\n[Kết quả bằng tiếng Việt]:"
    result = await ai_service.chat(full_prompt)
    return WritingAssistResponse(action=payload.action, result=result)

@router.post("/nlu", response_model=NluResponse)
async def process_natural_language_query(
    payload: NluRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    from ...services.ai_nlu_service import ai_nlu_service
    user_id = current_user.id if current_user else 0
    return await ai_nlu_service.process_natural_query(
        db=db,
        user_id=user_id,
        query=payload.query,
        context_note_id=payload.context_note_id,
    )

@router.post("/flashcards", response_model=FlashcardResponse)
async def generate_flashcards(
    payload: AskRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    from ...services.ai_nlu_service import ai_nlu_service
    user_id = current_user.id if current_user else 0
    cards = await ai_nlu_service.generate_flashcards_from_query(
        db=db,
        user_id=user_id,
        query=payload.question,
        note_id=payload.note_id,
    )
    return FlashcardResponse(note_id=payload.note_id, flashcards=cards)

class IndexNoteRequest(BaseModel):
    note_id: str
    title: str
    content: str

@router.post("/index")
async def index_note_endpoint(
    payload: IndexNoteRequest,
    current_user: User | None = Depends(get_optional_current_user),
):
    if not current_user:
        # Chế độ Khách: Dữ liệu chỉ lưu cục bộ trên trình duyệt Web/Drift SQLite, không index lên máy chủ để tránh rò rỉ dữ liệu giữa các phiên khách
        return {
            "status": "guest_local_only",
            "note_id": payload.note_id,
            "message": "Chế độ Khách lưu trữ dữ liệu cục bộ trên thiết bị, không đồng bộ lên vector database.",
        }
    user_id = current_user.id
    await ai_service.index_note(
        note_id=payload.note_id,
        title=payload.title,
        content=payload.content,
        user_id=user_id,
    )
    return {"status": "ok", "note_id": payload.note_id, "user_id": user_id}
