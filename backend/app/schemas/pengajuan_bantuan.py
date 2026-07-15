from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
from app.models.pengajuan_bantuan import StatusPengajuan


class PengajuanCreate(BaseModel):
    bantuan_id: str


class PengajuanUpdate(BaseModel):
    catatan: Optional[str] = None


class VerifikasiAction(BaseModel):
    catatan: Optional[str] = None


class SeleksiRequest(BaseModel):
    kelayakan: str  # LAYAK, TIDAK_LAYAK, or DIPERTIMBANGKAN
    keterangan: Optional[str] = None
    ukt_penurunan: Optional[float] = None


class PengajuanResponse(BaseModel):
    id: str
    mahasiswa_id: str
    bantuan_id: str
    status: str
    catatan: Optional[str] = None
    dokumen_paths: Optional[List[str]] = None
    created_at: datetime
    updated_at: datetime
    bantuan_nama: Optional[str] = None
    mahasiswa_nama: Optional[str] = None
    mahasiswa_nim: Optional[str] = None
    ukt_awal: Optional[float] = None
    ukt_akhir: Optional[float] = None

    class Config:
        from_attributes = True
