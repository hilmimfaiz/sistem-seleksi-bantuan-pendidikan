import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.mahasiswa import Mahasiswa
    from app.models.notification import Notification
    from app.models.activity_log import ActivityLog
    from app.models.hasil_seleksi import HasilSeleksi
    from app.models.verifikasi_pengajuan import VerifikasiPengajuan


class UserRole(str, Enum):
    ADMIN = "ADMIN"
    MAHASISWA = "MAHASISWA"


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    email: str = Field(unique=True, index=True, max_length=255)
    password_hash: str = Field(max_length=255)
    role: UserRole = Field(default=UserRole.MAHASISWA)
    is_active: bool = Field(default=True)
    refresh_token: Optional[str] = Field(default=None, max_length=500)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = Field(default=None)
    foto_profil: Optional[str] = Field(default=None, max_length=500)
    nama: Optional[str] = Field(default="Administrator", max_length=100)

    # Relationships
    mahasiswa: Optional["Mahasiswa"] = Relationship(back_populates="user")
    notifications: List["Notification"] = Relationship(back_populates="user")
    activity_logs: List["ActivityLog"] = Relationship(back_populates="user")
