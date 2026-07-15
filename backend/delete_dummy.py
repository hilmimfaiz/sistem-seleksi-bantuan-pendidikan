import os
import sys

# Add backend directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlmodel import Session, select, delete
from app.database import engine
from app.models.user import User
from app.models.mahasiswa import Mahasiswa
from app.models.data_finansial import DataFinansial
from app.models.bantuan_pendidikan import BantuanPendidikan
from app.models.pengajuan_bantuan import PengajuanBantuan
from app.models.evaluasi_model import EvaluasiModel
from app.models.hasil_clustering import HasilClustering

def delete_dummy_data():
    with Session(engine) as db:
        print("Mencari data dummy mahasiswa...")
        # Temukan semua mahasiswa yang merupakan dummy (dari email: dummy..._21...@student.ac.id)
        dummy_users = db.exec(
            select(User).where(User.email.like("dummy%_21%@student.ac.id"))
        ).all()
        
        if not dummy_users:
            print("Tidak ada data dummy yang ditemukan.")
        else:
            print(f"Menghapus {len(dummy_users)} data dummy mahasiswa beserta relasinya...")
            
            user_ids = [u.id for u in dummy_users]
            
            dummy_mhs = db.exec(
                select(Mahasiswa).where(Mahasiswa.user_id.in_(user_ids))
            ).all()
            
            mhs_ids = [m.id for m in dummy_mhs]
            
            if mhs_ids:
                # Ambil ID DataFinansial untuk dummy mahasiswa ini
                dummy_finansial = db.exec(
                    select(DataFinansial).where(DataFinansial.mahasiswa_id.in_(mhs_ids))
                ).all()
                fin_ids = [f.id for f in dummy_finansial]
                
                # 1. Hapus Hasil Clustering hanya untuk dummy
                if fin_ids:
                    print(f"Menghapus {len(fin_ids)} data hasil clustering dummy...")
                    db.exec(delete(HasilClustering).where(HasilClustering.data_finansial_id.in_(fin_ids)))
            
            if mhs_ids:
                # 3. Hapus Pengajuan
                db.exec(delete(PengajuanBantuan).where(PengajuanBantuan.mahasiswa_id.in_(mhs_ids)))
                
                # 4. Hapus Finansial
                db.exec(delete(DataFinansial).where(DataFinansial.mahasiswa_id.in_(mhs_ids)))
                
                # 5. Hapus Mahasiswa
                db.exec(delete(Mahasiswa).where(Mahasiswa.id.in_(mhs_ids)))
                
            # 6. Hapus User
            if user_ids:
                db.exec(delete(User).where(User.id.in_(user_ids)))
                
        db.commit()
        print("Selesai menghapus data dummy.")

if __name__ == "__main__":
    delete_dummy_data()
