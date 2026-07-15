import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.pengajuan_bantuan import PengajuanBantuan


class StatusBantuan(str, Enum):
    AKTIF = "AKTIF"
    TIDAK_AKTIF = "TIDAK_AKTIF"


class BantuanPendidikan(SQLModel, table=True):
    __tablename__ = "bantuan_pendidikan"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    nama: str = Field(max_length=255, index=True)
    deskripsi: str = Field(max_length=2000)
    kuota: int = Field(ge=1, description="Jumlah penerima yang diterima")
    jumlah_dana: float = Field(ge=0, description="Jumlah dana bantuan dalam rupiah")
    persyaratan: str = Field(max_length=2000)
    status: StatusBantuan = Field(default=StatusBantuan.AKTIF)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = Field(default=None)

    # Relationships
    pengajuan: List["PengajuanBantuan"] = Relationship(back_populates="bantuan")
