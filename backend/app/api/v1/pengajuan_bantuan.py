import os
import uuid
import shutil
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, Query, UploadFile, File, Form
from sqlmodel import Session, select, and_
from app.database import get_session
from app.schemas.pengajuan_bantuan import PengajuanCreate, PengajuanResponse
from app.schemas.common import BaseResponse
from app.core.dependencies import get_current_user, require_admin, require_mahasiswa
from app.core.exceptions import (
    NotFoundException, ConflictException, BadRequestException, ForbiddenException
)
from app.config import settings
from app.models.user import User, UserRole
from app.models.mahasiswa import Mahasiswa
from app.models.data_finansial import DataFinansial
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.models.bantuan_pendidikan import BantuanPendidikan, StatusBantuan
from app.services.notification_service import NotificationService
from app.models.notification import NotificationType

router = APIRouter(prefix="/pengajuan", tags=["Pengajuan Bantuan"])

UPLOAD_DIR = settings.UPLOAD_DIR
MAX_SIZE = settings.MAX_FILE_SIZE_MB * 1024 * 1024


def _build_response(p: PengajuanBantuan, db: Session) -> dict:
    """Build response dict dengan relasi."""
    data = {
        "id": p.id,
        "mahasiswa_id": p.mahasiswa_id,
        "bantuan_id": p.bantuan_id,
        "status": p.status,
        "catatan": p.catatan,
        "dokumen_paths": p.dokumen_paths or [],
        "created_at": p.created_at.isoformat(),
        "updated_at": p.updated_at.isoformat(),
        "bantuan_nama": None,
        "mahasiswa_nama": None,
        "mahasiswa_nim": None,
        "ukt_awal": None,
        "ukt_akhir": None,
    }
    if p.bantuan:
        data["bantuan_nama"] = p.bantuan.nama
        data["bantuan_jumlah_dana"] = p.bantuan.jumlah_dana
    if p.mahasiswa:
        data["mahasiswa_nama"] = p.mahasiswa.nama
        data["mahasiswa_nim"] = p.mahasiswa.nim
        from app.models.data_finansial import DataFinansial
        finansial = db.exec(select(DataFinansial).where(DataFinansial.mahasiswa_id == p.mahasiswa_id)).first()
        if finansial:
            data["ukt_awal"] = finansial.ukt_awal
            data["ukt_akhir"] = finansial.ukt_akhir
    return data


@router.get("/me", response_model=BaseResponse)
def get_my_pengajuan(
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Daftar pengajuan bantuan mahasiswa yang sedang login."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        return BaseResponse(success=True, message="Belum ada pengajuan", data=[])

    pengajuan_list = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        ).order_by(PengajuanBantuan.created_at.desc())
    ).all()

    # Load relasi
    result = []
    for p in pengajuan_list:
        _ = p.bantuan
        _ = p.mahasiswa
        result.append(_build_response(p, db))

    return BaseResponse(success=True, message="Berhasil", data=result)


@router.delete("/{pengajuan_id}", response_model=BaseResponse)
def delete_my_pengajuan(
    pengajuan_id: str,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Hapus pengajuan bantuan (soft delete)."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException("Profil mahasiswa tidak ditemukan")

    pengajuan = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.id == pengajuan_id,
                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).first()

    if not pengajuan:
        raise NotFoundException("Pengajuan tidak ditemukan")

    pengajuan.deleted_at = datetime.utcnow()
    db.add(pengajuan)
    db.commit()

    return BaseResponse(success=True, message="Pengajuan berhasil dihapus")


