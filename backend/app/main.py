import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import create_db_and_tables
from app.api.v1 import auth, mahasiswa, data_finansial, bantuan_pendidikan
from app.api.v1 import pengajuan_bantuan, verifikasi, clustering, hasil_seleksi
from app.api.v1 import notifications, admin

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info("🚀 Starting Sistem Finansial Pendidikan API...")
    
    # Create upload directory
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "pengajuan"), exist_ok=True)
    
    # Create database tables
    create_db_and_tables()
    
    # Seed data awal
    await seed_initial_data()
    
    logger.info("✅ Application startup complete")
    yield
    logger.info("🛑 Application shutting down...")


async def seed_initial_data():
    """Seed data awal: admin dan mahasiswa contoh."""
    from sqlmodel import Session, select
    from app.database import engine
    from app.models.user import User, UserRole
    from app.models.mahasiswa import Mahasiswa, JenisKelamin
    from app.models.data_finansial import DataFinansial
    from app.models.bantuan_pendidikan import BantuanPendidikan, StatusBantuan
    from app.core.security import hash_password

    with Session(engine) as db:
        # Cek apakah sudah ada admin
        admin_exists = db.exec(
            select(User).where(User.role == UserRole.ADMIN)
        ).first()
        
        if admin_exists:
            logger.info("Seed data sudah ada, skip.")
            return

        logger.info("Seeding initial data...")

        # Buat admin default
        admin = User(
            email="admin@finansial.ac.id",
            password_hash=hash_password("Admin@123"),
            role=UserRole.ADMIN,
            is_active=True,
        )
        db.add(admin)
        db.flush()

        # Buat bantuan pendidikan
        bantuan_list = [
            BantuanPendidikan(
                nama="Bantuan Penurunan UKT",
                deskripsi="Bantuan Penurunan UKT, ada pengurangan biayanya. UKT tertinggi kampus yaitu 8juta.",
                kuota=100,
                jumlah_dana=0,
                persyaratan="1. Pendapatan orang tua maksimal Rp7.000.000 per bulan.\n2. Memiliki kesulitan membayar UKT.\n3. Kondisi ekonomi telah diverifikasi.",
                status=StatusBantuan.AKTIF,
            ),
            BantuanPendidikan(
                nama="Bantuan Pendidikan Ekonomi",
                deskripsi="Bantuan biaya hidup sebesar Rp500.000 per bulan. Diberikan selama 1 semester (6 bulan). Total bantuan Rp3.000.000.",
                kuota=50,
                jumlah_dana=3000000,
                persyaratan="1. Pendapatan orang tua maksimal Rp5.000.000 per bulan.\n2. Jumlah tanggungan keluarga minimal 2 orang.\n3. Memiliki keterbatasan ekonomi berdasarkan hasil verifikasi.",
                status=StatusBantuan.AKTIF,
            ),
        ]
        for b in bantuan_list:
            db.add(b)
        db.flush()

        # Buat 10 akun mahasiswa contoh
        mahasiswa_data = [
            {
                "email": "mhs001@student.ac.id",
                "nim": "2021001",
                "nama": "Ahmad Fauzi",
                "program_studi": "Teknik Informatika",
                "fakultas": "Fakultas Teknik",
                "angkatan": 2021,
                "jenis_kelamin": JenisKelamin.LAKI_LAKI,
                "alamat": "Jl. Merdeka No.1, Jakarta",
                "nomor_hp": "081234567001",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 2000000,
                    "jumlah_tanggungan": 4,
                    "pengeluaran_bulanan": 1500000,
                    "uang_saku": 500000,
                    "literasi_keuangan": 6,
                    "gaya_hidup": 3,
                },
            },
            {
                "email": "mhs002@student.ac.id",
                "nim": "2021002",
                "nama": "Budi Santoso",
                "program_studi": "Manajemen",
                "fakultas": "Fakultas Ekonomi",
                "angkatan": 2021,
                "jenis_kelamin": JenisKelamin.LAKI_LAKI,
                "alamat": "Jl. Sudirman No.5, Bandung",
                "nomor_hp": "081234567002",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 8000000,
                    "jumlah_tanggungan": 2,
                    "pengeluaran_bulanan": 3000000,
                    "uang_saku": 2000000,
                    "literasi_keuangan": 8,
                    "gaya_hidup": 7,
                },
            },
            {
                "email": "mhs003@student.ac.id",
                "nim": "2021003",
                "nama": "Citra Dewi",
                "program_studi": "Akuntansi",
                "fakultas": "Fakultas Ekonomi",
                "angkatan": 2021,
                "jenis_kelamin": JenisKelamin.PEREMPUAN,
                "alamat": "Jl. Pahlawan No.10, Surabaya",
                "nomor_hp": "081234567003",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 1500000,
                    "jumlah_tanggungan": 5,
                    "pengeluaran_bulanan": 1200000,
                    "uang_saku": 400000,
                    "literasi_keuangan": 5,
                    "gaya_hidup": 2,
                },
            },
            {
                "email": "mhs004@student.ac.id",
                "nim": "2021004",
                "nama": "Dian Purnama",
                "program_studi": "Pendidikan Matematika",
                "fakultas": "Fakultas Keguruan",
                "angkatan": 2022,
                "jenis_kelamin": JenisKelamin.PEREMPUAN,
                "alamat": "Jl. Gadjah Mada No.15, Yogyakarta",
                "nomor_hp": "081234567004",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 4000000,
                    "jumlah_tanggungan": 3,
                    "pengeluaran_bulanan": 2000000,
                    "uang_saku": 800000,
                    "literasi_keuangan": 7,
                    "gaya_hidup": 5,
                },
            },
            {
                "email": "mhs005@student.ac.id",
                "nim": "2021005",
                "nama": "Eko Prasetyo",
                "program_studi": "Teknik Elektro",
                "fakultas": "Fakultas Teknik",
                "angkatan": 2020,
                "jenis_kelamin": JenisKelamin.LAKI_LAKI,
                "alamat": "Jl. Diponegoro No.20, Semarang",
                "nomor_hp": "081234567005",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 1000000,
                    "jumlah_tanggungan": 6,
                    "pengeluaran_bulanan": 900000,
                    "uang_saku": 300000,
                    "literasi_keuangan": 4,
                    "gaya_hidup": 2,
                },
            },
            {
                "email": "mhs006@student.ac.id",
                "nim": "2021006",
                "nama": "Fitri Handayani",
                "program_studi": "Psikologi",
                "fakultas": "Fakultas Psikologi",
                "angkatan": 2022,
                "jenis_kelamin": JenisKelamin.PEREMPUAN,
                "alamat": "Jl. Ahmad Yani No.25, Malang",
                "nomor_hp": "081234567006",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 12000000,
                    "jumlah_tanggungan": 2,
                    "pengeluaran_bulanan": 5000000,
                    "uang_saku": 3000000,
                    "literasi_keuangan": 9,
                    "gaya_hidup": 8,
                },
            },
            {
                "email": "mhs007@student.ac.id",
                "nim": "2021007",
                "nama": "Gunawan Setiadi",
                "program_studi": "Kedokteran",
                "fakultas": "Fakultas Kedokteran",
                "angkatan": 2020,
                "jenis_kelamin": JenisKelamin.LAKI_LAKI,
                "alamat": "Jl. Veteran No.30, Medan",
                "nomor_hp": "081234567007",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 3000000,
                    "jumlah_tanggungan": 4,
                    "pengeluaran_bulanan": 2500000,
                    "uang_saku": 700000,
                    "literasi_keuangan": 6,
                    "gaya_hidup": 4,
                },
            },
            {
                "email": "mhs008@student.ac.id",
                "nim": "2021008",
                "nama": "Hana Pertiwi",
                "program_studi": "Hukum",
                "fakultas": "Fakultas Hukum",
                "angkatan": 2021,
                "jenis_kelamin": JenisKelamin.PEREMPUAN,
                "alamat": "Jl. Imam Bonjol No.35, Padang",
                "nomor_hp": "081234567008",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 1800000,
                    "jumlah_tanggungan": 5,
                    "pengeluaran_bulanan": 1400000,
                    "uang_saku": 450000,
                    "literasi_keuangan": 5,
                    "gaya_hidup": 3,
                },
            },
            {
                "email": "mhs009@student.ac.id",
                "nim": "2021009",
                "nama": "Indra Kurniawan",
                "program_studi": "Arsitektur",
                "fakultas": "Fakultas Teknik",
                "angkatan": 2022,
                "jenis_kelamin": JenisKelamin.LAKI_LAKI,
                "alamat": "Jl. Raya Bogor No.40, Bogor",
                "nomor_hp": "081234567009",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 6000000,
                    "jumlah_tanggungan": 3,
                    "pengeluaran_bulanan": 2800000,
                    "uang_saku": 1500000,
                    "literasi_keuangan": 8,
                    "gaya_hidup": 6,
                },
            },
            {
                "email": "mhs010@student.ac.id",
                "nim": "2021010",
                "nama": "Juwita Rahma",
                "program_studi": "Farmasi",
                "fakultas": "Fakultas Farmasi",
                "angkatan": 2021,
                "jenis_kelamin": JenisKelamin.PEREMPUAN,
                "alamat": "Jl. Sisingamangaraja No.45, Makassar",
                "nomor_hp": "081234567010",
                "finansial": {
                    "ukt_awal": 4000000, "pendapatan_orang_tua": 900000,
                    "jumlah_tanggungan": 7,
                    "pengeluaran_bulanan": 800000,
                    "uang_saku": 250000,
                    "literasi_keuangan": 3,
                    "gaya_hidup": 2,
                },
            },
        ]

        for mhs_data in mahasiswa_data:
            # Buat user
            user = User(
                email=mhs_data["email"],
                password_hash=hash_password("Mahasiswa@123"),
                role=UserRole.MAHASISWA,
                is_active=True,
            )
            db.add(user)
            db.flush()

            # Buat mahasiswa
            mhs = Mahasiswa(
                user_id=user.id,
                nim=mhs_data["nim"],
                nama=mhs_data["nama"],
                program_studi=mhs_data["program_studi"],
                fakultas=mhs_data["fakultas"],
                angkatan=mhs_data["angkatan"],
                jenis_kelamin=mhs_data["jenis_kelamin"],
                alamat=mhs_data["alamat"],
                nomor_hp=mhs_data["nomor_hp"],
            )
            db.add(mhs)
            db.flush()

            # Buat data finansial
            fin_data = mhs_data["finansial"]
            finansial = DataFinansial(
                mahasiswa_id=mhs.id,
                **fin_data,
            )
            db.add(finansial)

        db.commit()
        logger.info("✅ Seed data berhasil dibuat!")
        logger.info("   Admin: admin@finansial.ac.id / Admin@123")
        logger.info("   Mahasiswa: mhs001@student.ac.id / Mahasiswa@123")


