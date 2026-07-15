from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from sqlmodel import Session
from app.database import get_session
from app.schemas.common import BaseResponse
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.notification_service import NotificationService
from app.ws.connection_manager import manager

router = APIRouter(prefix="/notifications", tags=["Notifikasi"])

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(websocket, user_id)
    try:
        while True:
            # We don't really expect messages from the client, just keep connection open
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)

@router.get("", response_model=BaseResponse)
def get_notifications(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    unread_only: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Daftar notifikasi pengguna."""
    service = NotificationService(db)
    notifications, total = service.get_user_notifications(
        current_user.id, page, per_page, unread_only
    )
    unread_count = service.get_unread_count(current_user.id)

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "items": [
                {
                    "id": n.id,
                    "title": n.title,
                    "body": n.body,
                    "type": n.type,
                    "reference_id": n.reference_id,
                    "is_read": n.is_read,
                    "created_at": n.created_at.isoformat(),
                }
                for n in notifications
            ],
            "total": total,
            "unread_count": unread_count,
            "page": page,
            "per_page": per_page,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.put("/{notification_id}/read", response_model=BaseResponse)
def mark_as_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Tandai notifikasi sebagai sudah dibaca."""
    service = NotificationService(db)
    notification = service.mark_as_read(notification_id, current_user.id)
    if not notification:
        return BaseResponse(success=False, message="Notifikasi tidak ditemukan")
    return BaseResponse(success=True, message="Notifikasi ditandai dibaca")


@router.put("/read-all", response_model=BaseResponse)
def mark_all_as_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Tandai semua notifikasi sebagai sudah dibaca."""
    service = NotificationService(db)
    count = service.mark_all_as_read(current_user.id)
    return BaseResponse(success=True, message=f"{count} notifikasi ditandai dibaca")


@router.delete("", response_model=BaseResponse)
def delete_notifications(
    period: str = Query("all", description="1h, 24h, 7d, 30d, all"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Hapus riwayat notifikasi berdasarkan rentang waktu."""
    from datetime import datetime, timedelta
    
    cutoff_date = None
    now = datetime.utcnow()
    
    if period == "1h":
        cutoff_date = now - timedelta(hours=1)
    elif period == "24h":
        cutoff_date = now - timedelta(hours=24)
    elif period == "7d":
        cutoff_date = now - timedelta(days=7)
    elif period == "30d":
        cutoff_date = now - timedelta(days=30)
    elif period == "all":
        cutoff_date = None
    else:
        return BaseResponse(success=False, message="Period tidak valid")

    service = NotificationService(db)
    count = service.delete_history(current_user.id, cutoff_date)
    return BaseResponse(success=True, message=f"{count} notifikasi berhasil dihapus")
