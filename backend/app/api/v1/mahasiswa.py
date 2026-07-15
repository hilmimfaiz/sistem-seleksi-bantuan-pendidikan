from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select, and_, func
from app.database import get_session
from app.schemas.mahasiswa import MahasiswaCreate, MahasiswaUpdate, MahasiswaResponse
from app.schemas.common import BaseResponse, PaginatedResponse
from app.core.dependencies import get_current_user, require_admin, require_mahasiswa
from app.core.exceptions import NotFoundException, ConflictException, ForbiddenException, BadRequestException
from app.models.user import User
from app.models.mahasiswa import Mahasiswa
from app.services.notification_service import NotificationService
from app.models.notification import NotificationType

router = APIRouter(prefix="/mahasiswa", tags=["Mahasiswa"])


@router.get("/me", response_model=BaseResponse)
def get_my_profile(
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Ambil profil mahasiswa yang sedang login."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        return BaseResponse(success=True, message="Profil belum lengkap", data=None)
    m_dict = MahasiswaResponse.model_validate(mahasiswa).model_dump(mode="json")
    if mahasiswa.user and mahasiswa.user.foto_profil:
        m_dict["foto_profil"] = mahasiswa.user.foto_profil
    if mahasiswa.data_finansial:
        m_dict["ukt_awal"] = mahasiswa.data_finansial.ukt_awal
        m_dict["ukt_akhir"] = mahasiswa.data_finansial.ukt_akhir

    return BaseResponse(
        success=True,
        message="Berhasil",
        data=m_dict,
    )


@router.post("", response_model=BaseResponse)
def create_profile(
    body: MahasiswaCreate,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Buat profil mahasiswa baru."""
    existing = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if existing:
        raise ConflictException("Profil mahasiswa sudah ada. Gunakan PUT untuk memperbarui.")

    # Cek NIM unik
    nim_exists = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.nim == body.nim, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if nim_exists:
        raise ConflictException(f"NIM {body.nim} sudah terdaftar.")

    mahasiswa = Mahasiswa(
        user_id=current_user.id,
        **body.model_dump(),
    )
    db.add(mahasiswa)
    db.commit()
    db.refresh(mahasiswa)

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Profil Dibuat",
        body="Data profil mahasiswa Anda berhasil dilengkapi.",
        notif_type=NotificationType.GENERAL,
        reference_id=mahasiswa.id,
    )

    return BaseResponse(
        success=True,
        message="Profil mahasiswa berhasil dibuat",
        data=MahasiswaResponse.model_validate(mahasiswa).model_dump(),
    )


@router.put("/me", response_model=BaseResponse)
def update_my_profile(
    body: MahasiswaUpdate,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Update profil mahasiswa."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException("Profil mahasiswa tidak ditemukan. Buat profil terlebih dahulu.")

    update_data = body.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(mahasiswa, key, value)
    mahasiswa.updated_at = datetime.utcnow()

    db.add(mahasiswa)
    db.commit()
    db.refresh(mahasiswa)

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Profil Diperbarui",
        body="Data profil mahasiswa Anda berhasil diperbarui.",
        notif_type=NotificationType.GENERAL,
        reference_id=mahasiswa.id,
    )

    return BaseResponse(
        success=True,
        message="Profil berhasil diperbarui",
        data=MahasiswaResponse.model_validate(mahasiswa).model_dump(),
    )


# === ADMIN ENDPOINTS ===

@router.get("", response_model=BaseResponse)
def list_mahasiswa(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    program_studi: Optional[str] = Query(None),
    angkatan: Optional[int] = Query(None),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Daftar semua mahasiswa dengan pagination dan search."""
    query = select(Mahasiswa).where(Mahasiswa.deleted_at.is_(None))
    if search:
        query = query.where(
            Mahasiswa.nama.contains(search) | Mahasiswa.nim.contains(search)
        )
    if program_studi:
        query = query.where(Mahasiswa.program_studi == program_studi)
    if angkatan:
        query = query.where(Mahasiswa.angkatan == angkatan)
        
    query = query.order_by(Mahasiswa.created_at.desc())

    all_results = db.exec(query).all()
    total = len(all_results)
    offset = (page - 1) * per_page
    mahasiswa_list = db.exec(query.offset(offset).limit(per_page)).all()

    responses = []
    for m in mahasiswa_list:
        m_dict = MahasiswaResponse.model_validate(m).model_dump(mode="json")
        if m.user and m.user.foto_profil:
            m_dict["foto_profil"] = m.user.foto_profil
        if m.data_finansial:
            m_dict["ukt_awal"] = m.data_finansial.ukt_awal
            m_dict["ukt_akhir"] = m.data_finansial.ukt_akhir
        responses.append(m_dict)

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "items": responses,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.get("/filters", response_model=BaseResponse)
def get_mahasiswa_filters(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Mendapatkan daftar unik Program Studi dan Angkatan dari data mahasiswa."""
    programs = db.exec(select(Mahasiswa.program_studi).where(Mahasiswa.deleted_at.is_(None)).distinct()).all()
    angkatans = db.exec(select(Mahasiswa.angkatan).where(Mahasiswa.deleted_at.is_(None)).distinct()).all()

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "program_studi": [p for p in programs if p],
            "angkatan": sorted([a for a in angkatans if a])
        }
    )


@router.get("/{mahasiswa_id}", response_model=BaseResponse)
def get_mahasiswa(
    mahasiswa_id: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Detail mahasiswa berdasarkan ID."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.id == mahasiswa_id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException("Mahasiswa tidak ditemukan")
    m_dict = MahasiswaResponse.model_validate(mahasiswa).model_dump(mode="json")
    if mahasiswa.user and mahasiswa.user.foto_profil:
        m_dict["foto_profil"] = mahasiswa.user.foto_profil
    if mahasiswa.data_finansial:
        m_dict["ukt_awal"] = mahasiswa.data_finansial.ukt_awal
        m_dict["ukt_akhir"] = mahasiswa.data_finansial.ukt_akhir

    return BaseResponse(
        success=True,
        message="Berhasil",
        data=m_dict,
    )


@router.put("/{mahasiswa_id}", response_model=BaseResponse)
def update_mahasiswa_by_admin(
    mahasiswa_id: str,
    body: MahasiswaUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Update data mahasiswa."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.id == mahasiswa_id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException("Mahasiswa tidak ditemukan")

    update_data = body.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(mahasiswa, key, value)
    mahasiswa.updated_at = datetime.utcnow()

    db.add(mahasiswa)
    db.commit()
    db.refresh(mahasiswa)
    return BaseResponse(
        success=True,
        message="Data mahasiswa berhasil diperbarui",
        data=MahasiswaResponse.model_validate(mahasiswa).model_dump(),
    )


@router.delete("/{mahasiswa_id}", response_model=BaseResponse)
def delete_mahasiswa_by_admin(
    mahasiswa_id: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Hapus data mahasiswa (Hard Delete)."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(Mahasiswa.id == mahasiswa_id)
    ).first()
    if not mahasiswa:
        raise NotFoundException("Mahasiswa tidak ditemukan")

    # Hard delete data finansial jika ada
    from app.models.data_finansial import DataFinansial
    data_finansial = db.exec(select(DataFinansial).where(DataFinansial.mahasiswa_id == mahasiswa.id)).first()
    if data_finansial:
        db.delete(data_finansial)

    # Hard delete pengajuan_bantuan & verifikasi_pengajuan
    from app.models.pengajuan_bantuan import PengajuanBantuan
    from app.models.verifikasi_pengajuan import VerifikasiPengajuan
    pengajuan_list = db.exec(select(PengajuanBantuan).where(PengajuanBantuan.mahasiswa_id == mahasiswa.id)).all()
    for p in pengajuan_list:
        verifikasi_list = db.exec(select(VerifikasiPengajuan).where(VerifikasiPengajuan.pengajuan_id == p.id)).all()
        for v in verifikasi_list:
            db.delete(v)
        db.delete(p)

    # Hard delete mahasiswa
    user_id = mahasiswa.user_id
    db.delete(mahasiswa)

    # Hard delete user
    user = db.get(User, user_id)
    if user:
        db.delete(user)

    db.commit()
    return BaseResponse(success=True, message="Data mahasiswa berhasil dihapus")

