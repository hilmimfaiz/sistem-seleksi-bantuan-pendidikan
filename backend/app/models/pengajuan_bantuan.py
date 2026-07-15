import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship, Column
from sqlalchemy import JSON

if TYPE_CHECKING:
    from app.models.mahasiswa import Mahasiswa
    from app.models.bantuan_pendidikan import BantuanPendidikan
    from app.models.verifikasi_pengajuan import VerifikasiPengajuan
    from app.models.hasil_seleksi import HasilSeleksi


class StatusPengajuan(str, Enum):
    MENUNGGU = "MENUNGGU"
    REVISI = "REVISI"
    DITOLAK = "DITOLAK"
    TERVERIFIKASI = "TERVERIFIKASI"
    SELEKSI = "SELEKSI"
    DITERIMA = "DITERIMA"
    TIDAK_DITERIMA = "TIDAK_DITERIMA"
    DIPERTIMBANGKAN = "DIPERTIMBANGKAN"


class PengajuanBantuan(SQLModel, table=True):
    __tablename__ = "pengajuan_bantuan"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    mahasiswa_id: str = Field(foreign_key="mahasiswa.id", index=True, max_length=36)
    bantuan_id: str = Field(foreign_key="bantuan_pendidikan.id", index=True, max_length=36)
    status: StatusPengajuan = Field(default=StatusPengajuan.MENUNGGU, index=True)
    catatan: Optional[str] = Field(default=None, max_length=1000)
    dokumen_paths: Optional[List[str]] = Field(default=None, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = Field(default=None)

    # Relationships
    mahasiswa: Optional["Mahasiswa"] = Relationship(back_populates="pengajuan_bantuan")
    bantuan: Optional["BantuanPendidikan"] = Relationship(back_populates="pengajuan")
    verifikasi: Optional["VerifikasiPengajuan"] = Relationship(back_populates="pengajuan")
    hasil_seleksi: Optional["HasilSeleksi"] = Relationship(back_populates="pengajuan")
