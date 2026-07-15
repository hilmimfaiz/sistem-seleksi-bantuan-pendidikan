from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select, and_
from app.database import get_session
from app.schemas.pengajuan_bantuan import VerifikasiAction
from app.schemas.common import BaseResponse
from app.core.dependencies import require_admin
from app.core.exceptions import NotFoundException, BadRequestException
from app.models.user import User
from app.models.mahasiswa import Mahasiswa
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.models.verifikasi_pengajuan import VerifikasiPengajuan, StatusVerifikasi
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/verifikasi", tags=["Verifikasi Pengajuan"])


def _get_pengajuan(pengajuan_id: str, db: Session) -> PengajuanBantuan:
    """Helper: ambil pengajuan berdasarkan ID."""
    p = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.id == pengajuan_id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).first()
    if not p:
        raise NotFoundException("Pengajuan tidak ditemukan")
    return p


def _send_notif(pengajuan: PengajuanBantuan, title: str, body: str, db: Session):
    """Helper: kirim notifikasi ke mahasiswa."""
    mahasiswa = db.get(Mahasiswa, pengajuan.mahasiswa_id)
    if mahasiswa:
        notif_service = NotificationService(db)
        notif_service.create_notification(
            user_id=mahasiswa.user_id,
            title=title,
            body=body,
            notif_type="VERIFIKASI",
            reference_id=pengajuan.id,
        )


@router.get("", response_model=BaseResponse)
def list_untuk_verifikasi(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=5000),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Daftar pengajuan yang menunggu verifikasi."""
    query = select(PengajuanBantuan).where(
        and_(
            PengajuanBantuan.status == StatusPengajuan.MENUNGGU,
            PengajuanBantuan.deleted_at.is_(None),
        )
    ).order_by(PengajuanBantuan.created_at.asc())

    all_results = db.exec(query).all()
    total = len(all_results)
    offset = (page - 1) * per_page
    pengajuan_list = db.exec(query.offset(offset).limit(per_page)).all()

    result = []
    for p in pengajuan_list:
        mahasiswa = db.get(Mahasiswa, p.mahasiswa_id)
        result.append({
            "id": p.id,
            "mahasiswa_id": p.mahasiswa_id,
            "mahasiswa_nama": mahasiswa.nama if mahasiswa else None,
            "mahasiswa_nim": mahasiswa.nim if mahasiswa else None,
            "bantuan_id": p.bantuan_id,
            "status": p.status,
            "dokumen_paths": p.dokumen_paths or [],
            "created_at": p.created_at.isoformat(),
        })

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


@router.post("/{pengajuan_id}/approve", response_model=BaseResponse)
def approve_pengajuan(
    pengajuan_id: str,
    body: VerifikasiAction,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Verifikasi/Terima pengajuan."""
    pengajuan = _get_pengajuan(pengajuan_id, db)
    if pengajuan.status not in [StatusPengajuan.MENUNGGU, StatusPengajuan.REVISI]:
        raise BadRequestException(f"Pengajuan dengan status '{pengajuan.status}' tidak dapat diverifikasi.")

    # Update status pengajuan
    pengajuan.status = StatusPengajuan.TERVERIFIKASI
    pengajuan.catatan = body.catatan
    pengajuan.updated_at = datetime.utcnow()
    db.add(pengajuan)

    # Simpan record verifikasi
    verifikasi = db.exec(
        select(VerifikasiPengajuan).where(VerifikasiPengajuan.pengajuan_id == pengajuan_id)
    ).first()
    if verifikasi:
        verifikasi.status = StatusVerifikasi.TERVERIFIKASI
        verifikasi.catatan = body.catatan
        verifikasi.admin_id = current_user.id
        verifikasi.updated_at = datetime.utcnow()
    else:
        verifikasi = VerifikasiPengajuan(
            pengajuan_id=pengajuan_id,
            admin_id=current_user.id,
            status=StatusVerifikasi.TERVERIFIKASI,
            catatan=body.catatan,
        )
    db.add(verifikasi)
    db.commit()

    # Kirim notifikasi
    _send_notif(
        pengajuan,
        "Pengajuan Terverifikasi ✓",
        f"Pengajuan Anda telah diverifikasi dan masuk tahap seleksi. "
        f"{body.catatan or ''}",
        db,
    )

    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Verifikasi Selesai",
        body=f"Anda telah memverifikasi pengajuan (ID: {pengajuan.id}).",
        notif_type="VERIFIKASI",
        reference_id=pengajuan.id,
    )

    return BaseResponse(success=True, message="Pengajuan berhasil diverifikasi")


