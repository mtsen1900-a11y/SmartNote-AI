from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...schemas.sync import SyncPushRequest, SyncPushResponse, SyncPullResponse
from ...services.sync_service import sync_service
from ..dependencies import get_current_user

router = APIRouter(prefix="/sync", tags=["Sync"])

@router.post("/push", response_model=SyncPushResponse)
def push_sync_events(
    payload: SyncPushRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Nhận batch các sự kiện đồng bộ từ Local Client (CREATE, UPDATE, DELETE).
    Kiểm tra Optimistic Concurrency Control (OCC) và trả về kết quả từng item.
    """
    return sync_service.push_batch(db=db, user_id=current_user.id, request=payload)

@router.get("/pull", response_model=SyncPullResponse)
def pull_sync_events(
    cursor: int = Query(default=0, ge=0, description="Sync Event ID cursor cuối cùng client đã nhận"),
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Lấy danh sách các sự kiện thay đổi mới từ server dựa trên cursor ID (tự động phân trang và bảo đảm thứ tự).
    """
    return sync_service.pull_changes(db=db, user_id=current_user.id, cursor=cursor, limit=limit)
