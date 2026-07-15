from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator
from app.models.bantuan_pendidikan import StatusBantuan


class BantuanCreate(BaseModel):
    nama: str
    deskripsi: str
    kuota: int
    jumlah_dana: float
    persyaratan: str
    status: StatusBantuan = StatusBantuan.AKTIF

    @field_validator("kuota")
    @classmethod
    def kuota_valid(cls, v):
        if v < 1:
            raise ValueError("Kuota minimal 1")
        return v

    @field_validator("jumlah_dana")
    @classmethod
    def dana_valid(cls, v):
        if v < 0:
            raise ValueError("Jumlah dana tidak boleh negatif")
        return v


class BantuanUpdate(BaseModel):
    nama: Optional[str] = None
    deskripsi: Optional[str] = None
    kuota: Optional[int] = None
    jumlah_dana: Optional[float] = None
    persyaratan: Optional[str] = None
    status: Optional[StatusBantuan] = None


class BantuanResponse(BaseModel):
    id: str
    nama: str
    deskripsi: str
    kuota: int
    jumlah_dana: float
    persyaratan: str
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