@router.post("/{pengajuan_id}/reject", response_model=BaseResponse)
def reject_pengajuan(
    pengajuan_id: str,
    body: VerifikasiAction,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Tolak pengajuan."""
    pengajuan = _get_pengajuan(pengajuan_id, db)
    if pengajuan.status not in [StatusPengajuan.MENUNGGU, StatusPengajuan.REVISI]:
        raise BadRequestException(f"Pengajuan tidak dapat ditolak pada status '{pengajuan.status}'.")

    pengajuan.status = StatusPengajuan.DITOLAK
    pengajuan.catatan = body.catatan
    pengajuan.updated_at = datetime.utcnow()
    db.add(pengajuan)

    verifikasi = db.exec(
        select(VerifikasiPengajuan).where(VerifikasiPengajuan.pengajuan_id == pengajuan_id)
    ).first()
    if verifikasi:
        verifikasi.status = StatusVerifikasi.DITOLAK
        verifikasi.catatan = body.catatan
        verifikasi.admin_id = current_user.id
        verifikasi.updated_at = datetime.utcnow()
    else:
        verifikasi = VerifikasiPengajuan(
            pengajuan_id=pengajuan_id,
            admin_id=current_user.id,
            status=StatusVerifikasi.DITOLAK,
            catatan=body.catatan,
        )
    db.add(verifikasi)
    db.commit()

    _send_notif(
        pengajuan,
        "Pengajuan Ditolak ✗",
        f"Maaf, pengajuan Anda tidak dapat diproses. {body.catatan or 'Hubungi admin untuk informasi lebih lanjut.'}",
        db,
    )

    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Verifikasi Ditolak",
        body=f"Anda telah menolak pengajuan (ID: {pengajuan.id}).",
        notif_type="VERIFIKASI",
        reference_id=pengajuan.id,
    )

    return BaseResponse(success=True, message="Pengajuan berhasil ditolak")


@router.post("/{pengajuan_id}/revise", response_model=BaseResponse)
def revise_pengajuan(
    pengajuan_id: str,
    body: VerifikasiAction,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Minta revisi dokumen pengajuan."""
    pengajuan = _get_pengajuan(pengajuan_id, db)
    if pengajuan.status not in [StatusPengajuan.MENUNGGU]:
        raise BadRequestException(f"Pengajuan tidak dapat direvisi pada status '{pengajuan.status}'.")

    pengajuan.status = StatusPengajuan.REVISI
    pengajuan.catatan = body.catatan
    pengajuan.updated_at = datetime.utcnow()
    db.add(pengajuan)

    verifikasi = VerifikasiPengajuan(
        pengajuan_id=pengajuan_id,
        admin_id=current_user.id,
        status=StatusVerifikasi.REVISI,
        catatan=body.catatan,
    )
    db.add(verifikasi)
    db.commit()

    _send_notif(
        pengajuan,
        "Perlu Revisi Dokumen",
        f"Pengajuan Anda memerlukan revisi. {body.catatan or 'Silakan upload ulang dokumen yang diperlukan.'}",
        db,
    )

    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Minta Revisi",
        body=f"Anda telah meminta revisi untuk pengajuan (ID: {pengajuan.id}).",
        notif_type="VERIFIKASI",
        reference_id=pengajuan.id,
    )

    return BaseResponse(success=True, message="Permintaan revisi berhasil dikirim")
