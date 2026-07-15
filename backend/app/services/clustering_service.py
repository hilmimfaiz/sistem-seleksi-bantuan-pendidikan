import logging
from datetime import datetime
from typing import List, Dict, Any
from sqlmodel import Session, select, and_

from app.models.mahasiswa import Mahasiswa
from app.models.data_finansial import DataFinansial
from app.models.hasil_clustering import HasilClustering, AlgoritmaKlustering, KategoriFinansial
from app.models.evaluasi_model import EvaluasiModel
from app.models.pengajuan_bantuan import PengajuanBantuan, StatusPengajuan
from app.ml.preprocessor import Preprocessor
from app.ml.kmeans_model import KMeansModel
from app.ml.dbscan_model import DBSCANModel
from app.ml.evaluator import ClusterEvaluator
from app.ml.cluster_labeler import ClusterLabeler
from app.core.exceptions import BadRequestException, ServerErrorException

logger = logging.getLogger(__name__)


class ClusteringService:
    def __init__(self, db: Session):
        self.db = db

    def run_clustering(
        self,
        n_clusters: int = 4,
        eps: float = 0.5,
        min_samples: int = 3,
    ) -> Dict[str, Any]:
        """
        Jalankan pipeline clustering lengkap:
        1. Ambil data terverifikasi
        2. Preprocessing + Normalisasi
        3. K-Means
        4. DBSCAN
        5. Evaluasi
        6. Simpan hasil
        """
        # 1. Ambil data finansial dari pengajuan terverifikasi
        verified_pengajuan = self.db.exec(
            select(PengajuanBantuan).where(
                PengajuanBantuan.status == StatusPengajuan.TERVERIFIKASI
            )
        ).all()

        if len(verified_pengajuan) < 3:
            raise BadRequestException(
                f"Data terverifikasi terlalu sedikit ({len(verified_pengajuan)} data). "
                f"Minimal 3 data diperlukan untuk clustering."
            )

        mahasiswa_ids = [p.mahasiswa_id for p in verified_pengajuan]

        data_finansial_list = self.db.exec(
            select(DataFinansial).where(
                and_(
                    DataFinansial.mahasiswa_id.in_(mahasiswa_ids),
                    DataFinansial.deleted_at.is_(None),
                )
            )
        ).all()

        if len(data_finansial_list) < 3:
            raise BadRequestException(
                "Data finansial terverifikasi tidak mencukupi untuk clustering."
            )

        # Hapus hasil clustering lama
        old_results = self.db.exec(select(HasilClustering)).all()
        for r in old_results:
            self.db.delete(r)
        self.db.commit()

        # 2. Preprocessing
        preprocessor = Preprocessor()
        X_raw, ids = preprocessor.extract_features(data_finansial_list)
        X_scaled = preprocessor.fit_transform(X_raw)

        total_data = len(X_scaled)
        feature_names = preprocessor.FEATURES

        # 3. K-Means
        kmeans_result = self._run_kmeans(
            X_scaled=X_scaled,
            ids=ids,
            feature_names=feature_names,
            n_clusters=min(n_clusters, total_data - 1),
        )

        # 4. DBSCAN
        dbscan_result = self._run_dbscan(
            X_scaled=X_scaled,
            ids=ids,
            feature_names=feature_names,
            eps=eps,
            min_samples=min_samples,
        )

        # Update pengajuan status ke SELEKSI
        self._update_pengajuan_status_to_seleksi(mahasiswa_ids)

        return {
            "kmeans": kmeans_result,
            "dbscan": dbscan_result,
            "total_processed": total_data,
        }

    def _run_kmeans(
        self,
        X_scaled,
        ids: List[str],
        feature_names: List[str],
        n_clusters: int,
    ) -> Dict:
        """Jalankan K-Means dan simpan hasil."""
        try:
            model = KMeansModel(n_clusters=n_clusters)
            model.fit(X_scaled)
            labels = model.get_labels()

            sil_score, db_index = ClusterEvaluator.evaluate(X_scaled, labels)
            sample_scores = ClusterEvaluator.silhouette_samples(X_scaled, labels)

            # Label kategori
            labeler = ClusterLabeler()
            category_map = labeler.label_clusters_kmeans(
                model.cluster_centers_, feature_names
            )
            
            # Generate K-Means plot
            try:
                import matplotlib
                matplotlib.use('Agg')
                import matplotlib.pyplot as plt
                from sklearn.decomposition import PCA
                import os
                from app.config import settings
                
                pca = PCA(n_components=2)
                X_pca = pca.fit_transform(X_scaled)
                
                plt.figure(figsize=(10, 6))
                
                import numpy as np
                category_colors = {
                    "SANGAT_MEMBUTUHKAN": "#e74c3c", # Red
                    "MEMBUTUHKAN": "#f1c40f",        # Yellow
                    "CUKUP_MAMPU": "#2ecc71",        # Green
                    "MAMPU": "#3498db"               # Blue
                }
                
                for cluster_id in np.unique(labels):
                    idx = (labels == cluster_id)
                    cat_enum = category_map.get(cluster_id, KategoriFinansial.CUKUP_MAMPU)
                    cat_val = cat_enum.value if hasattr(cat_enum, 'value') else str(cat_enum)
                    color = category_colors.get(cat_val, "#95a5a6")
                    label_name = cat_val.replace("_", " ").title()
                    
                    plt.scatter(
                        X_pca[idx, 0], X_pca[idx, 1], 
                        c=color, 
                        label=f'Cluster {cluster_id}: {label_name}', 
                        alpha=0.7, 
                        s=40
                    )
                    
                plt.title('K-Means Clustering Analysis (PCA Projection)')
                plt.xlabel('Principal Component 1')
                plt.ylabel('Principal Component 2')
                plt.legend(loc='best', title="Kategori")
                plt.grid(True, linestyle='--', alpha=0.7)
                
                os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
                kmeans_plot_path = os.path.join(settings.UPLOAD_DIR, "kmeans_plot.png")
                plt.savefig(kmeans_plot_path, dpi=150, bbox_inches='tight')
                plt.close()
                logger.info(f"K-Means plot saved to {kmeans_plot_path}")
            except Exception as plot_err:
                logger.error(f"Failed to generate K-Means plot: {plot_err}")

            # Simpan evaluasi model
            evaluasi = EvaluasiModel(
                algoritma="KMEANS",
                n_clusters=n_clusters,
                silhouette_score=sil_score,
                davies_bouldin_index=db_index,
                total_data=len(X_scaled),
                total_outlier=0,
                params=f'{{"n_clusters": {n_clusters}}}',
            )
            self.db.add(evaluasi)
            self.db.flush()

            # Simpan hasil per data
            for i, data_finansial_id in enumerate(ids):
                cluster_id = int(labels[i])
                kategori = category_map.get(cluster_id, KategoriFinansial.CUKUP_MAMPU)
                hasil = HasilClustering(
                    data_finansial_id=data_finansial_id,
                    evaluasi_model_id=evaluasi.id,
                    algoritma=AlgoritmaKlustering.KMEANS,
                    cluster_id=cluster_id,
                    kategori=kategori,
                    is_outlier=False,
                    score=float(sample_scores[i]),
                )
                self.db.add(hasil)

            self.db.commit()
            logger.info(f"K-Means selesai: {n_clusters} clusters, silhouette={sil_score:.4f}")

            return {
                "evaluasi_id": evaluasi.id,
                "n_clusters": n_clusters,
                "silhouette_score": sil_score,
                "davies_bouldin_index": db_index,
            }

        except Exception as e:
            self.db.rollback()
            logger.error(f"K-Means error: {str(e)}")
            raise ServerErrorException(f"K-Means clustering gagal: {str(e)}")

    def _run_dbscan(
        self,
        X_scaled,
        ids: List[str],
        feature_names: List[str],
        eps: float,
        min_samples: int,
    ) -> Dict:
        """Jalankan DBSCAN dan simpan hasil."""
        try:
            model = DBSCANModel(eps=eps, min_samples=min_samples)

            # Auto-tune eps jika hasil buruk
            auto_eps = model.auto_tune_eps(X_scaled)
            if auto_eps > 0:
                model.eps = max(eps, auto_eps * 0.8)

            model.fit(X_scaled)
            labels = model.get_labels()
            
            # Generate outlier plot
            try:
                import matplotlib
                matplotlib.use('Agg')
                import matplotlib.pyplot as plt
                from sklearn.decomposition import PCA
                import os
                from app.config import settings
                
                # Gunakan PCA untuk mereduksi dimensi ke 2D
                pca = PCA(n_components=2)
                X_pca = pca.fit_transform(X_scaled)
                
                plt.figure(figsize=(10, 6))
                
                # Plot normal points (not outliers)
                normal_idx = labels != -1
                if any(normal_idx):
                    plt.scatter(X_pca[normal_idx, 0], X_pca[normal_idx, 1], c='blue', alpha=0.5, label='Normal Data', s=30)
                
                # Plot outliers
                outlier_idx = labels == -1
                if any(outlier_idx):
                    plt.scatter(X_pca[outlier_idx, 0], X_pca[outlier_idx, 1], c='red', marker='x', label='Outliers (Noise)', s=50)
                
                plt.title('DBSCAN Outlier Analysis (PCA Projection)')
                plt.xlabel('Principal Component 1')
                plt.ylabel('Principal Component 2')
                plt.legend()
                plt.grid(True, linestyle='--', alpha=0.7)
                
                # Simpan plot
                os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
                plot_path = os.path.join(settings.UPLOAD_DIR, "dbscan_outliers.png")
                plt.savefig(plot_path, dpi=150, bbox_inches='tight')
                plt.close()
                logger.info(f"DBSCAN outlier plot saved to {plot_path}")
            except Exception as plot_err:
                logger.error(f"Failed to generate outlier plot: {plot_err}")

            n_clusters = model.get_cluster_count()
            n_outliers = model.get_outlier_count()

            sil_score, db_index = ClusterEvaluator.evaluate(X_scaled, labels)
            sample_scores = ClusterEvaluator.silhouette_samples(X_scaled, labels)

            # Label kategori
            labeler = ClusterLabeler()
            category_map = labeler.label_dbscan(labels, X_scaled, feature_names)

            # Simpan evaluasi model
            evaluasi = EvaluasiModel(
                algoritma="DBSCAN",
                n_clusters=2,  # Normal Data and Outlier
                silhouette_score=sil_score,
                davies_bouldin_index=db_index,
                total_data=len(X_scaled),
                total_outlier=n_outliers,
                params=f'{{"eps": {model.eps}, "min_samples": {model.min_samples}}}',
            )
            self.db.add(evaluasi)
            self.db.flush()

            # Simpan hasil per data
            for i, data_finansial_id in enumerate(ids):
                cluster_id = int(labels[i])
                is_outlier = cluster_id == -1
                kategori = category_map.get(cluster_id, KategoriFinansial.CUKUP_MAMPU)
                hasil = HasilClustering(
                    data_finansial_id=data_finansial_id,
                    evaluasi_model_id=evaluasi.id,
                    algoritma=AlgoritmaKlustering.DBSCAN,
                    cluster_id=cluster_id,
                    kategori=kategori,
                    is_outlier=is_outlier,
                    score=float(sample_scores[i]) if not is_outlier else None,
                )
                self.db.add(hasil)

            self.db.commit()
            logger.info(
                f"DBSCAN selesai: {n_clusters} clusters, {n_outliers} outliers, "
                f"silhouette={sil_score:.4f}"
            )

            return {
                "evaluasi_id": evaluasi.id,
                "n_clusters": n_clusters,
                "n_outliers": n_outliers,
                "silhouette_score": sil_score,
                "davies_bouldin_index": db_index,
            }

        except Exception as e:
            self.db.rollback()
            logger.error(f"DBSCAN error: {str(e)}")
            raise ServerErrorException(f"DBSCAN clustering gagal: {str(e)}")

    def _update_pengajuan_status_to_seleksi(self, mahasiswa_ids: List[str]) -> None:
        """Update status pengajuan yang terverifikasi ke SELEKSI."""
        pengajuan_list = self.db.exec(
            select(PengajuanBantuan).where(
                and_(
                    PengajuanBantuan.mahasiswa_id.in_(mahasiswa_ids),
                    PengajuanBantuan.status == StatusPengajuan.TERVERIFIKASI,
                )
            )
        ).all()
        for p in pengajuan_list:
            p.status = StatusPengajuan.SELEKSI
            p.updated_at = datetime.utcnow()
            self.db.add(p)
        self.db.commit()

    def get_clustering_results(self) -> Dict:
        """Ambil hasil clustering terbaru."""
        from sqlmodel import select, desc

        # Ambil evaluasi terbaru per algoritma
        kmeans_eval = self.db.exec(
            select(EvaluasiModel)
            .where(EvaluasiModel.algoritma == "KMEANS")
            .order_by(EvaluasiModel.created_at.desc())
        ).first()

        dbscan_eval = self.db.exec(
            select(EvaluasiModel)
            .where(EvaluasiModel.algoritma == "DBSCAN")
            .order_by(EvaluasiModel.created_at.desc())
        ).first()

        results = {
            "kmeans_evaluasi": kmeans_eval,
            "dbscan_evaluasi": dbscan_eval,
            "kmeans_stats": [],
            "dbscan_stats": [],
            "members": [],
            "outliers": [],
        }

        if kmeans_eval:
            kmeans_results = self.db.exec(
                select(HasilClustering).where(
                    HasilClustering.evaluasi_model_id == kmeans_eval.id
                )
            ).all()

            # Statistik per kategori
            stats_map = {}
            for r in kmeans_results:
                kategori = r.kategori
                if kategori not in stats_map:
                    stats_map[kategori] = {
                        "cluster_id": r.cluster_id,
                        "kategori": kategori,
                        "total": 0
                    }
                stats_map[kategori]["total"] += 1

            total = len(kmeans_results)
            for stats in stats_map.values():
                results["kmeans_stats"].append({
                    "cluster_id": stats["cluster_id"],
                    "kategori": stats["kategori"],
                    "total": stats["total"],
                    "percentage": round(stats["total"] / total * 100, 2) if total > 0 else 0,
                })

            # Member info dengan nama mahasiswa
            for r in kmeans_results:
                df = self.db.get(DataFinansial, r.data_finansial_id)
                if df:
                    mahasiswa = self.db.get(Mahasiswa, df.mahasiswa_id)
                    if mahasiswa:
                        pengajuan = self.db.exec(
                            select(PengajuanBantuan).where(
                                PengajuanBantuan.mahasiswa_id == mahasiswa.id,
                            ).order_by(PengajuanBantuan.created_at.desc())
                        ).first()
                        
                        results["members"].append({
                            "data_finansial_id": r.data_finansial_id,
                            "mahasiswa_id": mahasiswa.id,
                            "mahasiswa_nama": mahasiswa.nama,
                            "mahasiswa_nim": mahasiswa.nim,
                            "pengajuan_id": pengajuan.id if pengajuan else None,
                            "kmeans_cluster": r.cluster_id,
                            "kmeans_kategori": r.kategori,
                            "is_outlier": False,
                            "ukt_awal": df.ukt_awal,
                            "pendapatan_orang_tua": df.pendapatan_orang_tua,
                            "jumlah_tanggungan": df.jumlah_tanggungan,
                            "pengeluaran_bulanan": df.pengeluaran_bulanan,
                            "uang_saku": df.uang_saku,
                            "created_at": r.created_at.isoformat() if hasattr(r, 'created_at') else None,
                        })

        if dbscan_eval:
            dbscan_results = self.db.exec(
                select(HasilClustering).where(
                    HasilClustering.evaluasi_model_id == dbscan_eval.id
                )
            ).all()

            stats_map = {
                "Normal Data": {"cluster_id": 1, "kategori": "Normal Data", "total": 0, "is_outlier_group": False},
                "Outlier": {"cluster_id": -1, "kategori": "Outlier", "total": 0, "is_outlier_group": True},
            }
            for r in dbscan_results:
                if r.cluster_id == -1 or r.is_outlier:
                    stats_map["Outlier"]["total"] += 1
                else:
                    stats_map["Normal Data"]["total"] += 1

            total = len(dbscan_results)
            for stats in stats_map.values():
                results["dbscan_stats"].append({
                    "cluster_id": stats["cluster_id"],
                    "kategori": stats["kategori"],
                    "total": stats["total"],
                    "percentage": round(stats["total"] / total * 100, 2) if total > 0 else 0,
                    "is_outlier_group": stats["is_outlier_group"],
                })

            # Get outlier members
            for r in dbscan_results:
                if r.is_outlier or r.cluster_id == -1:
                    df = self.db.get(DataFinansial, r.data_finansial_id)
                    if df:
                        mahasiswa = self.db.get(Mahasiswa, df.mahasiswa_id)
                        if mahasiswa:
                            results["outliers"].append({
                                "data_finansial_id": r.data_finansial_id,
                                "mahasiswa_id": mahasiswa.id,
                                "mahasiswa_nama": mahasiswa.nama,
                                "mahasiswa_nim": mahasiswa.nim,
                            })

        return results

    def get_clustering_history(self) -> List[Dict]:
        """Ambil riwayat eksekusi clustering (semua model evaluasi)."""
        from sqlmodel import select, desc
        
        # Ambil semua EvaluasiModel diurutkan berdasarkan waktu terbaru
        evaluasi_list = self.db.exec(
            select(EvaluasiModel)
            .order_by(EvaluasiModel.created_at.desc())
        ).all()
        
        history = []
        for eval_model in evaluasi_list:
            history.append({
                "id": eval_model.id,
                "algoritma": eval_model.algoritma,
                "n_clusters": eval_model.n_clusters,
                "silhouette_score": eval_model.silhouette_score,
                "davies_bouldin_index": eval_model.davies_bouldin_index,
                "total_data": eval_model.total_data,
                "total_outlier": eval_model.total_outlier,
                "params": eval_model.params,
                "created_at": eval_model.created_at.isoformat() if hasattr(eval_model.created_at, 'isoformat') else eval_model.created_at,
            })
            
        return history
