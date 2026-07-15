from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator


class DataFinansialCreate(BaseModel):
    pendapatan_orang_tua: float
    ukt_awal: float = 0
    jumlah_tanggungan: int
    pengeluaran_bulanan: float
    uang_saku: float
    literasi_keuangan: int
    gaya_hidup: int

    @field_validator("pendapatan_orang_tua", "pengeluaran_bulanan", "uang_saku")
    @classmethod
    def must_be_positive(cls, v):
        if v < 0:
            raise ValueError("Nilai tidak boleh negatif")
        return v

    @field_validator("jumlah_tanggungan")
    @classmethod
    def tanggungan_valid(cls, v):
        if v < 0 or v > 20:
            raise ValueError("Jumlah tanggungan harus antara 0-20")
        return v

    @field_validator("literasi_keuangan", "gaya_hidup")
    @classmethod
    def score_valid(cls, v):
        if v < 1 or v > 10:
            raise ValueError("Skor harus antara 1-10")
        return v


class DataFinansialUpdate(BaseModel):
    pendapatan_orang_tua: Optional[float] = None
    ukt_awal: Optional[float] = None
    jumlah_tanggungan: Optional[int] = None
    pengeluaran_bulanan: Optional[float] = None
    uang_saku: Optional[float] = None
    literasi_keuangan: Optional[int] = None
    gaya_hidup: Optional[int] = None


class DataFinansialResponse(BaseModel):
    id: str
    mahasiswa_id: str
    pendapatan_orang_tua: float
    ukt_awal: float
    ukt_akhir: Optional[float] = None
    jumlah_tanggungan: int
    pengeluaran_bulanan: float
    uang_saku: float
    literasi_keuangan: int
    gaya_hidup: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
