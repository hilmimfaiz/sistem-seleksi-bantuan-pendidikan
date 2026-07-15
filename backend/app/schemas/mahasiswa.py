from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator
from app.models.mahasiswa import JenisKelamin


class MahasiswaCreate(BaseModel):
    nim: str
    nama: str
    program_studi: str
    fakultas: str
    angkatan: int
    jenis_kelamin: JenisKelamin
    alamat: str
    nomor_hp: str

    @field_validator("nim")
    @classmethod
    def nim_format(cls, v):
        if not v or len(v.strip()) < 5:
            raise ValueError("NIM minimal 5 karakter")
        return v.strip()

    @field_validator("angkatan")
    @classmethod
    def angkatan_valid(cls, v):
        if v < 2000 or v > 2030:
            raise ValueError("Angkatan tidak valid")
        return v

    @field_validator("nomor_hp")
    @classmethod
    def nomor_hp_valid(cls, v):
        import re
        if not re.match(r'^(\+62|62|0)[0-9]{9,12}$', v):
            raise ValueError("Format nomor HP tidak valid")
        return v


class MahasiswaUpdate(BaseModel):
    nama: Optional[str] = None
    program_studi: Optional[str] = None
    fakultas: Optional[str] = None
    angkatan: Optional[int] = None
    jenis_kelamin: Optional[JenisKelamin] = None
    alamat: Optional[str] = None
    nomor_hp: Optional[str] = None


class MahasiswaRegisterRequest(MahasiswaCreate):
    email: str
    password: str
    ukt_awal: Optional[float] = None

    @field_validator("password")
    @classmethod
    def password_length(cls, v):
        if len(v) < 6:
            raise ValueError("Password minimal 6 karakter")
        return v

class MahasiswaResponse(BaseModel):
    id: str
    user_id: str
    nim: str
    nama: str
    program_studi: str
    fakultas: str
    angkatan: int
    jenis_kelamin: JenisKelamin
    alamat: str
    nomor_hp: str
    ukt_awal: Optional[float] = None
    ukt_akhir: Optional[float] = None
    foto_profil: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
