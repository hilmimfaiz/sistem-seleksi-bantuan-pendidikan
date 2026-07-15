import sys
import os
import pandas as pd
from sqlmodel import Session, select
import uuid
from datetime import datetime

# Pastikan backend ada di system path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine
from app.models.bantuan_pendidikan import BantuanPendidikan, StatusBantuan
from app.models.user import User
from app.models.mahasiswa import Mahasiswa, JenisKelamin
from app.models.data_finansial import DataFinansial
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan

def import_dummy_data():
    csv_path = "../dummy_data_mahasiswa.csv"
    if not os.path.exists(csv_path):
        print(f"File CSV tidak ditemukan: {csv_path}")
        return

    df = pd.read_csv(csv_path)
    print(f"Mengimpor {len(df)} data ke database...")

    with Session(engine) as session:
        # Create Dummy Bantuan first if not exists
        bantuan = session.exec(select(BantuanPendidikan).limit(1)).first()
        if not bantuan:
            bantuan = BantuanPendidikan(
                id=str(uuid.uuid4()),
                nama="Bantuan Pendidikan Dummy",
                deskripsi="Bantuan dummy untuk pengujian",
                kuota=100,
                jumlah_dana=1000000.0,
                persyaratan="Dummy",
                status=StatusBantuan.AKTIF
            )
            session.add(bantuan)
            session.flush()

        count = 0
        for index, row in df.iterrows():
            nim_str = str(row['nim'])
            mahasiswa = session.exec(select(Mahasiswa).where(Mahasiswa.nim == nim_str)).first()
            
            if not mahasiswa:
                user_id = str(uuid.uuid4())
                user = User(
                    id=user_id,
                    email=f"{nim_str}@dummy.com",
                    password_hash="dummy",
                    role="MAHASISWA"
                )
                session.add(user)
                session.flush()

                mahasiswa = Mahasiswa(
                    id=str(uuid.uuid4()),
                    nama=row['nama'],
                    nim=nim_str,
                    program_studi="Sistem Informasi",
                    fakultas="Ilmu Komputer",
                    angkatan=2021,
                    jenis_kelamin=JenisKelamin.LAKI_LAKI, # Dummy
                    alamat="Jl. Dummy No. 123",
                    nomor_hp="081234567890",
                    user_id=user_id
                )
                session.add(mahasiswa)
                session.flush()

            dfin = session.exec(select(DataFinansial).where(DataFinansial.mahasiswa_id == mahasiswa.id)).first()
            if not dfin:
                dfin = DataFinansial(
                    id=str(uuid.uuid4()),
                    mahasiswa_id=mahasiswa.id,
                    pendapatan_orang_tua=row['pendapatan_orang_tua'],
                    jumlah_tanggungan=row['jumlah_tanggungan'],
                    pengeluaran_bulanan=row['pengeluaran_bulanan'],
                    uang_saku=row['uang_saku'],
                    literasi_keuangan=row['literasi_keuangan'],
                    gaya_hidup=row['gaya_hidup']
                )
                session.add(dfin)
                session.flush()

            pengajuan = session.exec(select(PengajuanBantuan).where(PengajuanBantuan.mahasiswa_id == mahasiswa.id)).first()
            if not pengajuan:
                pengajuan = PengajuanBantuan(
                    id=str(uuid.uuid4()),
                    mahasiswa_id=mahasiswa.id,
                    bantuan_id=bantuan.id,
                    status=StatusPengajuan.TERVERIFIKASI,
                    created_at=datetime.utcnow()
                )
                session.add(pengajuan)
            
            count += 1

        session.commit()
        print(f"Selesai! Berhasil mengimpor {count} data mahasiswa beserta pengajuannya ke dalam database.")
        print("Data siap diproses oleh layanan Clustering dari aplikasi Anda.")

if __name__ == "__main__":
    import_dummy_data()
