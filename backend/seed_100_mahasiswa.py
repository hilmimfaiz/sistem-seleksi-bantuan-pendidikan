import os
import sys
import random

# Add backend directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlmodel import Session, select
from app.database import engine
from app.models.user import User, UserRole
from app.models.mahasiswa import Mahasiswa, JenisKelamin
from app.models.data_finansial import DataFinansial
from app.models.bantuan_pendidikan import BantuanPendidikan, StatusBantuan
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.core.security import hash_password

FIRST_NAMES = ["Budi", "Andi", "Siti", "Ayu", "Dewi", "Rizky", "Putra", "Dian", "Agus", "Eko", "Fajar", "Hendra", "Indra", "Joko", "Rini", "Sari", "Tari", "Yudi", "Zainal", "Ahmad", "Muhammad", "Nur", "Wahyu", "Dimas", "Aditya", "Ilham", "Fikri", "Nisa", "Aulia", "Ratna", "Maya", "Dinda", "Cahya", "Bagus", "Gilang", "Reza", "Surya", "Bayu", "Arif", "Hasan", "Iqbal", "Farhan", "Rian", "Aldo", "Kevin", "Ricky", "Deni", "Doni"]
LAST_NAMES = ["Santoso", "Wijaya", "Pratama", "Saputra", "Kusuma", "Hidayat", "Setiawan", "Nugroho", "Putri", "Lestari", "Sari", "Ramadhan", "Purnama", "Kurniawan", "Wibowo", "Suryono", "Handayani", "Utami", "Maulana", "Syahputra", "Gunawan", "Halim", "Siregar", "Nasution", "Hutagalung", "Simanjuntak", "Marpaung", "Panjaitan", "Panggabean", "Sitompul", "Sihombing", "Nababan", "Sinaga"]

# ─────────────────────────────────────────────────────────────────────────────
# DATA STATIS: 100 mahasiswa yang sudah di-pre-generate dengan seed tetap.
# Dibuat sekali menggunakan random.seed(42) dan di-hardcode di sini.
# Sehingga data SELALU SAMA setiap kali seed dijalankan ulang.
# ─────────────────────────────────────────────────────────────────────────────

def _generate_static_data():
    """Generate 100 deterministic records using a fixed seed. Returns list of dicts."""
    rng = random.Random(42)  # fixed seed — will always produce the same output

    PRODI = ["Teknik Informatika", "Sistem Informasi", "Manajemen", "Akuntansi", "Ilmu Komunikasi"]
    FAKULTAS = ["Fakultas Teknik", "Fakultas Ekonomi", "Fakultas Ilmu Sosial"]
    ANGKATAN = [2020, 2021, 2022, 2023]
    UKT_OPTIONS = [1000000, 1500000, 2000000, 2500000, 3000000, 3500000,
                   4000000, 4500000, 5000000, 5500000, 6000000]

    records = []
    used_nims = set()

    for i in range(1, 101):
        # Generate unique NIM deterministically
        while True:
            nim = f"21{rng.randint(100000, 999999)}"
            if nim not in used_nims:
                used_nims.add(nim)
                break

        nama = f"{rng.choice(FIRST_NAMES)} {rng.choice(LAST_NAMES)}"
        email = f"dummy{i}_{nim}@student.ac.id"
        prodi = rng.choice(PRODI)
        fak = rng.choice(FAKULTAS)
        angkatan = rng.choice(ANGKATAN)
        jk = rng.choice([JenisKelamin.LAKI_LAKI, JenisKelamin.PEREMPUAN])
        alamat = f"Jl. Dummy No. {rng.randint(1, 100)}"
        hp = f"0812{rng.randint(10000000, 99999999)}"
        ukt = rng.choice(UKT_OPTIONS)

        # Finansial category (40% kategori 1, 40% kategori 2, 20% kategori 3)
        kategori = rng.choices([1, 2, 3], weights=[40, 40, 20])[0]

        if kategori == 1:
            pendapatan   = rng.randint(1_000_000, 3_000_000)
            tanggungan   = rng.randint(3, 6)
            pengeluaran  = rng.randint(800_000, 1_500_000)
            uang_saku    = rng.randint(300_000, 600_000)
            literasi     = rng.randint(3, 7)
            gaya_hidup   = rng.randint(1, 5)
        elif kategori == 2:
            pendapatan   = rng.randint(3_000_000, 8_000_000)
            tanggungan   = rng.randint(2, 4)
            pengeluaran  = rng.randint(1_500_000, 3_000_000)
            uang_saku    = rng.randint(600_000, 1_500_000)
            literasi     = rng.randint(5, 8)
            gaya_hidup   = rng.randint(4, 7)
        else:
            pendapatan   = rng.randint(8_000_000, 25_000_000)
            tanggungan   = rng.randint(1, 3)
            pengeluaran  = rng.randint(3_000_000, 8_000_000)
            uang_saku    = rng.randint(1_500_000, 5_000_000)
            literasi     = rng.randint(6, 10)
            gaya_hidup   = rng.randint(6, 10)

        records.append({
            "index": i,
            "nim": nim,
            "nama": nama,
            "email": email,
            "prodi": prodi,
            "fakultas": fak,
            "angkatan": angkatan,
            "jenis_kelamin": jk,
            "alamat": alamat,
            "nomor_hp": hp,
            "ukt_awal": ukt,
            "pendapatan_orang_tua": pendapatan,
            "jumlah_tanggungan": tanggungan,
            "pengeluaran_bulanan": pengeluaran,
            "uang_saku": uang_saku,
            "literasi_keuangan": literasi,
            "gaya_hidup": gaya_hidup,
        })

    return records


