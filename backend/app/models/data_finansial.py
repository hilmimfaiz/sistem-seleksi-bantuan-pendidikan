import uuid
from datetime import datetime
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from app.models.mahasiswa import Mahasiswa
    from app.models.hasil_clustering import HasilClustering


class DataFinansial(SQLModel, table=True):
    __tablename__ = "data_finansial"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
        max_length=36,
    )
    mahasiswa_id: str = Field(
        foreign_key="mahasiswa.id", unique=True, index=True, max_length=36
    )
    pendapatan_orang_tua: float = Field(ge=0, description="Pendapatan per bulan dalam rupiah")
    ukt_awal: float = Field(default=0, ge=0, description="Nominal UKT awal mahasiswa")
    ukt_akhir: Optional[float] = Field(default=None, ge=0, description="Nominal UKT setelah penurunan")
    jumlah_tanggungan: int = Field(ge=0, le=20, description="Jumlah anggota keluarga yang ditanggung")
    pengeluaran_bulanan: float = Field(ge=0, description="Total pengeluaran per bulan dalam rupiah")
    uang_saku: float = Field(ge=0, description="Uang saku per bulan dalam rupiah")
    literasi_keuangan: int = Field(ge=1, le=10, description="Skor literasi keuangan 1-10")
    gaya_hidup: int = Field(ge=1, le=10, description="Skor gaya hidup 1-10 (1=sangat hemat, 10=sangat boros)")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = Field(default=None)

    # Relationships
    mahasiswa: Optional["Mahasiswa"] = Relationship(back_populates="data_finansial")
    hasil_clustering: List["HasilClustering"] = Relationship(back_populates="data_finansial")
