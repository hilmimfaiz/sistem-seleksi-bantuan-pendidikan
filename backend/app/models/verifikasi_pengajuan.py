import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.pengajuan_bantuan import PengajuanBantuan
    from app.models.user import User


class StatusVerifikasi(str, Enum):
    TERVERIFIKASI = "TERVERIFIKASI"
    DITOLAK = "DITOLAK"
    REVISI = "REVISI"


class VerifikasiPengajuan(SQLModel, table=True):
    __tablename__ = "verifikasi_pengajuan"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    pengajuan_id: str = Field(
        foreign_key="pengajuan_bantuan.id", unique=True, index=True, max_length=36
    )
    admin_id: str = Field(foreign_key="users.id", index=True, max_length=36)
    status: StatusVerifikasi
    catatan: Optional[str] = Field(default=None, max_length=1000)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    pengajuan: Optional["PengajuanBantuan"] = Relationship(back_populates="verifikasi")