# Pre-compute once at module load — always identical regardless of when called
STATIC_RECORDS = _generate_static_data()


def seed_100_mahasiswa():
    with Session(engine) as db:
        # Check if 'Bantuan Penurunan UKT' exists
        bantuan = db.exec(
            select(BantuanPendidikan).where(BantuanPendidikan.nama == "Bantuan Penurunan UKT")
        ).first()

        if not bantuan:
            print("Creating 'Bantuan Penurunan UKT'...")
            bantuan = BantuanPendidikan(
                nama="Bantuan Penurunan UKT",
                deskripsi="Bantuan Penurunan UKT, ada pengurangan biayanya. UKT tertinggi kampus yaitu 8juta.",
                kuota=100,
                jumlah_dana=0,
                persyaratan=(
                    "1. Pendapatan orang tua maksimal Rp7.000.000 per bulan.\n"
                    "2. Memiliki kesulitan membayar UKT.\n"
                    "3. Kondisi ekonomi telah diverifikasi."
                ),
                status=StatusBantuan.AKTIF,
            )
            db.add(bantuan)
            db.flush()

        print("Generating 100 dummy students (deterministic / fixed seed)...")

        for rec in STATIC_RECORDS:
            i = rec["index"]

            # Skip if NIM already exists (idempotent – safe to re-run)
            existing = db.exec(
                select(Mahasiswa).where(Mahasiswa.nim == rec["nim"])
            ).first()
            if existing:
                print(f"  [SKIP] Mahasiswa #{i} NIM {rec['nim']} sudah ada.")
                continue

            # ── User ──────────────────────────────────────────────────────────
            user = User(
                email=rec["email"],
                password_hash=hash_password("Mahasiswa@123"),
                role=UserRole.MAHASISWA,
                is_active=True,
                nama=rec["nama"]
            )
            db.add(user)
            db.flush()

            # ── Mahasiswa ─────────────────────────────────────────────────────
            mhs = Mahasiswa(
                user_id=user.id,
                nim=rec["nim"],
                nama=rec["nama"],
                program_studi=rec["prodi"],
                fakultas=rec["fakultas"],
                angkatan=rec["angkatan"],
                jenis_kelamin=rec["jenis_kelamin"],
                alamat=rec["alamat"],
                nomor_hp=rec["nomor_hp"],
            )
            db.add(mhs)
            db.flush()

            # ── Data Finansial ────────────────────────────────────────────────
            finansial = DataFinansial(
                mahasiswa_id=mhs.id,
                ukt_awal=rec["ukt_awal"],
                pendapatan_orang_tua=rec["pendapatan_orang_tua"],
                jumlah_tanggungan=rec["jumlah_tanggungan"],
                pengeluaran_bulanan=rec["pengeluaran_bulanan"],
                uang_saku=rec["uang_saku"],
                literasi_keuangan=rec["literasi_keuangan"],
                gaya_hidup=rec["gaya_hidup"],
            )
            db.add(finansial)
            db.flush()

            # ── Pengajuan Bantuan (auto-verified) ────────────────────────────
            pengajuan = PengajuanBantuan(
                mahasiswa_id=mhs.id,
                bantuan_id=bantuan.id,
                status=StatusPengajuan.TERVERIFIKASI,
                catatan="Pengajuan otomatis dari dummy generator (Telah Diverifikasi Otomatis)"
            )
            db.add(pengajuan)

        db.commit()
        print("Successfully generated 100 dummy students and 'Penurunan UKT' applications.")
        print("Data is DETERMINISTIC — re-running this script will always produce the same 100 students.")

if __name__ == "__main__":
    seed_100_mahasiswa()
