from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
import json

from ...core.database import get_db
from ...models.user import User
from ...schemas.ingest import IngestTextRequest, IngestUrlRequest, IngestResponse
from ...services.ingest_service import ingest_service
from ..dependencies import get_current_user

router = APIRouter(prefix="/ingest", tags=["Data Ingestion Pipeline"])

@router.post("/text", response_model=IngestResponse)
async def ingest_text(
    payload: IngestTextRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await ingest_service.ingest_text(
        db=db,
        user_id=current_user.id,
        title=payload.title,
        content=payload.content,
        source_type=payload.source_type,
        source_reference=payload.source_reference,
        folder_name=payload.folder,
        tags=payload.tags,
    )
    return IngestResponse(**result)

@router.post("/url", response_model=IngestResponse)
async def ingest_url(
    payload: IngestUrlRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await ingest_service.ingest_url(
        db=db,
        user_id=current_user.id,
        url=payload.url,
        folder_name=payload.folder,
        tags=payload.tags,
    )
    return IngestResponse(**result)

@router.post("/file", response_model=IngestResponse)
async def ingest_file(
    file: UploadFile = File(...),
    folder: str = Form("Tài liệu đính kèm"),
    tags_json: str = Form("[\"file\"]"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Giới hạn kích thước file 10MB
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Kích thước tệp tin vượt quá giới hạn 10MB cho phép.")

    filename = file.filename or "uploaded_file"
    ext = filename.split(".")[-1].lower() if "." in filename else ""

    allowed_exts = {"txt", "md", "json", "csv", "log", "pdf", "docx"}
    if ext not in allowed_exts:
        raise HTTPException(
            status_code=400,
            detail=f"Định dạng tệp .{ext} chưa được hỗ trợ. Vui lòng sử dụng: txt, md, json, csv, pdf, docx."
        )

    text = ""
    if ext == "pdf":
        try:
            import io
            import pypdf
            reader = pypdf.PdfReader(io.BytesIO(contents))
            pages_text = [p.extract_text() or "" for p in reader.pages]
            text = "\n\n".join(pages_text).strip()
            if not text:
                raise HTTPException(status_code=400, detail="Không tìm thấy nội dung văn bản trong tệp PDF này.")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Lỗi đọc nội dung PDF: {e}")
    elif ext == "docx":
        try:
            import io
            import docx
            doc = docx.Document(io.BytesIO(contents))
            paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
            text = "\n\n".join(paragraphs).strip()
            if not text:
                raise HTTPException(status_code=400, detail="Tệp DOCX trống hoặc không chứa văn bản có thể đọc được.")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Lỗi đọc nội dung DOCX: {e}")
    else:
        try:
            text = contents.decode("utf-8")
        except UnicodeDecodeError:
            try:
                text = contents.decode("latin-1")
            except Exception:
                raise HTTPException(status_code=400, detail="Không thể đọc nội dung văn bản của tệp tin này.")

    try:
        tags = json.loads(tags_json)
        if not isinstance(tags, list):
            tags = ["file"]
    except Exception:
        tags = ["file"]

    result = await ingest_service.ingest_text(
        db=db,
        user_id=current_user.id,
        title=filename,
        content=text,
        source_type="file_upload",
        source_reference=filename,
        folder_name=folder,
        tags=tags,
    )
    return IngestResponse(**result)
