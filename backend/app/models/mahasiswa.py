import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.data_finansial import DataFinansial
    from app.models.pengajuan_bantuan import PengajuanBantuan


class JenisKelamin(str, Enum):
    LAKI_LAKI = "LAKI_LAKI"
    PEREMPUAN = "PEREMPUAN"


class Mahasiswa(SQLModel, table=True):
    __tablename__ = "mahasiswa"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    user_id: str = Field(foreign_key="users.id", unique=True, index=True, max_length=36)
    nim: str = Field(unique=True, index=True, max_length=20)
    nama: str = Field(max_length=255)
    program_studi: str = Field(max_length=100)
    fakultas: str = Field(max_length=100)
    angkatan: int
    jenis_kelamin: JenisKelamin
    alamat: str = Field(max_length=500)
    nomor_hp: str = Field(max_length=20)
    foto_profil: Optional[str] = Field(default=None, max_length=500)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = Field(default=None)

    # Relationships
    user: Optional["User"] = Relationship(back_populates="mahasiswa")
    data_finansial: Optional["DataFinansial"] = Relationship(back_populates="mahasiswa")
    pengajuan_bantuan: List["PengajuanBantuan"] = Relationship(back_populates="mahasiswa")
