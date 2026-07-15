from datetime import datetime
from fastapi import APIRouter, Depends, Query, Request
from sqlmodel import Session, select, and_
from app.database import get_session
from app.schemas.pengajuan_bantuan import SeleksiRequest
from app.schemas.common import BaseResponse
from app.core.dependencies import get_current_user, require_admin, require_mahasiswa
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException
from app.models.user import User, UserRole
from app.models.mahasiswa import Mahasiswa
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.models.hasil_seleksi import HasilSeleksi, Kelayakan
from app.models.hasil_clustering import HasilClustering, AlgoritmaKlustering
from app.models.data_finansial import DataFinansial
from app.services.notification_service import NotificationService
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/seleksi", tags=["Hasil Seleksi"])

class BulkDeleteRequest(BaseModel):
    ids: List[str]


@router.post("/{pengajuan_id}", response_model=BaseResponse)
def tentukan_kelayakan(
    pengajuan_id: str,
    body: SeleksiRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Tentukan kelayakan mahasiswa berdasarkan hasil clustering."""
    if body.kelayakan not in ["LAYAK", "TIDAK_LAYAK", "DIPERTIMBANGKAN"]:
        raise BadRequestException("Kelayakan harus 'LAYAK', 'TIDAK_LAYAK', atau 'DIPERTIMBANGKAN'")

    pengajuan = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.id == pengajuan_id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).first()
    if not pengajuan:
        raise NotFoundException("Pengajuan tidak ditemukan")

    if pengajuan.status not in [StatusPengajuan.SELEKSI, StatusPengajuan.DIPERTIMBANGKAN]:
        raise BadRequestException(
            f"Pengajuan harus dalam status SELEKSI atau DIPERTIMBANGKAN untuk penentuan kelayakan. "
            f"Status saat ini: {pengajuan.status}"
        )

    if body.kelayakan == "LAYAK":
        kelayakan = Kelayakan.LAYAK
        # Update ukt_akhir in DataFinansial
        if body.ukt_penurunan is not None:
            data_finansial = db.exec(
                select(DataFinansial).where(DataFinansial.mahasiswa_id == pengajuan.mahasiswa_id)
            ).first()
            if data_finansial:
                data_finansial.ukt_akhir = body.ukt_penurunan
                db.add(data_finansial)
    elif body.kelayakan == "TIDAK_LAYAK":
        kelayakan = Kelayakan.TIDAK_LAYAK
    else:
        kelayakan = Kelayakan.DIPERTIMBANGKAN

    # Update atau buat hasil seleksi
    hasil = db.exec(
        select(HasilSeleksi).where(HasilSeleksi.pengajuan_id == pengajuan_id)
    ).first()
    if hasil:
        hasil.kelayakan = kelayakan
        hasil.keterangan = body.keterangan
        hasil.admin_id = current_user.id
        hasil.updated_at = datetime.utcnow()
    else:
        hasil = HasilSeleksi(
            pengajuan_id=pengajuan_id,
            admin_id=current_user.id,
            kelayakan=kelayakan,
            keterangan=body.keterangan,
        )
    db.add(hasil)

    # Update status pengajuan
    if kelayakan == Kelayakan.LAYAK:
        pengajuan.status = StatusPengajuan.DITERIMA
    elif kelayakan == Kelayakan.TIDAK_LAYAK:
        pengajuan.status = StatusPengajuan.TIDAK_DITERIMA
    else:
        pengajuan.status = StatusPengajuan.DIPERTIMBANGKAN
        
    pengajuan.updated_at = datetime.utcnow()
    db.add(pengajuan)
    db.commit()

    # Kirim notifikasi
    mahasiswa = db.get(Mahasiswa, pengajuan.mahasiswa_id)
    if mahasiswa:
        notif_service = NotificationService(db)
        if kelayakan == Kelayakan.LAYAK:
            notif_service.create_notification(
                user_id=mahasiswa.user_id,
                title="🎉 Selamat! Anda Diterima",
                body=f"Anda dinyatakan LAYAK dan diterima sebagai penerima bantuan pendidikan. "
                     f"{body.keterangan or ''}",
                notif_type="SELEKSI",
                reference_id=pengajuan_id,
            )
        elif kelayakan == Kelayakan.TIDAK_LAYAK:
            notif_service.create_notification(
                user_id=mahasiswa.user_id,
                title="Hasil Seleksi - Tidak Diterima",
                body=f"Maaf, Anda belum berhasil dalam seleksi kali ini. "
                     f"{body.keterangan or 'Tetap semangat dan coba lagi pada periode berikutnya.'}",
                notif_type="SELEKSI",
                reference_id=pengajuan_id,
            )
        else:
            notif_service.create_notification(
                user_id=mahasiswa.user_id,
                title="Hasil Seleksi - Dipertimbangkan",
                body=f"Pengajuan Anda saat ini sedang DIPERTIMBANGKAN oleh panitia. "
                     f"{body.keterangan or 'Mohon tunggu informasi lebih lanjut.'}",
                notif_type="SELEKSI",
                reference_id=pengajuan_id,
            )

    # Admin notification
    notif_service.create_notification(
        user_id=current_user.id,
        title="Seleksi Ditetapkan",
        body=f"Anda telah menetapkan kelayakan '{body.kelayakan}' untuk pengajuan (ID: {pengajuan_id}).",
        notif_type="SELEKSI",
        reference_id=pengajuan_id,
    )

    return BaseResponse(
        success=True,
        message=f"Kelayakan berhasil ditetapkan: {body.kelayakan}",
        data={
            "id": hasil.id,
            "pengajuan_id": pengajuan_id,
            "kelayakan": body.kelayakan,
            "keterangan": body.keterangan,
        },
    )


@router.get("/me", response_model=BaseResponse)
def get_my_seleksi(
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Hasil seleksi mahasiswa yang sedang login."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == current_user.id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        return BaseResponse(success=True, message="Belum ada hasil seleksi", data=[])

    pengajuan_list = db.exec(
        select(PengajuanBantuan).where(
            and_(
                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                PengajuanBantuan.deleted_at.is_(None),
            )
        )
    ).all()

    result = []
    for p in pengajuan_list:
        hasil = db.exec(
            select(HasilSeleksi).where(HasilSeleksi.pengajuan_id == p.id)
        ).first()

        # Ambil hasil clustering
        finansial = db.exec(
            select(DataFinansial).where(DataFinansial.mahasiswa_id == mahasiswa.id)
        ).first()
        clustering = None
        if finansial:
            clustering_data = db.exec(
                select(HasilClustering).where(
                    and_(
                        HasilClustering.data_finansial_id == finansial.id,
                        HasilClustering.algoritma == AlgoritmaKlustering.KMEANS,
                    )
                ).order_by(HasilClustering.created_at.desc())
            ).first()
            if clustering_data:
                clustering = {
                    "cluster_id": clustering_data.cluster_id,
                    "kategori": clustering_data.kategori,
                    "is_outlier": clustering_data.is_outlier,
                }

        bantuan = p.bantuan
        result.append({
            "pengajuan_id": p.id,
            "bantuan_nama": bantuan.nama if bantuan else None,
            "status_pengajuan": p.status,
            "kelayakan": hasil.kelayakan if hasil else None,
            "keterangan": hasil.keterangan if hasil else None,
            "hasil_clustering": clustering,
            "created_at": p.created_at.isoformat(),
        })

    return BaseResponse(success=True, message="Berhasil", data=result)


@router.get("", response_model=BaseResponse)
def list_all_seleksi(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Daftar semua hasil seleksi."""
    hasil_list = db.exec(
        select(HasilSeleksi).order_by(HasilSeleksi.created_at.desc())
    ).all()

    total = len(hasil_list)
    offset = (page - 1) * per_page
    hasil_page = hasil_list[offset : offset + per_page]

    result = []
    for h in hasil_page:
        pengajuan = db.get(PengajuanBantuan, h.pengajuan_id)
        mahasiswa = None
        if pengajuan:
            mahasiswa = db.get(Mahasiswa, pengajuan.mahasiswa_id)
        result.append({
            "id": h.id,
            "pengajuan_id": h.pengajuan_id,
            "mahasiswa_nama": mahasiswa.nama if mahasiswa else None,
            "mahasiswa_nim": mahasiswa.nim if mahasiswa else None,
            "kelayakan": h.kelayakan,
            "keterangan": h.keterangan,
            "created_at": h.created_at.isoformat(),
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

@router.delete("/bulk", response_model=BaseResponse)
def bulk_delete_seleksi(
    request: Request,
    body: BulkDeleteRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Hapus beberapa hasil seleksi dan kembalikan status pengajuan ke SELEKSI."""
    from fastapi import Request
    deleted_count = 0
    for hasil_id in body.ids:
        hasil = db.get(HasilSeleksi, hasil_id)
        if hasil:
            pengajuan = db.get(PengajuanBantuan, hasil.pengajuan_id)
            if pengajuan:
                pengajuan.status = StatusPengajuan.SELEKSI
                pengajuan.updated_at = datetime.utcnow()
                db.add(pengajuan)
            db.delete(hasil)
            deleted_count += 1

    db.commit()
    return BaseResponse(
        success=True,
        message=f"{deleted_count} hasil seleksi berhasil dihapus"
    )
