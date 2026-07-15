from datetime import datetime
from typing import Optional, List
from sqlmodel import Session, select, and_
from app.models.notification import Notification
from app.models.user import User


class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def create_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        notif_type: str = "GENERAL",
        reference_id: Optional[str] = None,
    ) -> Notification:
        """Buat notifikasi baru untuk user."""
        notification = Notification(
            user_id=user_id,
            title=title,
            body=body,
            type=notif_type,
            reference_id=reference_id,
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)

        # Broadcast via WebSocket
        try:
            from app.ws.connection_manager import manager
            manager.send_personal_message_sync(
                {
                    "id": notification.id,
                    "title": notification.title,
                    "body": notification.body,
                    "type": notification.type,
                    "reference_id": notification.reference_id,
                    "created_at": notification.created_at.isoformat(),
                },
                user_id,
            )
        except Exception:
            pass

        return notification

    def get_user_notifications(
        self,
        user_id: str,
        page: int = 1,
        per_page: int = 20,
        unread_only: bool = False,
    ) -> tuple[List[Notification], int]:
        """Ambil daftar notifikasi user."""
        query = select(Notification).where(Notification.user_id == user_id)
        if unread_only:
            query = query.where(Notification.is_read == False)
        query = query.order_by(Notification.created_at.desc())

        total = len(self.db.exec(query).all())
        offset = (page - 1) * per_page
        notifications = self.db.exec(query.offset(offset).limit(per_page)).all()
        return notifications, total

    def mark_as_read(self, notification_id: str, user_id: str) -> Optional[Notification]:
        """Tandai notifikasi sebagai sudah dibaca."""
        notification = self.db.exec(
            select(Notification).where(
                and_(
                    Notification.id == notification_id,
                    Notification.user_id == user_id,
                )
            )
        ).first()
        if notification:
            notification.is_read = True
            self.db.add(notification)
            self.db.commit()
            self.db.refresh(notification)
        return notification

    def mark_all_as_read(self, user_id: str) -> int:
        """Tandai semua notifikasi sebagai sudah dibaca."""
        notifications = self.db.exec(
            select(Notification).where(
                and_(
                    Notification.user_id == user_id,
                    Notification.is_read == False,
                )
            )
        ).all()
        count = len(notifications)
        for notif in notifications:
            notif.is_read = True
            self.db.add(notif)
        self.db.commit()
        return count

    def get_unread_count(self, user_id: str) -> int:
        """Hitung jumlah notifikasi yang belum dibaca."""
        notifications = self.db.exec(
            select(Notification).where(
                and_(
                    Notification.user_id == user_id,
                    Notification.is_read == False,
                )
            )
        ).all()
        return len(notifications)

    def delete_history(self, user_id: str, cutoff_date: Optional[datetime] = None) -> int:
        """Hapus riwayat notifikasi user."""
        query = select(Notification).where(Notification.user_id == user_id)
        if cutoff_date:
            query = query.where(Notification.created_at >= cutoff_date)
            
        notifications = self.db.exec(query).all()
        count = len(notifications)
        for notif in notifications:
            self.db.delete(notif)
        self.db.commit()
        return count
