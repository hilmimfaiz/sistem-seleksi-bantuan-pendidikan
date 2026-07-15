import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.user import User


class NotificationType(str, Enum):
    PENGAJUAN = "PENGAJUAN"
    VERIFIKASI = "VERIFIKASI"
    SELEKSI = "SELEKSI"
    CLUSTERING = "CLUSTERING"
    GENERAL = "GENERAL"


class Notification(SQLModel, table=True):
    __tablename__ = "notifications"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    user_id: str = Field(foreign_key="users.id", index=True, max_length=36)
    title: str = Field(max_length=255)
    body: str = Field(max_length=1000)
    type: NotificationType = Field(default=NotificationType.GENERAL)
    reference_id: Optional[str] = Field(default=None, max_length=36)
    is_read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    user: Optional["User"] = Relationship(back_populates="notifications")