# Inisialisasi FastAPI
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API untuk Sistem Pengelompokan Kemampuan Finansial Mahasiswa",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, use settings.allowed_origins_list
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Static files untuk uploads
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

@app.get("/")
def root():
    return {"message": f"{settings.APP_NAME} v{settings.APP_VERSION}", "status": "running"}


@app.get("/health")
def health():
    return {"status": "healthy", "version": settings.APP_VERSION}


# Register all routers
API_PREFIX = "/api/v1"
app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(mahasiswa.router, prefix=API_PREFIX)
app.include_router(data_finansial.router, prefix=API_PREFIX)
app.include_router(bantuan_pendidikan.router, prefix=API_PREFIX)
app.include_router(pengajuan_bantuan.router, prefix=API_PREFIX)
app.include_router(verifikasi.router, prefix=API_PREFIX)
app.include_router(clustering.router, prefix=API_PREFIX)
app.include_router(hasil_seleksi.router, prefix=API_PREFIX)
app.include_router(notifications.router, prefix=API_PREFIX)
app.include_router(admin.router, prefix=API_PREFIX)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import logging, traceback
    with open("fatal_error.log", "a") as f:
        f.write(f"Error handling request {request.url}\n")
        traceback.print_exc(file=f)
    logging.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "Terjadi kesalahan pada server. Coba lagi nanti.",
            "detail": str(exc) if settings.DEBUG else None,
        },
    )
