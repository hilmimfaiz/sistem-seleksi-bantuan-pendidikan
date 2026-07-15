import numpy as np
from typing import List, Dict
from app.models.hasil_clustering import KategoriFinansial


class ClusterLabeler:
    """
    Labeler untuk menentukan kategori finansial berdasarkan cluster.
    
    Kategori:
    - SANGAT_MEMBUTUHKAN: Pendapatan rendah, tanggungan banyak, pengeluaran tinggi
    - MEMBUTUHKAN: Pendapatan menengah-bawah, butuh bantuan
    - CUKUP_MAMPU: Pendapatan menengah, cukup mandiri
    - MAMPU: Pendapatan tinggi, mandiri secara finansial
    - OUTLIER: Data anomali (khusus DBSCAN)
    """

    @staticmethod
    def label_clusters_kmeans(
        cluster_centers: np.ndarray,
        feature_names: List[str],
    ) -> Dict[int, KategoriFinansial]:
        """
        Beri label kategori ke setiap cluster K-Means
        berdasarkan centroid cluster.
        
        Logika: 
        - Cluster dengan pendapatan rendah + tanggungan banyak → SANGAT_MEMBUTUHKAN
        - Cluster dengan pendapatan tinggi + tanggungan sedikit → MAMPU
        """
        n_clusters = len(cluster_centers)
        
        # Indeks fitur penting
        try:
            idx_pendapatan = feature_names.index("pendapatan_orang_tua")
            idx_tanggungan = feature_names.index("jumlah_tanggungan")
            idx_pengeluaran = feature_names.index("pengeluaran_bulanan")
            idx_uang_saku = feature_names.index("uang_saku")
        except ValueError:
            idx_pendapatan, idx_tanggungan, idx_pengeluaran, idx_uang_saku = 0, 1, 2, 3

        # Hitung skor "kemampuan finansial" per cluster
        # Semakin tinggi skor = semakin mampu
        scores = []
        for i, center in enumerate(cluster_centers):
            score = (
                center[idx_pendapatan] * 2.0   # Bobot pendapatan tinggi
                - center[idx_tanggungan] * 1.5   # Tanggungan banyak → lebih butuh
                + center[idx_uang_saku] * 1.0    # Uang saku banyak → lebih mampu
                - center[idx_pengeluaran] * 0.5  # Pengeluaran besar → sedikit negatif
            )
            scores.append((i, score))

        # Sort berdasarkan skor
        scores.sort(key=lambda x: x[1])

        # Assign kategori berdasarkan urutan kemampuan
        categories = [
            KategoriFinansial.SANGAT_MEMBUTUHKAN,
            KategoriFinansial.MEMBUTUHKAN,
            KategoriFinansial.CUKUP_MAMPU,
        ]

        mapping: Dict[int, KategoriFinansial] = {}
        for rank, (cluster_id, _) in enumerate(scores):
            if rank < len(categories):
                mapping[cluster_id] = categories[rank]
            else:
                # Jika cluster lebih dari 4, distribute categories
                category_idx = min(rank, len(categories) - 1)
                mapping[cluster_id] = categories[category_idx]

        return mapping

    @staticmethod
    def label_dbscan(
        labels: np.ndarray,
        X_scaled: np.ndarray,
        feature_names: List[str],
    ) -> Dict[int, KategoriFinansial]:
        """
        Beri label kategori ke setiap cluster DBSCAN.
        Cluster -1 (outlier) → OUTLIER.
        """
        unique_labels = sorted(set(labels) - {-1})
        mapping: Dict[int, KategoriFinansial] = {-1: KategoriFinansial.OUTLIER}

        if not unique_labels:
            return mapping

        # Hitung centroid per cluster
        centroids = []
        for label in unique_labels:
            mask = labels == label
            centroid = X_scaled[mask].mean(axis=0)
            centroids.append((label, centroid))

        # Gunakan logika sama seperti K-Means
        try:
            idx_pendapatan = feature_names.index("pendapatan_orang_tua")
            idx_tanggungan = feature_names.index("jumlah_tanggungan")
            idx_uang_saku = feature_names.index("uang_saku")
            idx_pengeluaran = feature_names.index("pengeluaran_bulanan")
        except ValueError:
            idx_pendapatan, idx_tanggungan, idx_uang_saku, idx_pengeluaran = 0, 1, 3, 2

        scores = []
        for label, centroid in centroids:
            score = (
                centroid[idx_pendapatan] * 2.0
                - centroid[idx_tanggungan] * 1.5
                + centroid[idx_uang_saku] * 1.0
                - centroid[idx_pengeluaran] * 0.5
            )
            scores.append((label, score))

        scores.sort(key=lambda x: x[1])

        categories = [
            KategoriFinansial.SANGAT_MEMBUTUHKAN,
            KategoriFinansial.MEMBUTUHKAN,
            KategoriFinansial.CUKUP_MAMPU,
        ]

        for rank, (label, _) in enumerate(scores):
            category_idx = min(rank, len(categories) - 1)
            mapping[label] = categories[category_idx]

        return mapping