@router.post("", response_model=BaseResponse)
def create_pengajuan(
    body: PengajuanCreate,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Buat pengajuan bantuan baru."""
    # Cek profil mahasiswa
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise BadRequestException(
            "Profil mahasiswa belum lengkap. Lengkapi data mahasiswa terlebih dahulu."
        )

    # Cek data finansial
    finansial = db.exec(
        select(DataFinansial).where(
            and_(
                DataFinansial.mahasiswa_id == mahasiswa.id,
                DataFinansial.deleted_at.is_(None),
            )
        )
    ).first()
    if not finansial:
        raise BadRequestException(
            "Data finansial belum lengkap. Isi data finansial terlebih dahulu."
        )

    # Cek bantuan ada dan aktif
    bantuan = db.exec(
        select(BantuanPendidikan).where(
            and_(
                BantuanPendidikan.id == body.bantuan_id,
                BantuanPendidikan.deleted_at.is_(None),
                BantuanPendidikan.status == StatusBantuan.AKTIF,
            )
        )
    ).first()
    if not bantuan:
        raise NotFoundException("Bantuan tidak ditemukan atau tidak aktif.")

    # Cek belum pernah mengajukan ke bantuan yang sama
    existing = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                PengajuanBantuan.bantuan_id == body.bantuan_id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).first()
    if existing:
        raise ConflictException("Anda sudah pernah mengajukan ke bantuan ini.")

    pengajuan = PengajuanBantuan(
        mahasiswa_id=mahasiswa.id,
        bantuan_id=body.bantuan_id,
        status=StatusPengajuan.MENUNGGU,
    )
    db.add(pengajuan)
    db.commit()
    db.refresh(pengajuan)

    # Load relasi untuk response
    _ = pengajuan.bantuan
    _ = pengajuan.mahasiswa

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Pengajuan Dibuat",
        body=f"Pengajuan bantuan {bantuan.nama} berhasil dibuat. Harap segera lengkapi dokumen persyaratan.",
        notif_type=NotificationType.PENGAJUAN,
        reference_id=pengajuan.id,
    )

    return BaseResponse(
        success=True,
        message="Pengajuan berhasil dibuat. Harap upload dokumen pendukung.",
        data=_build_response(pengajuan, db),
    )


@router.post("/{pengajuan_id}/upload", response_model=BaseResponse)
async def upload_dokumen(
    pengajuan_id: str,
    files: List[UploadFile] = File(...),
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Upload dokumen pengajuan bantuan."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException("Mahasiswa tidak ditemukan")

    pengajuan = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.id == pengajuan_id,
                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).first()
    if not pengajuan:
        raise NotFoundException("Pengajuan tidak ditemukan")

    if pengajuan.status not in [StatusPengajuan.MENUNGGU, StatusPengajuan.REVISI]:
        raise BadRequestException(
            f"Tidak dapat upload dokumen pada status '{pengajuan.status}'."
        )

    # Validasi dan simpan file
    saved_paths = list(pengajuan.dokumen_paths or [])
    upload_folder = os.path.join(UPLOAD_DIR, "pengajuan", pengajuan_id)
    os.makedirs(upload_folder, exist_ok=True)

    for file in files:
        # Validasi extension
        ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
        if ext not in settings.allowed_extensions_list:
            raise BadRequestException(
                f"Tipe file '{ext}' tidak diizinkan. "
                f"Gunakan: {', '.join(settings.allowed_extensions_list)}"
            )

        # Validasi ukuran
        contents = await file.read()
        if len(contents) > MAX_SIZE:
            raise BadRequestException(
                f"Ukuran file '{file.filename}' melebihi {settings.MAX_FILE_SIZE_MB}MB."
            )

        # Simpan dengan nama unik
        unique_name = f"{uuid.uuid4()}_{file.filename}"
        file_path = os.path.join(upload_folder, unique_name)
        with open(file_path, "wb") as f:
            f.write(contents)

        saved_paths.append(file_path)

    pengajuan.dokumen_paths = saved_paths
    pengajuan.updated_at = datetime.utcnow()
    db.add(pengajuan)
    db.commit()
    db.refresh(pengajuan)

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Dokumen Diunggah",
        body=f"{len(files)} dokumen berhasil diunggah. Pengajuan Anda siap diproses.",
        notif_type=NotificationType.PENGAJUAN,
        reference_id=pengajuan.id,
    )

    return BaseResponse(
        success=True,
        message=f"{len(files)} dokumen berhasil diupload",
        data={"dokumen_paths": saved_paths},
    )


# === ADMIN ENDPOINTS ===

@router.get("", response_model=BaseResponse)
def list_all_pengajuan(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=5000),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Daftar semua pengajuan bantuan."""
    query = select(PengajuanBantuan).where(PengajuanBantuan.deleted_at.is_(None))
    if status:
        query = query.where(PengajuanBantuan.status == status)
    query = query.order_by(PengajuanBantuan.created_at.desc())

    all_results = db.exec(query).all()
    total = len(all_results)
    offset = (page - 1) * per_page
    pengajuan_list = db.exec(query.offset(offset).limit(per_page)).all()

    result = []
    for p in pengajuan_list:
        _ = p.bantuan
        _ = p.mahasiswa
        result.append(_build_response(p, db))

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "items": result,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.get("/{pengajuan_id}", response_model=BaseResponse)
def get_pengajuan_detail(
    pengajuan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Detail pengajuan bantuan."""
    query = select(PengajuanBantuan).where(
        and_(
            PengajuanBantuan.id == pengajuan_id,
            PengajuanBantuan.deleted_at.is_(None),
        )
    )
    pengajuan = db.exec(query).first()
    if not pengajuan:
        raise NotFoundException("Pengajuan tidak ditemukan")

    # Mahasiswa hanya bisa lihat pengajuan sendiri
    if current_user.role == UserRole.MAHASISWA:
        mahasiswa = db.exec(
            select(Mahasiswa).where(Mahasiswa.user_id == current_user.id)
        ).first()
        if not mahasiswa or pengajuan.mahasiswa_id != mahasiswa.id:
            raise ForbiddenException("Akses ditolak")

    _ = pengajuan.bantuan
    _ = pengajuan.mahasiswa

    return BaseResponse(
        success=True,
        message="Berhasil",
        data=_build_response(pengajuan, db),
    )
