import io
import csv
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlmodel import Session, select, func, and_
from app.database import get_session
from app.schemas.common import BaseResponse
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.mahasiswa import Mahasiswa
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.models.hasil_seleksi import HasilSeleksi, Kelayakan
from app.models.hasil_clustering import HasilClustering, AlgoritmaKlustering
from app.models.evaluasi_model import EvaluasiModel
from app.schemas.mahasiswa import MahasiswaRegisterRequest
from app.core.security import hash_password
from app.core.exceptions import ConflictException
from app.models.data_finansial import DataFinansial

router = APIRouter(prefix="/admin", tags=["Admin Dashboard"])

@router.post("/mahasiswa", response_model=BaseResponse)
def register_mahasiswa(
    body: MahasiswaRegisterRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Mendaftarkan akun User baru (role: MAHASISWA) sekaligus profil Mahasiswanya."""
    # Cek duplikasi email
    if db.exec(select(User).where(User.email == body.email)).first():
        raise ConflictException(f"Email {body.email} sudah terdaftar.")

    # Cek duplikasi NIM
    if db.exec(select(Mahasiswa).where(Mahasiswa.nim == body.nim)).first():
        raise ConflictException(f"NIM {body.nim} sudah terdaftar.")

    # 1. Buat User
    new_user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        role="MAHASISWA"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 2. Buat Profil Mahasiswa
    new_mahasiswa = Mahasiswa(
        user_id=new_user.id,
        nim=body.nim,
        nama=body.nama,
        program_studi=body.program_studi,
        fakultas=body.fakultas,
        angkatan=body.angkatan,
        jenis_kelamin=body.jenis_kelamin,
        alamat=body.alamat,
        nomor_hp=body.nomor_hp,
    )
    db.add(new_mahasiswa)
    db.commit()
    db.refresh(new_mahasiswa)

    # 3. Create initial DataFinansial if ukt_awal is provided
    if body.ukt_awal is not None:
        initial_finansial = DataFinansial(
            mahasiswa_id=new_mahasiswa.id,
            pendapatan_orang_tua=0,
            ukt_awal=body.ukt_awal,
            jumlah_tanggungan=0,
            pengeluaran_bulanan=0,
            uang_saku=0,
            literasi_keuangan=5,
            gaya_hidup=5
        )
        db.add(initial_finansial)
        db.commit()
    
    return BaseResponse(
        success=True,
        message="Akun Mahasiswa berhasil dibuat",
        data={"user_id": new_user.id, "email": new_user.email}
    )


@router.get("/stats", response_model=BaseResponse)
def get_admin_stats(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Statistik utama untuk dashboard admin."""
    # Total mahasiswa terdaftar
    total_mahasiswa = len(db.exec(
        select(Mahasiswa).where(Mahasiswa.deleted_at.is_(None))
    ).all())

    # Total pengajuan dengan filter tanggal
    query = select(PengajuanBantuan, Mahasiswa).join(Mahasiswa).where(PengajuanBantuan.deleted_at.is_(None))
    
    if start_date:
        try:
            sd = datetime.strptime(start_date, "%Y-%m-%d")
            query = query.where(PengajuanBantuan.created_at >= sd)
        except ValueError:
            pass
    if end_date:
        try:
            # End of day
            ed = datetime.strptime(end_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.where(PengajuanBantuan.created_at <= ed)
        except ValueError:
            pass
            
    pengajuan_all = db.exec(query).all()
    total_pengajuan = len(pengajuan_all)

    # Breakdown per status and student details
    status_count = {}
    status_students = {}
    for p, m in pengajuan_all:
        s = p.status.value if hasattr(p.status, "value") else str(p.status)
        status_count[s] = status_count.get(s, 0) + 1
        
        if s not in status_students:
            status_students[s] = []
        status_students[s].append({
            "id": m.id,
            "nama": m.nama,
            "nim": m.nim,
            "pengajuan_id": p.id
        })

    # Total terverifikasi, ditolak, direvisi
    total_terverifikasi = status_count.get("TERVERIFIKASI", 0) + status_count.get("DITERIMA", 0)
    total_ditolak = status_count.get("DITOLAK", 0) + status_count.get("TIDAK_DITERIMA", 0)
    total_menunggu = status_count.get("MENUNGGU", 0)
    total_direvisi = status_count.get("REVISI", 0)

    # Statistik cluster terbaru
    latest_kmeans = db.exec(
        select(EvaluasiModel)
        .where(EvaluasiModel.algoritma == "KMEANS")
        .order_by(EvaluasiModel.created_at.desc())
    ).first()

    cluster_stats = {}
    if latest_kmeans:
        members = db.exec(
            select(HasilClustering).where(
                HasilClustering.evaluasi_model_id == latest_kmeans.id
            )
        ).all()
        for m in members:
            k = m.kategori.value if hasattr(m.kategori, "value") else str(m.kategori)
            cluster_stats[k] = cluster_stats.get(k, 0) + 1

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "total_mahasiswa": total_mahasiswa,
            "total_pengajuan": total_pengajuan,
            "total_terverifikasi": total_terverifikasi,
            "total_ditolak": total_ditolak,
            "total_menunggu": total_menunggu,
            "total_direvisi": total_direvisi,
            "status_breakdown": status_count,
            "status_students": status_students,
            "cluster_stats": cluster_stats,
            "kmeans_score": {
                "silhouette": latest_kmeans.silhouette_score if latest_kmeans else None,
                "davies_bouldin": latest_kmeans.davies_bouldin_index if latest_kmeans else None,
            } if latest_kmeans else None,
        },
    )

@router.get("/stats/download")
def download_admin_stats(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_session),
):
    """[Admin] Download laporan statistik berupa CSV."""
    # Data pengajuan
    query = select(PengajuanBantuan, Mahasiswa).join(Mahasiswa).where(PengajuanBantuan.deleted_at.is_(None))
    
    if start_date:
        try:
            sd = datetime.strptime(start_date, "%Y-%m-%d")
            query = query.where(PengajuanBantuan.created_at >= sd)
        except ValueError:
            pass
    if end_date:
        try:
            ed = datetime.strptime(end_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.where(PengajuanBantuan.created_at <= ed)
        except ValueError:
            pass
            
    pengajuan_all = db.exec(query).all()
    
    # Create CSV
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Header
    writer.writerow(["ID Pengajuan", "NIM", "Nama Mahasiswa", "Status", "Tanggal Pengajuan"])
    
    for p, m in pengajuan_all:
        status_val = p.status.value if hasattr(p.status, "value") else str(p.status)
        tgl = p.created_at.strftime("%Y-%m-%d %H:%M:%S") if p.created_at else ""
        writer.writerow([p.id, m.nim, m.nama, status_val, tgl])
        
    output.seek(0)
    
    filename = f"Laporan_Pengajuan_{datetime.now().strftime('%Y%m%d')}.csv"
    
    return StreamingResponse(
        output,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
